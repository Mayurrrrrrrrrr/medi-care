class AdherenceLogModel {
  final int scheduleId;
  final String timeSlot;
  final String? label;
  final int medicineId;
  final String medicineName;
  final String dose;
  final String form;
  final String foodTiming;
  final bool isCritical;
  final String status; // 'pending', 'taken', 'skipped', 'snoozed'
  final int? logId;
  final String? skipReason;
  final String? loggedAt;
  final String scheduledDate;

  AdherenceLogModel({
    required this.scheduleId,
    required this.timeSlot,
    this.label,
    required this.medicineId,
    required this.medicineName,
    required this.dose,
    required this.form,
    required this.foodTiming,
    required this.isCritical,
    required this.status,
    this.logId,
    this.skipReason,
    this.loggedAt,
    required this.scheduledDate,
  });

  factory AdherenceLogModel.fromJson(Map<String, dynamic> json) {
    return AdherenceLogModel(
      scheduleId: _toInt(json['schedule_id']),
      timeSlot: json['time_slot'],
      label: json['label'],
      medicineId: _toInt(json['medicine_id']),
      medicineName: json['medicine_name'],
      dose: json['dose'],
      form: json['form'],
      foodTiming: json['food_timing'],
      isCritical: json['is_critical'] == 1 || json['is_critical'] == '1',
      status: json['status'],
      logId: json['log_id'] != null ? _toInt(json['log_id']) : null,
      skipReason: json['skip_reason'],
      loggedAt: json['logged_at'],
      scheduledDate: json['scheduled_date'],
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    return 0;
  }
}
