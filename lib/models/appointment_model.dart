class AppointmentModel {
  final String id;
  final String? doctorId;
  final String? patientId;
  final String? clinicId;
  final String? status;
  final String? reason;
  final DateTime? scheduledAt;

  const AppointmentModel({
    required this.id,
    this.doctorId,
    this.patientId,
    this.clinicId,
    this.status,
    this.reason,
    this.scheduledAt,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return AppointmentModel(
      id: '${map['id'] ?? ''}',
      doctorId: map['doctor_id']?.toString(),
      patientId: map['patient_id']?.toString(),
      clinicId: map['clinic_id']?.toString(),
      status: map['status']?.toString(),
      reason: map['reason']?.toString(),
      scheduledAt: parseDate(
        map['scheduled_at'] ?? map['appointment_date'] ?? map['date'],
      ),
    );
  }

  String get displayStatus =>
      (status ?? 'pending').trim().isEmpty ? 'pending' : status!.trim();
}
