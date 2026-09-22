import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const RAZORPAY_KEY_ID = Deno.env.get('RAZORPAY_KEY_ID')!;
const RAZORPAY_KEY_SECRET = Deno.env.get('RAZORPAY_KEY_SECRET')!;

const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

function basicAuth() {
  return `Basic ${btoa(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`)}`;
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
    },
  });
}

serve(async (_req) => {
  try {
    const { data: candidates, error: listError } = await admin
      .from('careflow_payments')
      .select('id')
      .eq('status', 'paid_pending_confirmation')
      .not('confirmation_deadline', 'is', null)
      .lte('confirmation_deadline', new Date().toISOString())
      .limit(50);

    if (listError) {
      throw listError;
    }

    const results = [];

    for (const candidate of candidates ?? []) {
      const { data: claimed, error: claimError } = await admin
        .rpc('careflow_claim_expired_payment', {
          p_payment_id: candidate.id,
        });

      if (claimError) {
        results.push({ id: candidate.id, status: 'claim_error', error: claimError.message });
        continue;
      }

      if (!claimed || claimed.length === 0) {
        results.push({ id: candidate.id, status: 'already_handled' });
        continue;
      }

      const item = claimed[0];
      const providerPaymentId = item.provider_payment_id;

      if (!providerPaymentId) {
        await admin
          .from('careflow_payments')
          .update({
            status: 'refund_failed',
            failure_reason: 'Missing provider payment ID.',
            updated_at: new Date().toISOString(),
          })
          .eq('id', item.payment_id)
          .eq('status', 'refund_pending');

        results.push({ id: candidate.id, status: 'refund_failed', error: 'Missing provider payment ID.' });
        continue;
      }

      const refundResponse = await fetch(
        `https://api.razorpay.com/v1/payments/${providerPaymentId}/refund`,
        {
          method: 'POST',
          headers: {
            Authorization: basicAuth(),
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            notes: {
              appointment_id: item.appointment_id,
              reason: 'doctor_confirmation_timeout',
            },
          }),
        },
      );

      const refund = await refundResponse.json();

      if (!refundResponse.ok) {
        await admin
          .from('careflow_payments')
          .update({
            status: 'refund_failed',
            failure_reason: refund?.error?.description ?? 'Refund failed.',
            updated_at: new Date().toISOString(),
          })
          .eq('id', item.payment_id)
          .eq('status', 'refund_pending');

        results.push({
          id: candidate.id,
          status: 'refund_failed',
          error: refund?.error?.description ?? 'Refund failed.',
        });
        continue;
      }

      const now = new Date().toISOString();

      await admin
        .from('careflow_payments')
        .update({
          provider_refund_id: refund.id,
          status: 'refunded',
          refunded_at: now,
          updated_at: now,
        })
        .eq('id', item.payment_id)
        .eq('status', 'refund_pending');

      const { data: appointment } = await admin
        .from('careflow_appointments')
        .select('patient_id')
        .eq('id', item.appointment_id)
        .maybeSingle();

      await admin
        .from('careflow_appointments')
        .update({
          status: 'cancelled',
        })
        .eq('id', item.appointment_id)
        .eq('status', 'awaiting_doctor_confirmation');

      if (appointment?.patient_id) {
        await admin
          .from('careflow_notifications')
          .insert({
            user_id: appointment.patient_id,
            title: 'Appointment expired — refund started',
            body: 'The doctor did not confirm your appointment within the confirmation window. Your payment refund has been initiated.',
            type: 'payment',
          });
      }

      results.push({
        id: candidate.id,
        status: 'refunded',
        refund_id: refund.id,
      });
    }

    return json({
      ok: true,
      processed: results.length,
      results,
    });
  } catch (error) {
    console.error(error);
    return json({
      error: error instanceof Error ? error.message : 'Unexpected server error.',
    }, 500);
  }
});
