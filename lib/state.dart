// App state: user choices, saved verses and the reminder plan, persisted on the device.
import 'dart:convert';
import 'dart:math';

import 'package:family_ui/family_ui.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'core/content.dart';
import 'core/schedule.dart';

/// Delivers reminders. Implemented with local notifications; replaced by a fake in tests.
abstract class Reminders {
  bool get canSchedule;
  Future<bool> requestPermission();
  Future<void> schedule(List<(PlannedReminder, Ayah)> items, String lang);
  Future<void> showNow(Ayah ayah, String lang);
}

class AppState extends ChangeNotifier {
  AppState(this.content, this._prefs, this.reminders) {
    _load();
  }

  static const _key = 'sakina.v1';

  final Content content;
  final SharedPreferences _prefs;
  final Reminders reminders;

  // User choices
  String lang = 'de';
  ThemeMode themeMode = ThemeMode.system;
  double arabicScale = 1.0;
  Set<String> categories = {};
  bool remindersOn = false;
  List<int> times = [7 * 60, 13 * 60, 20 * 60]; // minutes of day, sorted
  Set<int> weekdays = {1, 2, 3, 4, 5, 6, 7};
  List<String> saved = []; // ayah ids, newest first
  bool welcomed = true; // false only on the very first start

  /// Topic chosen with "How do you feel?"; while set, Today shows verses from it.
  String? mood;

  /// Reminders that have been delivered, newest first.
  List<PlannedReminder> received = [];

  // Reading position and reminder sequence
  int _seed = 0;
  int _browseIndex = 0;
  String? _currentId;
  int _cursor = 0;
  int _lastSeenIndex = -1;
  int _moodIndex = 0;
  List<PlannedReminder> plan = [];

  /// Bumped when the Today tab should be shown (e.g. a notification was opened).
  final showToday = ValueNotifier<int>(0);

  List<String> get poolIds => content.poolIds(categories);

  /// The verse shown on the Today tab.
  Ayah? get current {
    if (mood != null) {
      final id = ayahAt(content.poolIds({mood!}), _browseSeed ^ mood.hashCode, _moodIndex);
      return id == null ? null : content.byId(id);
    }
    final pool = poolIds;
    final id = (_currentId != null && pool.contains(_currentId)) ? _currentId : ayahAt(pool, _browseSeed, _browseIndex);
    return id == null ? null : content.byId(id);
  }

  bool get canGoBack => mood != null ? _moodIndex > 0 : _browseIndex > 0;
  bool isSaved(String id) => saved.contains(id);

  /// Next reminder that hasn't fired yet.
  PlannedReminder? nextReminder(int nowMs) {
    for (final p in plan) {
      if (p.time > nowMs) return p;
    }
    return null;
  }

  // Browsing uses its own shuffle so it doesn't reveal the upcoming reminders.
  int get _browseSeed => _seed ^ 0x5bd1e995;

  // --- Reading ---

  void next() => mood != null ? _browseMood(_moodIndex + 1) : _browse(_browseIndex + 1);
  void previous() => mood != null ? _browseMood(max(0, _moodIndex - 1)) : _browse(max(0, _browseIndex - 1));

  void _browseMood(int index) {
    _moodIndex = index;
    _commit();
  }

  /// Shows verses for a feeling (by its topic id); choosing the same one again goes back to all verses.
  void feel(String? categoryId) {
    mood = categoryId == mood ? null : categoryId;
    _moodIndex = 0;
    _commit();
  }

  /// Ends the first-start welcome; with [reminders] it switches them on (false if permission was denied).
  Future<bool> finishWelcome({bool reminders = false}) async {
    final ok = reminders ? await setRemindersOn(true) : true;
    welcomed = true;
    _commit();
    return ok;
  }

  void _browse(int index) {
    _browseIndex = index;
    _currentId = ayahAt(poolIds, _browseSeed, index);
    _commit();
  }

  /// Show a specific verse, e.g. from a notification or the saved list.
  void open(String ayahId) {
    if (content.byId(ayahId) == null) return;
    mood = null;
    _currentId = ayahId;
    showToday.value++;
    _commit();
  }

  /// Saves or un-saves; returns an undo function.
  VoidCallback toggleSaved(String id) {
    final before = List<String>.of(saved);
    saved = saved.contains(id) ? (saved..remove(id)) : [id, ...saved];
    _commit();
    return () {
      saved = before;
      _commit();
    };
  }

  // --- Choices ---

  Future<void> toggleCategory(String id) async {
    categories = categories.contains(id) ? ({...categories}..remove(id)) : {...categories, id};
    _currentId = null;
    _browseIndex = 0;
    await refresh();
  }

  /// Turning reminders on asks for permission first; returns false if it was denied.
  Future<bool> setRemindersOn(bool on) async {
    // In the browser nothing is scheduled, so no permission is needed to preview the plan.
    if (on && reminders.canSchedule && !await reminders.requestPermission()) return false;
    remindersOn = on;
    await refresh();
    return true;
  }

