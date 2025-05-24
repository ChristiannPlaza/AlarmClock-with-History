import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

class AlarmService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> _showAlarmNotification(AlarmInfo alarm) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      channelDescription: 'Notifications for alarm triggers',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      actions: [
        const AndroidNotificationAction(
          'stop_alarm',
          'Stop Alarm',
          showsUserInterface: true,
        ),
      ],
      // Make notification dismissible
      ongoing: false,
      autoCancel: true,
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'alarm_sound.mp3',
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      alarm.id!,
      'Alarm',
      'Time to wake up!',
      platformChannelSpecifics,
      payload: json.encode(alarm.toJson()),
    );
  }
} 