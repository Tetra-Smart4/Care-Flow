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
    const action = body?.action?.toString();

    if (!appointmentId || !['confirm', 'reject'].includes(action)) {
      return json({
        error: 'appointment_id and action=confirm|reject are required.',
      }, 400);
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
        provider_payment_id,
        confirmation_deadline
      `)
      .eq('appointment_id', appointmentId)
      .eq('doctor_id', authData.user.id)
      .maybeSingle();

    if (paymentError) {
      throw paymentError;
    }

    if (!payment) {
      return json({ error: 'Paid appointment not found for this doctor.' }, 404);
    }

    if (payment.status !== 'paid_pending_confirmation') {
      return json({
        error: `Appointment is not waiting for doctor confirmation. Current payment status: ${payment.status}.`,
      }, 409);
    }

    if (payment.confirmation_deadline &&
        new Date(payment.confirmation_deadline).getTime() <= Date.now()) {
      return json({
        error: 'The confirmation window has expired. The refund worker will process this payment.',
      }, 409);
    }

    if (action === 'reject') {
      // Claim the payment before refunding so confirmation and rejection cannot both win.
      const { data: claimed, error: claimError } = await admin
        .from('careflow_payments')
        .update({
          status: 'refund_pending',
          updated_at: new Date().toISOString(),
        })
        .eq('id', payment.id)
        .eq('status', 'paid_pending_confirmation')
        .select('id')
        .maybeSingle();

      if (claimError) {
        throw claimError;
      }

      if (!claimed) {
        return json({ error: 'Payment was already handled.' }, 409);
      }

      const refundResponse = await fetch(
        `https://api.razorpay.com/v1/payments/${payment.provider_payment_id}/refund`,
        {
          method: 'POST',
          headers: {
            Authorization: basicAuth(),
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            notes: {
              appointment_id: appointmentId,
              reason: 'doctor_rejected',
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
          .eq('id', payment.id)
          .eq('status', 'refund_pending');

        return json({
          error: refund?.error?.description ?? 'Refund failed.',
        }, 502);
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
        .eq('id', payment.id)
        .eq('status', 'refund_pending');

      await admin
        .from('careflow_appointments')
        .update({
          status: 'cancelled',
        })
        .eq('id', appointmentId)
        .eq('status', 'awaiting_doctor_confirmation');

      await admin
        .from('careflow_notifications')
        .insert({
          user_id: payment.patient_id,
          title: 'Appointment cancelled and refund started',
          body: 'The doctor did not accept this appointment. Your payment refund has been initiated.',
          type: 'payment',
        });

      return json({
        ok: true,
        action: 'reject',
        payment_status: 'refunded',
        refund_id: refund.id,
      });
    }

    // ==========================================================
    // CONFIRM: transfer money to the doctor's Route linked account
    // ==========================================================

    const { data: payoutAccount, error: payoutError } = await admin
      .from('careflow_doctor_payout_accounts')
      .select('razorpay_linked_account_id, active')
      .eq('doctor_id', authData.user.id)
      .eq('active', true)
      .maybeSingle();

    if (payoutError) {
      throw payoutError;
    }

    if (!payoutAccount?.razorpay_linked_account_id) {
      return json({
        error: 'Doctor payout account is not configured. Appointment was not confirmed and payment was not transferred.',
      }, 409);
    }

    // First atomically claim the confirmation operation.
    const { data: claimed, error: claimError } = await admin
      .from('careflow_payments')
      .update({
        status: 'transfer_pending',
        updated_at: new Date().toISOString(),
      })
      .eq('id', payment.id)
      .eq('status', 'paid_pending_confirmation')
      .select('id')
      .maybeSingle();

    if (claimError) {
      throw claimError;
    }

    if (!claimed) {
      return json({ error: 'Payment was already handled.' }, 409);
    }

    const transferResponse = await fetch(
      `https://api.razorpay.com/v1/payments/${payment.provider_payment_id}/transfers`,
      {
        method: 'POST',
        headers: {
          Authorization: basicAuth(),
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          transfers: [
            {
              account: payoutAccount.razorpay_linked_account_id,
              amount: payment.amount_paise,
              currency: 'INR',
              notes: {
                appointment_id: appointmentId,
                patient_id: payment.patient_id,
                doctor_id: payment.doctor_id,
              },
              linked_account_notes: ['appointment_id'],
            },
          ],
        }),
      },
    );

    const transferResult = await transferResponse.json();

    if (!transferResponse.ok) {
      await admin
        .from('careflow_payments')
        .update({
          status: 'paid_pending_confirmation',
          failure_reason: transferResult?.error?.description ?? 'Doctor payout transfer failed.',
          updated_at: new Date().toISOString(),
        })
        .eq('id', payment.id)
        .eq('status', 'transfer_pending');

      return json({
        error: transferResult?.error?.description ?? 'Doctor payout transfer failed.',
      }, 502);
    }

    const transferItem =
      Array.isArray(transferResult?.items) && transferResult.items.length > 0
        ? transferResult.items[0]
        : null;

    const now = new Date().toISOString();

    await admin
      .from('careflow_payments')
      .update({
        provider_transfer_id: transferItem?.id ?? null,
        status: 'transferred',
        confirmed_at: now,
        updated_at: now,
      })
      .eq('id', payment.id)
      .eq('status', 'transfer_pending');

    await admin
      .from('careflow_appointments')
      .update({
        status: 'confirmed',
      })
      .eq('id', appointmentId)
      .eq('status', 'awaiting_doctor_confirmation');

    await admin
      .from('careflow_notifications')
      .insert({
        user_id: payment.patient_id,
        title: 'Appointment confirmed',
        body: 'The doctor confirmed your paid appointment.',
        type: 'appointment',
      });

    return json({
      ok: true,
      action: 'confirm',
      payment_status: 'transferred',
      transfer_id: transferItem?.id ?? null,
    });
  } catch (error) {
    console.error(error);
    return json({
      error: error instanceof Error ? error.message : 'Unexpected server error.',
    }, 500);
  }
});