  Future<void> addTime(int minutes) async {
    times = ({...times, minutes}.toList()..sort());
    await refresh();
  }

  Future<void> removeTime(int minutes) async {
    times = [...times]..remove(minutes);
    await refresh();
  }

  Future<void> toggleWeekday(int day) async {
    weekdays = weekdays.contains(day) ? ({...weekdays}..remove(day)) : {...weekdays, day};
    await refresh();
  }

  Future<void> setLang(String value) async {
    lang = value;
    await refresh(); // notification texts use the language
  }

  void setThemeMode(ThemeMode value) {
    themeMode = value;
    _commit();
  }

  void setArabicScale(double value) {
    arabicScale = value;
    _commit();
  }

  /// Returns false if notifications aren't allowed.
  Future<bool> sendTest() async {
    final ayah = current;
    if (ayah == null) return true;
    if (!await reminders.requestPermission()) return false;
    await reminders.showNow(ayah, lang);
    return true;
  }

  // --- Reminders ---

  /// Call on start, on resume and after relevant changes: shows the newest delivered reminder
  /// and plans the next days of reminders.
  Future<void> refresh([tz.TZDateTime? at]) async {
    final now = at ?? tz.TZDateTime.now(tz.local);
    final nowMs = now.millisecondsSinceEpoch;

    final delivered = lastDelivered(plan, nowMs);
    if (delivered != null && delivered.index > _lastSeenIndex) {
      _lastSeenIndex = delivered.index;
      _currentId = delivered.ayahId;
      mood = null;
    }
    // Keep what was delivered before the plan is rebuilt, so it can be found again.
    final known = {for (final r in received) r.time};
    final arrived = [for (final p in plan) if (p.time <= nowMs && !known.contains(p.time)) p];
    if (arrived.isNotEmpty) received = [...arrived.reversed, ...received].take(50).toList();

    _cursor = nextIndex(plan, nowMs, _cursor);
    final pool = poolIds;
    // The plan is also built in the browser (to preview it); only delivery needs a phone.
    plan = remindersOn && pool.isNotEmpty
        ? buildPlan(upcomingSlots(now, times, weekdays), pool, _seed, _cursor)
        : [];
    _commit();
    await reminders.schedule([for (final p in plan) (p, content.byId(p.ayahId)!)], lang);
  }

  // --- Persistence ---

  void _commit() {
    _prefs.setString(_key, jsonEncode(_toJson()));
    notifyListeners();
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      // First start: device language, everything selected, fresh shuffle.
      lang = deviceLang('en');
      categories = {for (final c in content.categories) c.id};
      _seed = Random().nextInt(1 << 31);
      welcomed = false;
      return;
    }
    final j = jsonDecode(raw) as Map<String, dynamic>;
    lang = j['lang'] as String? ?? lang;
    themeMode = ThemeMode.values.byName(j['theme'] as String? ?? 'system');
    arabicScale = (j['arabicScale'] as num?)?.toDouble() ?? arabicScale;
    final known = {for (final c in content.categories) c.id};
    categories = {for (final c in j['categories'] as List? ?? []) if (known.contains(c)) c as String};
    remindersOn = j['remindersOn'] as bool? ?? false;
    times = [for (final t in j['times'] as List? ?? times) t as int]..sort();
    weekdays = {for (final d in j['weekdays'] as List? ?? weekdays) d as int};
    saved = [for (final s in j['saved'] as List? ?? []) s as String];
    welcomed = j['welcomed'] as bool? ?? true;
    mood = j['mood'] as String?;
    if (mood != null && !known.contains(mood)) mood = null;
    _moodIndex = j['moodIndex'] as int? ?? 0;
    received = [for (final r in j['received'] as List? ?? []) PlannedReminder.fromJson(r as Map<String, dynamic>)];
    _seed = j['seed'] as int? ?? 0;
    _browseIndex = j['browse'] as int? ?? 0;
    _currentId = j['current'] as String?;
    _cursor = j['cursor'] as int? ?? 0;
    _lastSeenIndex = j['lastSeen'] as int? ?? -1;
    plan = [for (final p in j['plan'] as List? ?? []) PlannedReminder.fromJson(p as Map<String, dynamic>)];
  }

  Map<String, Object?> _toJson() => {
        'lang': lang,
        'theme': themeMode.name,
        'arabicScale': arabicScale,
        'categories': categories.toList(),
        'remindersOn': remindersOn,
        'times': times,
        'weekdays': weekdays.toList()..sort(),
        'saved': saved,
        'welcomed': welcomed,
        'mood': mood,
        'moodIndex': _moodIndex,
        'received': [for (final r in received) r.toJson()],
        'seed': _seed,
        'browse': _browseIndex,
        'current': _currentId,
        'cursor': _cursor,
        'lastSeen': _lastSeenIndex,
        'plan': [for (final p in plan) p.toJson()],
      };
}
