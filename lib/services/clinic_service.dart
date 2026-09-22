import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClinicService {
  ClinicService({SupabaseClient? client})
      : _db = client ?? Supabase.instance.client;

  final SupabaseClient _db;

  String get _userId {
    final id = _db.auth.currentUser?.id;

    if (id == null) {
      throw const AuthException(
        'Clinic session not found. Please login again.',
      );
    }

    return id;
  }

  // ============================================================
  // CLINIC PROFILE
  // ============================================================

  Future<Map<String, dynamic>> getClinicProfile() async {
    final userId = _userId;

    final profile = await _db
        .from('profiles')
        .select('id, full_name, phone, address, role')
        .eq('id', userId)
        .maybeSingle();

    return {
      'id': userId,
      'clinic_name': profile?['full_name'] ?? 'Clinic',
      'phone': profile?['phone'],
      'address': profile?['address'],
      'role': profile?['role'],
    };
  }

  // ============================================================
  // DOCTORS
  // ============================================================

  Future<List<Map<String, dynamic>>> getDoctors() async {
    final response = await _db.rpc(
      'careflow_clinic_doctors',
    );

    return _rows(response);
  }

  // ============================================================
  // PATIENTS
  // ============================================================

  Future<List<Map<String, dynamic>>> getPatients() async {
    final response = await _db.rpc(
      'careflow_clinic_patients',
    );

    return _rows(response);
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Future<Map<String, dynamic>> getClinicSummary() async {
    final response = await _db.rpc(
      'careflow_clinic_summary',
    );

    final rows = _rows(response);

    if (rows.isEmpty) {
      throw Exception('Clinic summary returned no data.');
    }

    return rows.first;
  }

  // ============================================================
  // DASHBOARD COUNTS
  // ============================================================

  Future<Map<String, int>> getDashboardCounts() async {
    final summary = await getClinicSummary();

    return {
      'doctors': _toInt(summary['total_doctors']),
      'patients': _toInt(summary['total_patients']),
      'appointments': _toInt(summary['today_appointments']),
      'attended': _toInt(summary['today_attended']),
      'completed': _toInt(summary['completed']),
      'pending': _toInt(summary['pending']),
      'cancelled': _toInt(summary['cancelled']),
    };
  }

  // ============================================================
  // QUEUE
  // ============================================================

  Future<List<Map<String, dynamic>>> getQueue() async {
    final response = await _db.rpc(
      'careflow_clinic_queue',
    );

    return _rows(response);
  }

  // ============================================================
  // APPOINTMENTS
  // ============================================================

  Future<List<Map<String, dynamic>>> getAppointments({
    bool todayOnly = false,
  }) async {
    final response = await _db.rpc(
      'careflow_clinic_queue',
    );

    final queue = _rows(response);

    return queue.map((item) {
      final patientName =
          item['patient_name']?.toString() ?? 'Patient';

      final doctorName =
          item['doctor_name']?.toString() ?? 'Doctor';

      return {
        'id': item['appointment_id'],
        'patient_id': item['patient_id'],
        'doctor_id': item['doctor_id'],
        'status': item['status'],
        'reason': null,
        'created_at': item['checked_in_at'],
        'patients': {
          'profiles': {
            'full_name': patientName,
          },
        },
        'doctors': {
          'profiles': {
            'full_name': doctorName,
          },
        },
        'doctor_slots': {
          'start_time': item['appointment_time'],
        },
        'token_no': item['token_no'],
        'patient_name': patientName,
        'doctor_name': doctorName,
      };
    }).toList();
  }

  // ============================================================
  // PATIENT APPOINTMENTS
  // ============================================================

  Future<List<Map<String, dynamic>>> getPatientAppointments(
    String patientId,
  ) async {
    final response = await _db.rpc(
      'careflow_clinic_queue',
    );

    final rows = _rows(response);

    return rows
        .where(
          (row) => row['patient_id']?.toString() == patientId,
        )
        .toList();
  }

  // ============================================================
  // DOCTOR AVAILABILITY
  // ============================================================

  Future<void> setDoctorAvailability({
    required String doctorId,
    required bool value,
  }) async {
    final clinicId = _userId;

    await _db
        .from('clinic_doctors')
        .update({
          'is_available': value,
        })
        .eq('clinic_id', clinicId)
        .eq('doctor_id', doctorId);
  }

  // ============================================================
  // UPDATE CLINIC PROFILE
  // ============================================================

  Future<void> updateClinicProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    final userId = _userId;

    await _db
        .from('profiles')
        .update({
          'full_name': name,
          'phone': phone,
          'address': address,
        })
        .eq('id', userId);
  }

  // ============================================================
  // CREATE DOCTOR
  // ============================================================

  Future<Map<String, dynamic>> createDoctor({
    required String name,
    required String email,
    required String password,
    required String specialization,
    required String qualification,
    required String phone,
  }) async {
    final response = await _db.functions.invoke(
      'clinic-create-doctor',
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'specialization': specialization.trim(),
        'qualification': qualification.trim(),
        'phone': phone.trim(),
      },
    );

    if (response.data is! Map) {
      throw Exception(
        'Doctor registration returned an invalid response.',
      );
    }

    return Map<String, dynamic>.from(
      response.data as Map,
    );
  }

  // ============================================================
  // REALTIME
  // ============================================================

  RealtimeChannel subscribe(
    VoidCallback onChanged, {
    String tag = 'shared',
  }) {
    final clinicId = _userId;

    final channel = _db.channel(
      'clinic-$clinicId-$tag',
    );

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'careflow_appointments',
          callback: (_) {
            onChanged();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'clinic_doctors',
          callback: (_) {
            onChanged();
          },
        );

    channel.subscribe();

    return channel;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  List<Map<String, dynamic>> _rows(dynamic response) {
    if (response == null) {
      return <Map<String, dynamic>>[];
    }

    if (response is List) {
      return response
          .whereType<Map>()
          .map(
            (row) => Map<String, dynamic>.from(row),
          )
          .toList();
    }

    if (response is Map) {
      return [
        Map<String, dynamic>.from(response),
      ];
    }

    return <Map<String, dynamic>>[];
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '0',
        ) ??
        0;
  }
}