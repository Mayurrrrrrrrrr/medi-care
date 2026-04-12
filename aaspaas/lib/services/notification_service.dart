import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'dart:convert';
import '../main.dart';
import '../features/medicines/screens/alarm_screen.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          final data = json.decode(response.payload!);
          
          // Route to Full-Screen Alarm via global key
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => AlarmScreen(
                scheduleId: data['scheduleId'],
                patientId: data['patientId'],
                medicineName: data['medicineName'],
                scheduledTime: data['scheduledTime'],
                voicePath: data['voicePath'] == 'none' ? null : data['voicePath'],
              ),
            ),
          );
        }
      },
    );
  }

  static Future<void> triggerMedicineAlarm({
    required int scheduleId,
    required int patientId,
    required String medicineName,
    required String scheduledTime,
    String? cachedVoicePath,
  }) async {
    // Aggressive priority channel bypassing Do Not Disturb
    const androidChannel = AndroidNotificationDetails(
      'aaspaas_medical_alerts',
      'Medicine Reminders',
      channelDescription: 'Crucial alerts for medication timings',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
    );

    const notificationDetails = NotificationDetails(android: androidChannel);

    // Payload as JSON for easy parsing on tap
    final payload = {
      'scheduleId': scheduleId,
      'patientId': patientId,
      'medicineName': medicineName,
      'voicePath': cachedVoicePath ?? 'none',
      'scheduledTime': scheduledTime,
    };

    await _notifications.show(
      id: scheduleId, 
      title: 'Medicine Reminder',
      body: 'It is time for your $medicineName!',
      notificationDetails: notificationDetails,
      payload: json.encode(payload),
    );

    // If cache mapping was successful, play the aggressive local voice overlay
    if (cachedVoicePath != null) {
      final file = File(cachedVoicePath);
      if (await file.exists()) {
        final player = AudioPlayer();
        await player.play(DeviceFileSource(cachedVoicePath));
      }
    }
  }
}
