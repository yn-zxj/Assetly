import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/models.dart';
import '../data/app_database.dart';

@pragma('vm:entry-point')
void handleMedicationNotification(NotificationResponse response) async {
  final medicineId = response.payload;
  if (medicineId == null || medicineId.isEmpty) return;
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  await database.open();
  if (response.actionId == 'take') {
    await database.recordDoseById(medicineId);
  } else if (response.actionId == 'snooze') {
    final medicine = await database.getMedicine(medicineId);
    if (medicine != null) {
      final notifications = NotificationService();
      await notifications.initialize();
      await notifications.scheduleSnooze(medicine);
    }
  }
}

class NotificationService {
  final plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: handleMedicationNotification,
        onDidReceiveBackgroundNotificationResponse:
            handleMedicationNotification,
      );
    } catch (error) {
      debugPrint('Notifications unavailable on this platform: $error');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final android = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final notification =
          await android?.requestNotificationsPermission() ?? true;
      final exact = await android?.requestExactAlarmsPermission() ?? true;
      final ios =
          await plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          true;
      return notification && exact && ios;
    } catch (_) {
      return false;
    }
  }

  Future<void> scheduleMedicine(Medicine medicine) async {
    await cancelMedicine(medicine);
    for (var index = 0; index < medicine.slots.length; index++) {
      final parts = medicine.slots[index].split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]) ?? 8,
          minute = int.tryParse(parts[1]) ?? 0;
      final now = tz.TZDateTime.now(tz.local);
      var when = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
      await plugin.zonedSchedule(
        id: medicine.id.hashCode.abs() % 100000 + index,
        title: '用药提醒 · ${medicine.name}',
        body:
            '${medicine.dosageInstructions} · 剩余 ${medicine.remainingQuantity.toStringAsFixed(0)} ${medicine.unit}',
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_exact',
            '精准服药提醒',
            channelDescription: '锁屏与后台状态下的准时服药提醒',
            importance: Importance.max,
            priority: Priority.high,
            actions: [
              AndroidNotificationAction('take', '已服用'),
              AndroidNotificationAction('snooze', '15分钟后'),
            ],
          ),
          iOS: DarwinNotificationDetails(categoryIdentifier: 'medication'),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: medicine.id,
      );
    }
  }

  Future<void> scheduleSnooze(Medicine medicine) async {
    await plugin.zonedSchedule(
      id: medicine.id.hashCode.abs() % 100000 + 90,
      title: '稍后提醒 · ${medicine.name}',
      body: medicine.dosageInstructions,
      scheduledDate: tz.TZDateTime.now(
        tz.local,
      ).add(const Duration(minutes: 15)),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_exact',
          '精准服药提醒',
          importance: Importance.max,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction('take', '已服用'),
            AndroidNotificationAction('snooze', '再等15分钟'),
          ],
        ),
        iOS: DarwinNotificationDetails(categoryIdentifier: 'medication'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: medicine.id,
    );
  }

  Future<void> cancelMedicine(Medicine medicine) async {
    for (var i = 0; i < 8; i++) {
      await plugin.cancel(id: medicine.id.hashCode.abs() % 100000 + i);
    }
  }
}
