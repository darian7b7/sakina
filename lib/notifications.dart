// Local notifications. Scheduling works on Android and iOS; the browser can only show one immediately.
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'core/content.dart';
import 'core/schedule.dart';
import 'core/strings.dart';
import 'state.dart';

class LocalReminders implements Reminders {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Called with the ayah id when a notification is tapped while the app runs.
  void Function(String ayahId)? onOpen;

  @override
  bool get canSchedule => !kIsWeb;

  /// Returns the ayah id if the app was launched by tapping a notification.
  Future<String?> init() async {
    try {
      _ready = await _plugin.initialize(
            settings: const InitializationSettings(
              android: AndroidInitializationSettings('@mipmap/ic_launcher'),
              // Permission is asked when reminders are switched on, not at launch.
              iOS: DarwinInitializationSettings(
                requestAlertPermission: false,
                requestBadgePermission: false,
                requestSoundPermission: false,
              ),
              web: WebInitializationSettings(),
            ),
            onDidReceiveNotificationResponse: (r) {
              if (r.payload != null) onOpen?.call(r.payload!);
            },
          ) ??
          false;
      if (!_ready || kIsWeb) return null;
      final launch = await _plugin.getNotificationAppLaunchDetails();
      return launch?.didNotificationLaunchApp == true ? launch!.notificationResponse?.payload : null;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
      return null;
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      if (kIsWeb) {
        return await _plugin.resolvePlatformSpecificImplementation<WebFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission() ?? false;
      }
      return await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission() ??
          await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, sound: true) ??
          false;
    } catch (e) {
      debugPrint('Permission request failed: $e');
      return false;
    }
  }

  @override
  Future<void> schedule(List<(PlannedReminder, Ayah)> items, String lang) async {
    if (!_ready || !canSchedule) return;
    // Pending ones only, so reminders already in the notification shade stay visible.
    await _plugin.cancelAllPendingNotifications();
    for (final (i, (p, ayah)) in items.indexed) {
      final (title, body) = _texts(ayah, lang);
      await _plugin.zonedSchedule(
        id: i,
        scheduledDate: tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, p.time),
        title: title,
        body: body,
        payload: ayah.id,
        notificationDetails: _details(ayah, lang),
        // A few minutes' leeway is fine for reminders and needs no exact-alarm permission.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> showNow(Ayah ayah, String lang) async {
    if (!_ready) return;
    final (title, body) = _texts(ayah, lang);
    await _plugin.show(id: 999, title: title, body: body, payload: ayah.id, notificationDetails: _details(ayah, lang));
  }

  (String, String) _texts(Ayah ayah, String lang) =>
      ('$appName · ${tr(lang, 'reference', {'s': ayah.surah, 'a': ayah.ayah})}', ayah.translation(lang) ?? ayah.arabic);

  NotificationDetails _details(Ayah ayah, String lang) {
    final translation = ayah.translation(lang);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        tr(lang, 'reminders'),
        styleInformation: BigTextStyleInformation(translation == null ? ayah.arabic : '${ayah.arabic}\n\n$translation'),
      ),
      iOS: const DarwinNotificationDetails(),
      web: WebNotificationDetails(lang: lang),
    );
  }
}
