class DoctorModel {
  final String id;
  final String name;
  final String? specialization;
  final String? qualification;
  final String? phone;
  final bool isAvailable;

  const DoctorModel({
    required this.id,
    required this.name,
    this.specialization,
    this.qualification,
    this.phone,
    this.isAvailable = true,
  });

  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] is Map
        ? Map<String, dynamic>.from(map['profiles'] as Map)
        : <String, dynamic>{};

    return DoctorModel(
      id: '${map['id'] ?? ''}',
      name: '${map['full_name'] ?? profile['full_name'] ?? 'Doctor'}',
      specialization: map['specialization']?.toString(),
      qualification: map['qualification']?.toString(),
      phone: map['phone']?.toString(),
      isAvailable:
          map['is_available'] == null ? true : map['is_available'] == true,
    );
  }
}
