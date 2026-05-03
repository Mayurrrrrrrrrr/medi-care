import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'notification_service.dart';
import '../data/api_service.dart';
import '../core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AlarmService {
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  static Future<void> cancelAllAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final String? idsJson = prefs.getString('scheduled_alarm_ids');
    if (idsJson != null) {
      final List<dynamic> ids = json.decode(idsJson);
      for (var id in ids) {
        if (id is int) {
          await AndroidAlarmManager.cancel(id);
        }
      }
    }
    await prefs.remove('scheduled_alarm_ids');
  }

  static Future<void> scheduleAllAlarms(List<dynamic> medicines) async {
    await cancelAllAlarms();
    final now = DateTime.now();
    final List<int> newAlarmIds = [];

    for (var med in medicines) {
      final patientId = med['patient_id'];
      final medicineName = med['name'];
      final schedules = med['schedules'] as List<dynamic>? ?? [];

      for (var schedule in schedules) {
        if (schedule['is_active'] == 0 || schedule['is_active'] == '0') continue;
        
        final scheduleId = schedule['id'] is int ? schedule['id'] : int.tryParse(schedule['id'].toString()) ?? 0;
        final timeSlot = schedule['time_slot'].toString();
        final daysOfWeekStr = schedule['days_of_week'].toString();
        final daysList = daysOfWeekStr.split(',');

        final parts = timeSlot.split(':');
        if (parts.length < 2) continue;
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        for (int i = 0; i < 7; i++) {
          final targetDate = now.add(Duration(days: i));
          final targetDayStr = targetDate.weekday.toString();
          
          if (daysList.contains(targetDayStr) || daysOfWeekStr == 'Everyday') {
            final alarmTime = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
            
            if (alarmTime.isAfter(now)) {
              final alarmId = (scheduleId * 10 + i).hashCode.abs() % 2147483647;
              newAlarmIds.add(alarmId);
              await AndroidAlarmManager.oneShotAt(
                alarmTime,
                alarmId,
                _alarmFired,
                wakeup: true,
                exact: true,
                alarmClock: true, 
                allowWhileIdle: true,
                rescheduleOnReboot: true,
                params: {
                  'scheduleId': scheduleId,
                  'patientId': patientId,
                  'medicineId': med['id'],
                  'medicineName': medicineName,
                  'dose': med['dose'] ?? '',
                  'foodTiming': med['food_timing'] ?? '',
                  'isCritical': med['is_critical'] ?? 0,
                  'voiceUrl': schedule['voice_url'] ?? '',
                  'scheduledTime': alarmTime.toIso8601String(),
                },
              );
            }
          }
        }
      }
    }
    
    // Save new IDs
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('scheduled_alarm_ids', json.encode(newAlarmIds));
  }

  @pragma('vm:entry-point')
  static Future<void> rescheduleOnAppOpen() async {
    try {
      final api = ApiService();
      final patientsRes = await api.get(ApiConstants.patientsIndex);
      if (patientsRes['status'] != 'success') return;
      
      List<dynamic> allMedicines = [];
      for (var patient in patientsRes['data']) {
        final detailRes = await api.get('${ApiConstants.baseUrl}/patients/detail.php?patient_id=${patient['id']}');
        if (detailRes['status'] == 'success') {
          final medicines = detailRes['data']['medicines'] as List<dynamic>? ?? [];
          for (var med in medicines) {
            med['patient_id'] = patient['id'];
            allMedicines.add(med);
          }
        }
      }
      await scheduleAllAlarms(allMedicines);
    } catch (e) {
      debugPrint("Error rescheduling alarms: $e");
    }
  }

  static Future<void> scheduleMedicineAlarm(
      int scheduleId, 
      int patientId,
      int medicineId,
      DateTime dateTime, 
      String medicineName, 
      String? voicePath) async {
    
    if (dateTime.isAfter(DateTime.now())) {
      await AndroidAlarmManager.oneShotAt(
        dateTime,
        scheduleId,
        _alarmFired,
        wakeup: true,
        exact: true,
        alarmClock: true, 
        allowWhileIdle: true,
        rescheduleOnReboot: true,
        params: {
          'scheduleId': scheduleId,
          'patientId': patientId,
          'medicineId': medicineId,
          'medicineName': medicineName,
          'dose': '', // Manual alarms don't have all details yet
          'foodTiming': '',
          'isCritical': 0,
          'voiceUrl': '',
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
  NotificationService.triggerMedicineAlarm(
     scheduleId: params['scheduleId'],
     patientId: params['patientId'],
     medicineId: params['medicineId'] ?? 0,
     medicineName: params['medicineName'],
     dose: params['dose'] ?? '',
     foodTiming: params['foodTiming'] ?? '',
     isCritical: int.tryParse(params['isCritical']?.toString() ?? '0') ?? 0,
     voiceUrl: params['voiceUrl'] ?? '',
     scheduledTime: params['scheduledTime'],
     cachedVoicePath: params['voicePath'] == 'none' ? null : params['voicePath']
  );
}
