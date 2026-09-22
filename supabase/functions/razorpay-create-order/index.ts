import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const RAZORPAY_KEY_ID = Deno.env.get('RAZORPAY_KEY_ID')!;
const RAZORPAY_KEY_SECRET = Deno.env.get('RAZORPAY_KEY_SECRET')!;

const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

function basicAuth() {
  return `Basic ${btoa(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`)}`;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const token = authHeader.replace(/^Bearer\s+/i, '').trim();

    if (!token) {
      return json({ error: 'Missing authorization token.' }, 401);
    }

    const { data: authData, error: authError } =
      await admin.auth.getUser(token);

    if (authError || !authData.user) {
      return json({ error: 'Unauthorized.' }, 401);
    }

    const body = await req.json();
    const appointmentId = body?.appointment_id?.toString();

    if (!appointmentId) {
      return json({ error: 'appointment_id is required.' }, 400);
    }

    const { data: payment, error: paymentError } = await admin
      .from('careflow_payments')
      .select(`
        id,
        appointment_id,
        patient_id,
        doctor_id,
        clinic_id,
        amount_paise,
        currency,
        status,
        provider_order_id
      `)
      .eq('appointment_id', appointmentId)
      .eq('patient_id', authData.user.id)
      .maybeSingle();

    if (paymentError) {
      throw paymentError;
    }

    if (!payment) {
      return json({ error: 'Payment record not found.' }, 404);
    }

    if (payment.status === 'paid_pending_confirmation') {
      return json({
        ok: true,
        already_paid: true,
        appointment_id: appointmentId,
        payment_id: payment.id,
      });
    }

    if (payment.status !== 'awaiting_payment') {
      return json({
        error: `Payment is not payable in status ${payment.status}.`,
      }, 409);
    }

    if (!payment.provider_order_id) {
      const razorpayResponse = await fetch(
        'https://api.razorpay.com/v1/orders',
        {
          method: 'POST',
          headers: {
            Authorization: basicAuth(),
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            amount: payment.amount_paise,
            currency: 'INR',
            receipt: `CF-${appointmentId}`,
            partial_payment: false,
            notes: {
              appointment_id: appointmentId,
              payment_id: payment.id,
              patient_id: authData.user.id,
            },
          }),
        },
      );

      const razorpayOrder = await razorpayResponse.json();

      if (!razorpayResponse.ok) {
        return json({
          error: razorpayOrder?.error?.description ??
              'Razorpay order creation failed.',
        }, 502);
      }

      const { error: updateError } = await admin
        .from('careflow_payments')
        .update({
          provider_order_id: razorpayOrder.id,
          updated_at: new Date().toISOString(),
        })
        .eq('id', payment.id)
        .eq('status', 'awaiting_payment');

      if (updateError) {
        throw updateError;
      }

      return json({
        ok: true,
        key_id: RAZORPAY_KEY_ID,
        order_id: razorpayOrder.id,
        amount_paise: payment.amount_paise,
        currency: 'INR',
        appointment_id: appointmentId,
        payment_id: payment.id,
      });
    }

    return json({
      ok: true,
      key_id: RAZORPAY_KEY_ID,
      order_id: payment.provider_order_id,
      amount_paise: payment.amount_paise,
      currency: 'INR',
      appointment_id: appointmentId,
      payment_id: payment.id,
    });
  } catch (error) {
    console.error(error);
    return json({
      error: error instanceof Error ? error.message : 'Unexpected server error.',
    }, 500);
  }
});
