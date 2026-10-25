// Verse reminders on top of the family's local notifications.
import 'package:family_reminders/family_reminders.dart';

import 'core/content.dart';
import 'core/schedule.dart';
import 'core/strings.dart';
import 'state.dart';

class LocalReminders implements Reminders {
  final _notifier = LocalNotifier(channelId: 'reminders');

  /// Called with the ayah id when a notification is tapped while the app runs.
  set onOpen(void Function(String ayahId)? f) => _notifier.onOpen = f;

  @override
  bool get canSchedule => _notifier.canSchedule;

  /// Returns the ayah id if the app was launched by tapping a notification.
  Future<String?> init() => _notifier.init();

  @override
  Future<bool> requestPermission() => _notifier.requestPermission();

  @override
  Future<void> schedule(List<(PlannedReminder, Ayah)> items, String lang) => _notifier.scheduleAll(
        [for (final (p, ayah) in items) (DateTime.fromMillisecondsSinceEpoch(p.time), _notice(ayah, lang))],
        channelName: tr(lang, 'reminders'),
        lang: lang,
      );

  @override
  Future<void> showNow(Ayah ayah, String lang) =>
      _notifier.showNow(_notice(ayah, lang), channelName: tr(lang, 'reminders'), lang: lang);

  Notice _notice(Ayah ayah, String lang) {
    final translation = ayah.translation(lang);
    return Notice(
      title: '$appName · ${ayah.surah}:${ayah.ayah}', // short and clear: "Sakina · 3:16"
      body: translation ?? ayah.arabic,
      expandedBody: translation == null ? ayah.arabic : '${ayah.arabic}\n\n$translation',
      payload: ayah.id,
    );
  }
}
