import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  PaymentService({SupabaseClient? client})
      : _db = client ?? Supabase.instance.client;

  final SupabaseClient _db;

  Future<Map<String, dynamic>> prepareAppointment({
    required String doctorId,
    required String clinicId,
    required String appointmentDate,
    required String appointmentTime,
    required String reason,
  }) async {
    final response = await _db.rpc(
      'careflow_prepare_paid_appointment',
      params: {
        'p_doctor_id': doctorId,
        'p_clinic_id': clinicId,
        'p_appointment_date': appointmentDate,
        'p_appointment_time': appointmentTime,
        'p_reason': reason,
      },
    );

    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    throw Exception(
      'CareFlow did not return appointment payment details.',
    );
  }

  /// Demo-only payment capture.
  ///
  /// No real money is charged. This moves the payment ledger from
  /// awaiting_payment -> paid_pending_confirmation and the appointment
  /// from payment_pending -> awaiting_doctor_confirmation.
  Future<Map<String, dynamic>> captureDemoPayment({
    required String paymentId,
  }) async {
    final response = await _db.rpc(
      'careflow_demo_capture_payment',
      params: {
        'p_payment_id': paymentId,
      },
    );

    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    throw Exception('Demo payment could not be completed.');
  }

  /// Demo-only doctor decision.
  ///
  /// action = confirm or reject.
  /// Confirm simulates payout; reject simulates a refund.
  Future<Map<String, dynamic>> doctorDemoAction({
    required String paymentId,
    required String action,
  }) async {
    final response = await _db.rpc(
      'careflow_demo_doctor_action',
      params: {
        'p_payment_id': paymentId,
        'p_action': action,
      },
    );

    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    throw Exception('Doctor action could not be completed.');
  }

  Future<List<Map<String, dynamic>>> doctorPaidRequests() async {
    final response = await _db.rpc('careflow_demo_doctor_paid_requests');

    if (response is List) {
      return response
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }

    if (response is Map) {
      return [Map<String, dynamic>.from(response)];
    }

    return <Map<String, dynamic>>[];
  }
}
