class PatientModel {
  final String id;
  final String name;
  final int? age;
  final String? gender;
  final String? phone;
  final String? address;

  const PatientModel({
    required this.id,
    required this.name,
    this.age,
    this.gender,
    this.phone,
    this.address,
  });

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    final rawAge = map['age'];

    return PatientModel(
      id: '${map['id'] ?? ''}',
      name: '${map['full_name'] ?? 'Patient'}',
      age: rawAge is int ? rawAge : int.tryParse('$rawAge'),
      gender: map['gender']?.toString(),
      phone: map['phone']?.toString(),
      address: map['address']?.toString(),
    );
  }
}
