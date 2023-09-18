import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationsServices {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AndroidInitializationSettings _androidInitializationSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');

  NotificationsServices() {
    initializeNotifications();
  }

  void initializeNotifications() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    InitializationSettings initializationSettings = InitializationSettings(
      android: _androidInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void sendNotification(String title, String body) async {
    AndroidNotificationDetails androidNotificationDetails =
        const AndroidNotificationDetails('channelId', 'channelName',
            importance: Importance.max, priority: Priority.high);
    NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
        0, title, body, notificationDetails);
  }

  void scheduleNotification() async {

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime absenDatangDibuka = tz.TZDateTime(tz.local, now.year, now.month, now.day, 6, 0);
    tz.TZDateTime absenDatangDitutup = tz.TZDateTime(tz.local, now.year, now.month, now.day, 11, 30);
    tz.TZDateTime absenPulangDibuka = tz.TZDateTime(tz.local, now.year, now.month, now.day, 12, 0);
    tz.TZDateTime absenPulangDitutup = tz.TZDateTime(tz.local, now.year, now.month, now.day, 17, 30);
    tz.TZDateTime absenLemburDibuka = tz.TZDateTime(tz.local, now.year, now.month, now.day, 18, 0);
    tz.TZDateTime absenLemburDitutup = tz.TZDateTime(tz.local, now.year, now.month, now.day, 23, 30);

    if (absenDatangDibuka.isBefore(now)) {
      absenDatangDibuka = absenDatangDibuka.add(const Duration(days: 1));
    }

    if (absenDatangDitutup.isBefore(now)) {
      absenDatangDitutup = absenDatangDitutup.add(const Duration(days: 1));
    }

    if (absenPulangDibuka.isBefore(now)) {
      absenPulangDibuka = absenPulangDibuka.add(const Duration(days: 1));
    }

    if (absenPulangDitutup.isBefore(now)) {
      absenPulangDitutup = absenPulangDitutup.add(const Duration(days: 1));
    }

    if (absenLemburDibuka.isBefore(now)) {
      absenLemburDibuka = absenLemburDibuka.add(const Duration(days: 1));
    }

    if (absenLemburDitutup.isBefore(now)) {
      absenLemburDitutup = absenLemburDitutup.add(const Duration(days: 1));
    }

    AndroidNotificationDetails androidNotificationDetails =
        const AndroidNotificationDetails(
      'channelId',
      'channelName',
      importance: Importance.max,
      priority: Priority.high,
    );

    NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Absen Datang Dibuka',
      'Absen Datang akan Ditutup pada Pukul 11.59',
      absenDatangDibuka,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Absen Datang Ditutup',
      'Absen Datang akan Segera Ditutup dalam 30 Menit',
      absenDatangDitutup,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      2,
      'Absen Pulang Dibuka',
      'Absen Pulang akan Ditutup pada Pukul 17.59',
      absenPulangDibuka,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      3,
      'Absen Pulang Ditutup',
      'Absen Pulang akan Segera Ditutup dalam 30 Menit',
      absenPulangDitutup,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      4,
      'Absen Lembur Dibuka',
      'Absen Lembur akan Ditutup pada Pukul 23.59',
      absenLemburDibuka,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      5,
      'Absen Lembur Ditutup',
      'Absen Lembur akan Segera Ditutup dalam 30 Menit',
      absenLemburDitutup,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  void stopNotifications() async {
    _flutterLocalNotificationsPlugin.cancel(0);
  }
}
