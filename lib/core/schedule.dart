// When reminders fire and which ayah each one shows. Pure Dart: no Flutter imports.
import 'package:timezone/timezone.dart' as tz;

/// iOS keeps at most 64 pending notifications per app; stay below that.
const maxPlanned = 60;

/// Reminder times after [now] for the next [days] days (today included), at most [limit].
/// [minutesOfDay] are wall-clock times (e.g. 13:00 = 780), [weekdays] use DateTime.monday…sunday.
/// Times are built per calendar day in [now]'s location, so daylight-saving changes are handled.
List<tz.TZDateTime> upcomingSlots(
  tz.TZDateTime now,
  List<int> minutesOfDay,
  Set<int> weekdays, {
  int days = 7,
  int limit = maxPlanned,
}) {
  final times = minutesOfDay.toSet().toList()..sort();
  final slots = <tz.TZDateTime>[];
  for (var d = 0; d < days; d++) {
    final date = tz.TZDateTime(now.location, now.year, now.month, now.day + d);
    if (!weekdays.contains(date.weekday)) continue;
    for (final m in times) {
      final t = tz.TZDateTime(now.location, date.year, date.month, date.day, m ~/ 60, m % 60);
      if (!t.isAfter(now)) continue;
      slots.add(t);
      if (slots.length == limit) return slots;
    }
  }
  return slots;
}

/// The ayah at position [index] of an endless sequence over [poolIds]. Each round of
/// poolIds.length positions is a fresh shuffle, so no ayah repeats before all others were shown.
String? ayahAt(List<String> poolIds, int seed, int index) {
  final n = poolIds.length;
  if (n == 0) return null;
  final order = _roundOrder(n, seed, index ~/ n);
  return poolIds[order[index % n]];
}

List<int> _roundOrder(int n, int seed, int round) {
  final order = _shuffle(n, seed, round);
  // Don't start a round with the ayah that ended the previous one.
  if (round > 0 && n > 2 && order.first == _shuffle(n, seed, round - 1).last) {
    final first = order[0];
    order[0] = order[1];
    order[1] = first;
  }
  return order;
}

/// Fisher–Yates with a small deterministic generator (same result on every platform).
List<int> _shuffle(int n, int seed, int round) {
  final next = _mulberry32((seed ^ (round * 0x9E3779B9)) & 0xFFFFFFFF);
  final order = List<int>.generate(n, (i) => i);
  for (var i = n - 1; i > 0; i--) {
    final j = next() % (i + 1);
    final t = order[i];
    order[i] = order[j];
    order[j] = t;
  }
  return order;
}

int Function() _mulberry32(int state) {
  return () {
    state = (state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = state;
    t = _imul(t ^ (t >> 15), t | 1);
    t ^= (t + _imul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF;
    return (t ^ (t >> 14)) & 0xFFFFFFFF;
  };
}

/// 32-bit multiplication that gives the same result natively and on the web.
int _imul(int a, int b) {
  final lo = ((a & 0xFFFF) * b) & 0xFFFFFFFF;
  final hi = (((a >> 16) & 0xFFFF) * b & 0xFFFF) << 16;
  return (lo + hi) & 0xFFFFFFFF;
}

/// One scheduled reminder: when, its position in the sequence, and the ayah it shows.
class PlannedReminder {
  const PlannedReminder(this.time, this.index, this.ayahId);

  final int time; // epoch milliseconds
  final int index;
  final String ayahId;

  Map<String, Object> toJson() => {'t': time, 'i': index, 'a': ayahId};

  factory PlannedReminder.fromJson(Map<String, dynamic> j) =>
      PlannedReminder(j['t'] as int, j['i'] as int, j['a'] as String);
}

/// Where the sequence continues: at the first reminder that hasn't fired yet, or after the
/// last one that has. Rescheduling therefore never skips or repeats an ayah.
int nextIndex(List<PlannedReminder> previous, int nowMs, int fallback) {
  for (final p in previous) {
    if (p.time > nowMs) return p.index;
  }
  return previous.isEmpty ? fallback : previous.last.index + 1;
}

/// The most recent reminder that has already fired, if any.
PlannedReminder? lastDelivered(List<PlannedReminder> plan, int nowMs) {
  PlannedReminder? last;
  for (final p in plan) {
    if (p.time <= nowMs) last = p;
  }
  return last;
}

/// Assigns ayat to [slots], continuing the sequence at [startIndex].
List<PlannedReminder> buildPlan(List<tz.TZDateTime> slots, List<String> poolIds, int seed, int startIndex) {
  if (poolIds.isEmpty) return const [];
  return [
    for (final (i, t) in slots.indexed)
      PlannedReminder(t.millisecondsSinceEpoch, startIndex + i, ayahAt(poolIds, seed, startIndex + i)!),
  ];
}
