// Shared test fixtures: placeholder content (no real verses) and a fake notification service.
import 'package:sakina/core/content.dart';
import 'package:sakina/core/schedule.dart';
import 'package:sakina/state.dart';

/// Placeholder content for tests only (no real verses).
final testContent = Content.fromJson({
  'categories': [
    {'id': 'a', 'name': {'de': 'Kategorie A', 'en': 'Category A'}},
    {'id': 'b', 'name': {'de': 'Kategorie B', 'en': 'Category B'}},
  ],
  'ayat': [
    for (var i = 1; i <= 6; i++)
      {'surah': 9, 'ayah': i, 'arabic': 'نص $i', 'translation': {'de': 'Text $i', 'en': 'Text $i'}, 'categories': [i <= 4 ? 'a' : 'b']},
  ],
});

class FakeReminders implements Reminders {
  FakeReminders({this.canSchedule = true, this.allow = true});

  @override
  final bool canSchedule;
  final bool allow;
  int permissionRequests = 0;
  List<(PlannedReminder, Ayah)> scheduled = [];

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return allow;
  }

  @override
  Future<void> schedule(List<(PlannedReminder, Ayah)> items, String lang) async => scheduled = items;

  @override
  Future<void> showNow(Ayah ayah, String lang) async {}
}
