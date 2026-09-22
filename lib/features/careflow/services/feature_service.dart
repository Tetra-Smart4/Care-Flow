import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/feature_models.dart';

class CareFlowFeatureService {
  CareFlowFeatureService._();
  static final CareFlowFeatureService instance = CareFlowFeatureService._();

  SupabaseClient get _db => Supabase.instance.client;
  String get userId => _db.auth.currentUser!.id;

  Future<List<DirectoryPerson>> doctors() async {
    final data = await _db.rpc('careflow_list_doctors');
    return (data as List)
        .map(
            (e) => DirectoryPerson.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<DirectoryPerson>> clinics() async {
    final data = await _db.rpc('careflow_list_clinics');
    return (data as List)
        .map(
            (e) => DirectoryPerson.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<String> bookAppointment({
    required String doctorId,
    required String clinicId,
    required DateTime date,
    required String time,
    required String reason,
  }) async {
    final result = await _db.rpc('careflow_book_appointment', params: {
      'p_doctor_id': doctorId,
      'p_clinic_id': clinicId,
      'p_appointment_date':
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'p_appointment_time': time,
      'p_reason': reason,
    });
    return '$result';
  }

  Future<List<CareFlowAppointment>> patientAppointments() async {
    final data = await _db.rpc('careflow_patient_appointments');
    return (data as List)
        .map((e) =>
            CareFlowAppointment.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<CareFlowAppointment>> doctorAppointments() async {
    final data = await _db.rpc('careflow_doctor_appointments');
    return (data as List)
        .map((e) =>
            CareFlowAppointment.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<CareFlowAppointment>> clinicAppointments() async {
    final data = await _db.rpc('careflow_clinic_appointments');
    return (data as List)
        .map((e) =>
            CareFlowAppointment.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<CareFlowAppointment?> appointmentById(String id) async {
    final row =
        await _db.rpc('careflow_appointment_detail', params: {'p_id': id});
    if (row is List && row.isNotEmpty) {
      return CareFlowAppointment.fromMap(
          Map<String, dynamic>.from(row.first as Map));
    }
    return null;
  }

  Future<Map<String, dynamic>> checkInByQr(String qrToken) async {
    final result = await _db
        .rpc('careflow_check_in_by_qr', params: {'p_qr_token': qrToken});
    if (result is List && result.isNotEmpty) {
      return Map<String, dynamic>.from(result.first as Map);
    }
    return <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> queue(
      String clinicId, DateTime date) async {
    final data = await _db.rpc('careflow_queue', params: {
      'p_clinic_id': clinicId,
      'p_queue_date':
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    });
    return (data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> setAppointmentStatus(String appointmentId, String status) async {
    await _db.rpc('careflow_set_appointment_status', params: {
      'p_appointment_id': appointmentId,
      'p_status': status,
    });
  }

  Future<String> saveConsultation({
    required String appointmentId,
    required String symptoms,
    required String diagnosis,
    required String notes,
    required List<Map<String, dynamic>> medicines,
  }) async {
    final result = await _db.rpc('careflow_save_consultation', params: {
      'p_appointment_id': appointmentId,
      'p_symptoms': symptoms,
      'p_diagnosis': diagnosis,
      'p_notes': notes,
      'p_medicines': medicines,
    });
    return '$result';
  }

  Future<void> addFollowUp({
    required String appointmentId,
    required String patientId,
    required DateTime date,
    required String notes,
  }) async {
    await _db.rpc('careflow_add_followup', params: {
      'p_appointment_id': appointmentId,
      'p_patient_id': patientId,
      'p_followup_date':
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'p_notes': notes,
    });
  }

  Future<void> createBill({
    required String appointmentId,
    required double consultationFee,
    required double medicineTotal,
    required double testTotal,
    required double otherCharges,
  }) async {
    await _db.rpc('careflow_create_bill', params: {
      'p_appointment_id': appointmentId,
      'p_consultation_fee': consultationFee,
      'p_medicine_total': medicineTotal,
      'p_test_total': testTotal,
      'p_other_charges': otherCharges,
    });
  }

  Future<List<MedicineInfo>> medicines() async {
    final data = await _db.from('careflow_medicines').select().order('name');
    return (data as List)
        .map((e) => MedicineInfo.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> patientRecords() async {
    final data = await _db.rpc('careflow_patient_records');
    return (data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> patientFollowups() async {
    final data = await _db.rpc('careflow_patient_followups');
    return (data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> addLabReport(
      {required String appointmentId,
      required String patientId,
      required String title,
      required String reportType,
      required String summary}) async {
    await _db.rpc('careflow_add_lab_report', params: {
      'p_appointment_id': appointmentId,
      'p_patient_id': patientId,
      'p_title': title,
      'p_report_type': reportType,
      'p_result_summary': summary,
    });
  }

  Future<int> advanceQueue(String clinicId) async {
    final result = await _db
        .rpc('careflow_advance_queue', params: {'p_clinic_id': clinicId});
    return (result as num).toInt();
  }

  Future<List<Map<String, dynamic>>> patientBills() async {
    final data = await _db.rpc('careflow_patient_bills');
    return (data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> patientNotifications() async {
    final data = await _db
        .from('careflow_notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _db
        .from('careflow_notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .eq('user_id', userId);
  }
}
