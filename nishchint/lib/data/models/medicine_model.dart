class MedicineModel {
  final int id;
  final int patientId;
  final String name;
  final String form;
  final String dose;
  final String foodTiming;
  final bool isCritical;
  final int? scheduleId;
  final String? timeSlot;
  final String? daysOfWeek;
  final String? voiceNoteUrl;

  MedicineModel({
    required this.id,
    required this.patientId,
    required this.name,
    required this.form,
    required this.dose,
    required this.foodTiming,
    required this.isCritical,
    this.scheduleId,
    this.timeSlot,
    this.daysOfWeek,
    this.voiceNoteUrl,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      patientId: json['patient_id'] is int ? json['patient_id'] : int.parse(json['patient_id'].toString()),
      name: json['name'],
      form: json['form'],
      dose: json['dose'],
      foodTiming: json['food_timing'],
      isCritical: json['is_critical'] == 1 || json['is_critical'] == '1',
      scheduleId: json['schedule_id'],
      timeSlot: json['time_slot'],
      daysOfWeek: json['days_of_week'],
      voiceNoteUrl: json['voice_note_url'],
    );
  }
}
