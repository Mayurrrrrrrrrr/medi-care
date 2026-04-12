class PatientModel {
  final int id;
  final String name;
  final String? photoUrl;
  final String? conditions;
  final String? doctorName;
  final String? emergencyContact;
  final String userRole;

  PatientModel({
    required this.id,
    required this.name,
    this.photoUrl,
    this.conditions,
    this.doctorName,
    this.emergencyContact,
    required this.userRole,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'],
      photoUrl: json['photo_url'],
      conditions: json['conditions'],
      doctorName: json['doctor_name'],
      emergencyContact: json['emergency_contact'],
      userRole: json['user_role'] ?? 'member',
    );
  }
}
