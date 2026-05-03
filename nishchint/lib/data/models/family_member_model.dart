class FamilyMemberModel {
  final int id;
  final String name;
  final String phone;
  final String role; // 'primary' or 'member'

  FamilyMemberModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
  });

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'],
      phone: json['phone'],
      role: json['role'] ?? 'member',
    );
  }
}
