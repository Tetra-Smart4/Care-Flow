class CareFlowAppointment {
  const CareFlowAppointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.clinicId,
    required this.date,
    required this.time,
    required this.reason,
    required this.status,
    this.tokenNo,
    this.qrToken,
    this.doctorName,
    this.patientName,
    this.clinicName,
  });

  final String id;
  final String patientId;
  final String doctorId;
  final String clinicId;
  final String date;
  final String time;
  final String reason;
  final String status;
  final int? tokenNo;
  final String? qrToken;
  final String? doctorName;
  final String? patientName;
  final String? clinicName;

  factory CareFlowAppointment.fromMap(Map<String, dynamic> m) {
    return CareFlowAppointment(
      id: '${m['id']}',
      patientId: '${m['patient_id']}',
      doctorId: '${m['doctor_id']}',
      clinicId: '${m['clinic_id']}',
      date: '${m['appointment_date']}',
      time: '${m['appointment_time']}',
      reason: '${m['reason'] ?? ''}',
      status: '${m['status'] ?? 'pending'}',
      tokenNo: (m['token_no'] as num?)?.toInt(),
      qrToken: m['qr_token']?.toString(),
      doctorName: m['doctor_name']?.toString(),
      patientName: m['patient_name']?.toString(),
      clinicName: m['clinic_name']?.toString(),
    );
  }
}

class DirectoryPerson {
  const DirectoryPerson({
    required this.id,
    required this.name,
    this.specialization,
    this.qualification,
    this.phone,
  });

  final String id;
  final String name;
  final String? specialization;
  final String? qualification;
  final String? phone;

  factory DirectoryPerson.fromMap(Map<String, dynamic> m) {
    return DirectoryPerson(
      id: '${m['id']}',
      name: '${m['full_name'] ?? 'Unknown'}',
      specialization: m['specialization']?.toString(),
      qualification: m['qualification']?.toString(),
      phone: m['phone']?.toString(),
    );
  }
}

class MedicineInfo {
  const MedicineInfo({
    required this.id,
    required this.name,
    required this.commonUses,
    required this.precautions,
    required this.sideEffects,
    this.info,
  });

  final String id;
  final String name;
  final String commonUses;
  final String precautions;
  final String sideEffects;
  final String? info;

  factory MedicineInfo.fromMap(Map<String, dynamic> m) {
    return MedicineInfo(
      id: '${m['id']}',
      name: '${m['name']}',
      commonUses: '${m['common_uses'] ?? ''}',
      precautions: '${m['precautions'] ?? ''}',
      sideEffects: '${m['side_effects'] ?? ''}',
      info: m['general_info']?.toString(),
    );
  }
}
