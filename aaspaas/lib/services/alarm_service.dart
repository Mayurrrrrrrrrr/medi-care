import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'notification_service.dart';

class AlarmService {
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  static Future<void> scheduleMedicineAlarm(
      int scheduleId, 
      int patientId,
      DateTime dateTime, 
      String medicineName, 
      String? voicePath) async {
    
    // Only register logic for strictly future events to avoid infinite looping
    if (dateTime.isAfter(DateTime.now())) {
      await AndroidAlarmManager.oneShotAt(
        dateTime,
        scheduleId,
        _alarmFired, // Headless hook
        wakeup: true,
        exact: true,
        alarmClock: true, 
        allowWhileIdle: true,
        rescheduleOnReboot: true,
        params: {
          'scheduleId': scheduleId,
          'patientId': patientId,
          'medicineName': medicineName,
          'voicePath': voicePath ?? 'none',
          'scheduledTime': dateTime.toIso8601String(),
        },
      );
    }
  }

  static Future<void> cancelAlarm(int scheduleId) async {
    await AndroidAlarmManager.cancel(scheduleId);
  }
}

@pragma('vm:entry-point')
void _alarmFired(int id, Map<String, dynamic> params) {
  // Fire the local notification intent instantly upon OS wake
  NotificationService.triggerMedicineAlarm(
     scheduleId: params['scheduleId'],
     patientId: params['patientId'],
     medicineName: params['medicineName'],
     scheduledTime: params['scheduledTime'],
     cachedVoicePath: params['voicePath'] == 'none' ? null : params['voicePath']
  );
}
