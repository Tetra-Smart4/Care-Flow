class ClinicModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;

  const ClinicModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
  });

  factory ClinicModel.fromMap(Map<String, dynamic> map) {
    return ClinicModel(
      id: '${map['id'] ?? ''}',
      name: '${map['full_name'] ?? map['name'] ?? 'Clinic'}',
      email: '${map['email'] ?? ''}',
      phone: map['phone']?.toString(),
      address: map['address']?.toString(),
    );
  }
}
