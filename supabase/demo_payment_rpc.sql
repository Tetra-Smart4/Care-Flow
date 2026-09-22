-- CareFlow DEMO payment flow
-- No Razorpay / no real money.
-- Patient demo pay -> doctor confirm/reject -> simulated payout/refund.

create or replace function public.careflow_demo_capture_payment(
  p_payment_id uuid
)
returns table (
  payment_id uuid,
  appointment_id uuid,
  payment_status text,
  appointment_status text,
  confirmation_deadline timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_patient uuid := auth.uid();
  v_payment public.careflow_payments%rowtype;
  v_appointment public.careflow_appointments%rowtype;
  v_deadline timestamptz;
begin
  if v_patient is null then
    raise exception 'Not authenticated';
  end if;

  select *
  into v_payment
  from public.careflow_payments
  where id = p_payment_id
  for update;

  if not found then
    raise exception 'Payment not found';
  end if;

  if v_payment.patient_id <> v_patient then
    raise exception 'You cannot pay this appointment';
  end if;

  select *
  into v_appointment
  from public.careflow_appointments
  where id = v_payment.appointment_id
  for update;

  if not found then
    raise exception 'Appointment not found';
  end if;

  if v_payment.status = 'paid_pending_confirmation'
     and v_appointment.status = 'awaiting_doctor_confirmation' then
    return query
    select
      v_payment.id,
      v_payment.appointment_id,
      v_payment.status,
      v_appointment.status,
      v_payment.confirmation_deadline;
    return;
  end if;

  if v_payment.status <> 'awaiting_payment' then
    raise exception 'Payment cannot be completed from status: %', v_payment.status;
  end if;

  if v_appointment.status <> 'payment_pending' then
    raise exception 'Appointment cannot be paid from status: %', v_appointment.status;
  end if;

  v_deadline := now() + interval '15 minutes';

  update public.careflow_payments
  set
    provider = 'demo',
    status = 'paid_pending_confirmation',
    confirmation_deadline = v_deadline,
    paid_at = now(),
    updated_at = now()
  where id = v_payment.id;

  update public.careflow_appointments
  set
    status = 'awaiting_doctor_confirmation'
  where id = v_appointment.id;

  return query
  select
    v_payment.id,
    v_payment.appointment_id,
    'paid_pending_confirmation'::text,
    'awaiting_doctor_confirmation'::text,
    v_deadline;
end;
$$;

grant execute on function public.careflow_demo_capture_payment(uuid)
to authenticated;


create or replace function public.careflow_demo_doctor_paid_requests()
returns table (
  payment_id uuid,
  appointment_id uuid,
  patient_id uuid,
  patient_name text,
  clinic_name text,
  appointment_date date,
  appointment_time time,
  reason text,
  amount_paise bigint,
  status text,
  confirmation_deadline timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    p.id,
    a.id,
    a.patient_id,
    pp.full_name,
    cp.full_name,
    a.appointment_date,
    a.appointment_time,
    a.reason,
    p.amount_paise,
    p.status,
    p.confirmation_deadline
  from public.careflow_payments p
  join public.careflow_appointments a
    on a.id = p.appointment_id
  join public.profiles pp
    on pp.id = a.patient_id
  join public.profiles cp
    on cp.id = a.clinic_id
  join public.profiles dp
    on dp.id = a.doctor_id
  where a.doctor_id = auth.uid()
    and dp.role = 'doctor'
    and p.status = 'paid_pending_confirmation'
    and a.status = 'awaiting_doctor_confirmation'
  order by a.appointment_date, a.appointment_time, p.created_at;
$$;

grant execute on function public.careflow_demo_doctor_paid_requests()
to authenticated;


create or replace function public.careflow_demo_doctor_action(
  p_payment_id uuid,
  p_action text
)
returns table (
  payment_id uuid,
  appointment_id uuid,
  payment_status text,
  appointment_status text,
  action text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_doctor uuid := auth.uid();
  v_payment public.careflow_payments%rowtype;
  v_appointment public.careflow_appointments%rowtype;
  v_action text := lower(trim(coalesce(p_action, '')));
  v_demo_ref text;
begin
  if v_doctor is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1
    from public.profiles
    where id = v_doctor
      and role = 'doctor'
  ) then
    raise exception 'Only doctors can perform this action';
  end if;

  if v_action not in ('confirm', 'reject') then
    raise exception 'Action must be confirm or reject';
  end if;

  select *
  into v_payment
  from public.careflow_payments
  where id = p_payment_id
  for update;

  if not found then
    raise exception 'Payment not found';
  end if;

  select *
  into v_appointment
  from public.careflow_appointments
  where id = v_payment.appointment_id
  for update;

  if not found then
    raise exception 'Appointment not found';
  end if;

  if v_appointment.doctor_id <> v_doctor then
    raise exception 'You cannot action this appointment';
  end if;

  if v_payment.status <> 'paid_pending_confirmation'
     or v_appointment.status <> 'awaiting_doctor_confirmation' then
    raise exception 'This appointment is no longer awaiting confirmation';
  end if;

  if v_action = 'confirm' then
    v_demo_ref := 'demo_transfer_' || replace(gen_random_uuid()::text, '-', '');

    update public.careflow_payments
    set
      provider = 'demo',
      provider_transfer_id = v_demo_ref,
      status = 'transferred',
      confirmed_at = now(),
      updated_at = now()
    where id = v_payment.id;

    update public.careflow_appointments
    set status = 'confirmed'
    where id = v_appointment.id;

    return query
    select
      v_payment.id,
      v_payment.appointment_id,
      'transferred'::text,
      'confirmed'::text,
      'confirm'::text;
    return;
  end if;

  v_demo_ref := 'demo_refund_' || replace(gen_random_uuid()::text, '-', '');

  update public.careflow_payments
  set
    provider = 'demo',
    provider_refund_id = v_demo_ref,
    status = 'refunded',
    refunded_at = now(),
    failure_reason = 'Demo refund: doctor rejected appointment',
    updated_at = now()
  where id = v_payment.id;

  update public.careflow_appointments
  set status = 'cancelled'
  where id = v_appointment.id;

  return query
  select
    v_payment.id,
    v_payment.appointment_id,
    'refunded'::text,
    'cancelled'::text,
    'reject'::text;
end;
$$;

grant execute on function public.careflow_demo_doctor_action(uuid, text)
to authenticated;
