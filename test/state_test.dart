import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  final berlin = tz.getLocation('Europe/Berlin');
  tz.TZDateTime at(int d, int h, [int m = 0]) => tz.TZDateTime(berlin, 2026, 10, d, h, m);

  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('first start selects every category and shows a verse', () {
    final s = AppState(testContent, prefs, FakeReminders());
    expect(s.categories, {'a', 'b'});
    expect(s.current, isNotNull);
    expect(s.remindersOn, isFalse);
  });

  test('switching reminders on asks permission and schedules the next days', () async {
    final fake = FakeReminders();
    final s = AppState(testContent, prefs, fake);
    expect(await s.setRemindersOn(true), isTrue);
    await s.refresh(at(14, 12));
    expect(fake.permissionRequests, 1);
    // 3 default times × 7 days, minus 07:00 today which has passed → 20.
    expect(fake.scheduled.length, 20);
    expect(fake.scheduled.first.$1.time, at(14, 13).millisecondsSinceEpoch);
  });

  test('denied permission leaves reminders off', () async {
    final s = AppState(testContent, prefs, FakeReminders(allow: false));
    expect(await s.setRemindersOn(true), isFalse);
    expect(s.remindersOn, isFalse);
    expect(s.plan, isEmpty);
  });

  test('in the browser the plan is built for preview without asking permission', () async {
    final fake = FakeReminders(canSchedule: false);
    final s = AppState(testContent, prefs, fake);
    await s.setRemindersOn(true);
    await s.refresh(at(14, 12));
    expect(fake.permissionRequests, 0);
    expect(s.plan, isNotEmpty);
  });

  test('a delivered reminder becomes the verse on the Today tab', () async {
    final s = AppState(testContent, prefs, FakeReminders());
    await s.setRemindersOn(true);
    await s.refresh(at(14, 12));
    final first = s.plan.first; // today 13:00
    await s.refresh(at(14, 13, 5));
    expect(s.current!.id, first.ayahId);
    expect(s.plan.first.time, at(14, 20).millisecondsSinceEpoch, reason: 'delivered one is no longer pending');
  });

  test('replanning later keeps the same upcoming verses', () async {
    final s = AppState(testContent, prefs, FakeReminders());
    await s.setRemindersOn(true);
    await s.refresh(at(14, 12));
    final upcoming = s.plan.skip(1).take(5).map((p) => p.ayahId).toList();
    await s.refresh(at(14, 14));
    expect(s.plan.take(5).map((p) => p.ayahId).toList(), upcoming);
  });

  test('unselecting all categories empties Today and the plan', () async {
    final s = AppState(testContent, prefs, FakeReminders());
    await s.setRemindersOn(true);
    await s.toggleCategory('a');
    await s.toggleCategory('b');
    expect(s.current, isNull);
    expect(s.plan, isEmpty);
  });

  test('only verses of selected categories are shown', () async {
    final s = AppState(testContent, prefs, FakeReminders());
    await s.toggleCategory('a'); // only b left: 9:5, 9:6
    for (var i = 0; i < 6; i++) {
      expect(['9:5', '9:6'], contains(s.current!.id));
      s.next();
    }
  });

  test('next and previous browse without repeating neighbours', () {
    final s = AppState(testContent, prefs, FakeReminders());
    final first = s.current!.id;
    expect(s.canGoBack, isFalse);
    s.next();
    expect(s.current!.id, isNot(first));
    s.previous();
    expect(s.current!.id, first);
  });

  test('saving can be undone', () {
    final s = AppState(testContent, prefs, FakeReminders());
    final undo = s.toggleSaved('9:2');
    expect(s.isSaved('9:2'), isTrue);
    undo();
    expect(s.isSaved('9:2'), isFalse);
  });

  test('everything survives a restart', () async {
    final s = AppState(testContent, prefs, FakeReminders());
    await s.setRemindersOn(true);
    await s.addTime(9 * 60 + 30);
    await s.toggleWeekday(DateTime.sunday);
    await s.setLang('en');
    s.setThemeMode(ThemeMode.dark);
    s.toggleSaved('9:3');
    s.next();
    await s.refresh(at(14, 12));

    final r = AppState(testContent, prefs, FakeReminders());
    expect(r.remindersOn, isTrue);
    expect(r.times, [7 * 60, 9 * 60 + 30, 13 * 60, 20 * 60]);
    expect(r.weekdays.contains(DateTime.sunday), isFalse);
    expect([r.lang, r.themeMode], ['en', ThemeMode.dark]);
    expect(r.saved, ['9:3']);
    expect(r.current!.id, s.current!.id);
    expect(r.plan.map((p) => p.ayahId), s.plan.map((p) => p.ayahId));
  });

  test('only the very first start shows the welcome', () async {
    final s = AppState(testContent, prefs, FakeReminders());
    expect(s.welcomed, isFalse);
    await s.finishWelcome();
    expect(AppState(testContent, prefs, FakeReminders()).welcomed, isTrue);
  });

  test('a feeling browses its own topic and survives a restart', () {
    final s = AppState(testContent, prefs, FakeReminders());
    s.feel('b');
    expect(s.current!.categories, contains('b'));
    s.next();
    expect(s.current!.categories, contains('b'));
    expect(s.canGoBack, isTrue);
    final again = AppState(testContent, prefs, FakeReminders());
    expect(again.mood, 'b');
    expect(again.current!.id, s.current!.id);
    s.open('9:1');
    expect(s.mood, isNull, reason: 'opening a verse leaves the feeling');
  });

  test('delivered reminders are kept, newest first, without duplicates', () async {
    final s = AppState(testContent, prefs, FakeReminders());
    await s.setRemindersOn(true);
    await s.refresh(at(14, 12));
    await s.refresh(at(14, 21)); // 13:00 and 20:00 have been delivered
    await s.refresh(at(14, 22));
    expect([for (final r in s.received) r.time], [at(14, 20).millisecondsSinceEpoch, at(14, 13).millisecondsSinceEpoch]);
    expect(AppState(testContent, prefs, FakeReminders()).received.length, 2);
  });
}
