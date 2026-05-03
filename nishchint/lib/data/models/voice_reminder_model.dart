class VoiceReminder {
  final int id;
  final int scheduleId;
  final String fileUrl;
  final String? messageText;

  VoiceReminder({
    required this.id,
    required this.scheduleId,
    required this.fileUrl,
    this.messageText,
  });

  factory VoiceReminder.fromJson(Map<String, dynamic> json) {
    return VoiceReminder(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      scheduleId: json['schedule_id'] is int ? json['schedule_id'] : int.parse(json['schedule_id'].toString()),
      fileUrl: json['file_url'],
      messageText: json['message_text'],
    );
  }
}
