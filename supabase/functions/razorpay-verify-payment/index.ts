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
const CONFIRMATION_MINUTES = Number(
  Deno.env.get('DOCTOR_CONFIRMATION_MINUTES') ?? '15',
);

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

function hex(bytes: ArrayBuffer) {
  return [...new Uint8Array(bytes)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

async function hmacSha256(secret: string, value: string) {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  return hex(
    await crypto.subtle.sign(
      'HMAC',
      key,
      encoder.encode(value),
    ),
  );
}

function safeEqual(a: string, b: string) {
  if (a.length !== b.length) {
    return false;
  }

  let result = 0;

  for (let i = 0; i < a.length; i += 1) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }

  return result === 0;
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
    const paymentId = body?.razorpay_payment_id?.toString();
    const returnedOrderId = body?.razorpay_order_id?.toString();
    const signature = body?.razorpay_signature?.toString();

    if (!appointmentId ||
        !paymentId ||
        !returnedOrderId ||
        !signature) {
      return json({ error: 'Incomplete payment verification payload.' }, 400);
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
        status: payment.status,
        already_verified: true,
      });
    }

    if (payment.status !== 'awaiting_payment') {
      return json({
        error: `Payment cannot be verified from status ${payment.status}.`,
      }, 409);
    }

    // Razorpay requires the server's stored order ID for signature verification.
    if (!payment.provider_order_id ||
        payment.provider_order_id !== returnedOrderId) {
      return json({ error: 'Razorpay order ID mismatch.' }, 400);
    }

    const expectedSignature = await hmacSha256(
      RAZORPAY_KEY_SECRET,
      `${payment.provider_order_id}|${paymentId}`,
    );

    if (!safeEqual(expectedSignature, signature)) {
      return json({ error: 'Payment signature verification failed.' }, 400);
    }

    // Verify the provider-side payment record and amount.
    const providerResponse = await fetch(
      `https://api.razorpay.com/v1/payments/${paymentId}`,
      {
        method: 'GET',
        headers: {
          Authorization: basicAuth(),
        },
      },
    );

    const providerPayment = await providerResponse.json();

    if (!providerResponse.ok) {
      return json({
        error: providerPayment?.error?.description ??
            'Unable to verify payment at provider.',
      }, 502);
    }

    if (providerPayment.status !== 'captured') {
      return json({
        error: `Payment is ${providerPayment.status}, not captured.`,
      }, 409);
    }

    if (providerPayment.order_id !== payment.provider_order_id) {
      return json({ error: 'Provider order does not match the CareFlow order.' }, 400);
    }

    if (Number(providerPayment.amount) !== Number(payment.amount_paise)) {
      return json({ error: 'Payment amount mismatch.' }, 400);
    }

    const paidAt = new Date().toISOString();
    const deadline = new Date(
      Date.now() + CONFIRMATION_MINUTES * 60 * 1000,
    ).toISOString();

    const { data: updated, error: updateError } = await admin
      .from('careflow_payments')
      .update({
        provider_payment_id: paymentId,
        provider_signature: signature,
        status: 'paid_pending_confirmation',
        paid_at: paidAt,
        confirmation_deadline: deadline,
        updated_at: paidAt,
      })
      .eq('id', payment.id)
      .eq('status', 'awaiting_payment')
      .select('id, status, confirmation_deadline')
      .maybeSingle();

    if (updateError) {
      throw updateError;
    }

    if (!updated) {
      return json({
        ok: true,
        status: 'paid_pending_confirmation',
      });
    }

    await admin
      .from('careflow_appointments')
      .update({
        status: 'awaiting_doctor_confirmation',
      })
      .eq('id', appointmentId)
      .eq('status', 'payment_pending');

    await admin
      .from('careflow_notifications')
      .insert([
        {
          user_id: payment.doctor_id,
          title: 'Payment received — confirmation required',
          body: 'A patient has paid for an appointment and is waiting for your confirmation.',
          type: 'payment',
        },
        {
          user_id: payment.clinic_id,
          title: 'Paid appointment awaiting doctor confirmation',
          body: 'A patient has completed payment for an appointment.',
          type: 'payment',
        },
      ]);

    return json({
      ok: true,
      status: 'paid_pending_confirmation',
      confirmation_deadline: deadline,
    });
  } catch (error) {
    console.error(error);
    return json({
      error: error instanceof Error ? error.message : 'Unexpected server error.',
    }, 500);
  }
});
