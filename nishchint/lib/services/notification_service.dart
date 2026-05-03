import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../main.dart';
import '../features/medicines/screens/alarm_screen.dart';
import '../features/medicines/medicines_list_screen.dart';

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
          
          if (data['type'] == 'stock_alert') {
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => const MedicinesListScreen()),
            );
            return;
          }
          
          // Route to Full-Screen Alarm via global key
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => AlarmScreen(
                scheduleId: data['scheduleId'],
                patientId: data['patientId'],
                medicineId: data['medicineId'] ?? 0,
                medicineName: data['medicineName'],
                dose: data['dose'] ?? '',
                foodTiming: data['foodTiming'] ?? '',
                isCritical: data['isCritical'] ?? 0,
                voiceUrl: data['voiceUrl'] ?? '',
                scheduledTime: data['scheduledTime'],
                voicePath: data['voicePath'] == 'none' ? null : data['voicePath'],
              ),
            ),
          );
        }
      },
    );

    // FCM Foreground Listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'stock_alert') {
        _showStockAlert(message);
      }
    });

    // FCM Background/Terminated Listener (on tap)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['type'] == 'stock_alert') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const MedicinesListScreen()),
        );
      }
    });
  }

  static Future<void> triggerMedicineAlarm({
    required int scheduleId,
    required int patientId,
    required int medicineId,
    required String medicineName,
    required String dose,
    required String foodTiming,
    required int isCritical,
    required String voiceUrl,
    required String scheduledTime,
    String? cachedVoicePath,
  }) async {
    // Aggressive priority channel bypassing Do Not Disturb
    const androidChannel = AndroidNotificationDetails(
      'nishchint_medical_alerts',
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
      'medicineId': medicineId,
      'medicineName': medicineName,
      'dose': dose,
      'foodTiming': foodTiming,
      'isCritical': isCritical,
      'voiceUrl': voiceUrl,
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

  static Future<void> _showStockAlert(RemoteMessage message) async {
    const androidChannel = AndroidNotificationDetails(
      'nishchint_stock_alerts',
      'Stock Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidChannel);

    await _notifications.show(
      id: 999, 
      title: message.notification?.title ?? 'Medicine Running Low',
      body: message.notification?.body ?? 'Please check your medicine stock.',
      notificationDetails: notificationDetails,
      payload: json.encode(message.data),
    );
  }
}
