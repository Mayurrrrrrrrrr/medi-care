class CareNote {
  final int id;
  final int medicineId;
  final String noteText;
  final String addedByName;
  final String createdAt;

  CareNote({
    required this.id,
    required this.medicineId,
    required this.noteText,
    required this.addedByName,
    required this.createdAt,
  });

  factory CareNote.fromJson(Map<String, dynamic> json) {
    return CareNote(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      medicineId: json['medicine_id'] is int ? json['medicine_id'] : int.parse(json['medicine_id'].toString()),
      noteText: json['note_text'],
      addedByName: json['added_by_name'] ?? 'Unknown',
      createdAt: json['created_at'],
    );
  }
}
