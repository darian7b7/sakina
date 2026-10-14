import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/schedule.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tzdata.initializeTimeZones();
  final berlin = tz.getLocation('Europe/Berlin');
  tz.TZDateTime at(int y, int m, int d, [int h = 0, int min = 0]) => tz.TZDateTime(berlin, y, m, d, h, min);
  const everyDay = {1, 2, 3, 4, 5, 6, 7};

  group('upcomingSlots', () {
    test('lists the remaining times today, then the following days', () {
      final slots = upcomingSlots(at(2026, 10, 14, 12), [7 * 60, 13 * 60, 21 * 60], everyDay, days: 2);
      expect(slots, [at(2026, 10, 14, 13), at(2026, 10, 14, 21), at(2026, 10, 15, 7), at(2026, 10, 15, 13), at(2026, 10, 15, 21)]);
    });

    test('a time equal to now is not scheduled again', () {
      expect(upcomingSlots(at(2026, 10, 14, 13), [13 * 60], everyDay, days: 1), isEmpty);
    });

    test('skips weekdays that are switched off', () {
      // 2026-10-14 is a Wednesday.
      final slots = upcomingSlots(at(2026, 10, 14), [9 * 60], {DateTime.saturday, DateTime.sunday});
      expect(slots, [at(2026, 10, 17, 9), at(2026, 10, 18, 9)]);
    });

    test('sorts and de-duplicates times', () {
      final slots = upcomingSlots(at(2026, 10, 14), [21 * 60, 7 * 60, 7 * 60], everyDay, days: 1);
      expect(slots, [at(2026, 10, 14, 7), at(2026, 10, 14, 21)]);
    });

    test('stops at the limit', () {
      final slots = upcomingSlots(at(2026, 10, 14), List.generate(20, (i) => i * 60), everyDay);
      expect(slots.length, maxPlanned);
    });

    test('keeps wall-clock times across the autumn DST change', () {
      // Clocks go back on 2026-10-25 in Berlin; 07:00 must stay 07:00 local time.
      final slots = upcomingSlots(at(2026, 10, 24, 8), [7 * 60], everyDay, days: 3);
      expect(slots.map((t) => '${t.day} ${t.hour}:${t.minute} ${t.timeZoneOffset.inHours}'), ['25 7:0 1', '26 7:0 1']);
      expect(slots[0].difference(at(2026, 10, 24, 7)), const Duration(hours: 25));
    });

    test('keeps wall-clock times across the spring DST change', () {
      final slots = upcomingSlots(at(2026, 3, 28, 8), [7 * 60], everyDay, days: 2);
      expect(slots.single.difference(at(2026, 3, 28, 7)), const Duration(hours: 23));
    });
  });

  group('ayahAt', () {
    final pool = List.generate(7, (i) => '1:${i + 1}');

    test('is deterministic', () {
      expect([for (var i = 0; i < 20; i++) ayahAt(pool, 42, i)], [for (var i = 0; i < 20; i++) ayahAt(pool, 42, i)]);
    });

    test('shows every ayah once per round, and rounds differ', () {
      final round1 = [for (var i = 0; i < 7; i++) ayahAt(pool, 42, i)];
      final round2 = [for (var i = 7; i < 14; i++) ayahAt(pool, 42, i)];
      expect(round1.toSet(), pool.toSet());
      expect(round2.toSet(), pool.toSet());
      expect(round1, isNot(round2));
    });

    test('never shows the same ayah twice in a row, also across rounds', () {
      for (var seed = 1; seed < 200; seed++) {
        final seq = [for (var i = 0; i < 50; i++) ayahAt(pool, seed, i)];
        for (var i = 1; i < seq.length; i++) {
          expect(seq[i], isNot(seq[i - 1]), reason: 'seed $seed, position $i');
        }
      }
    });

    test('handles small pools', () {
      expect(ayahAt([], 1, 0), isNull);
      expect(ayahAt(['2:153'], 1, 5), '2:153');
    });

    test('matches known values (guards against platform differences)', () {
      expect([for (var i = 0; i < 7; i++) ayahAt(pool, 12345, i)], kExpectedOrder);
    });
  });

  group('plan', () {
    final pool = List.generate(10, (i) => '3:${i + 1}');
    final slots = upcomingSlots(at(2026, 10, 14, 6), [7 * 60, 13 * 60, 21 * 60], everyDay);

    test('assigns consecutive positions starting at the cursor', () {
      final plan = buildPlan(slots, pool, 7, 4);
      expect(plan.first.index, 4);
      expect(plan.last.index, 4 + slots.length - 1);
      expect(plan.first.ayahId, ayahAt(pool, 7, 4));
    });

    test('rescheduling continues after delivered reminders without skipping or repeating', () {
      final plan = buildPlan(slots, pool, 7, 0);
      final afterTwo = plan[1].time; // first two have fired
      expect(nextIndex(plan, afterTwo, 0), 2);
      expect(lastDelivered(plan, afterTwo)!.index, 1);

      // Rebuild later the same day: the new plan starts exactly where the old one would have.
      final later = tz.TZDateTime.fromMillisecondsSinceEpoch(berlin, afterTwo);
      final replanned = buildPlan(upcomingSlots(later, [7 * 60, 13 * 60, 21 * 60], everyDay), pool, 7, nextIndex(plan, afterTwo, 0));
      expect(replanned.first.ayahId, plan[2].ayahId);
      expect(replanned.first.time, plan[2].time);
    });

    test('after every reminder fired, continues after the last one', () {
      final plan = buildPlan(slots, pool, 7, 0);
      expect(nextIndex(plan, plan.last.time + 1, 0), plan.length);
      expect(nextIndex(const [], 0, 9), 9);
    });

    test('survives a JSON round trip', () {
      final p = buildPlan(slots, pool, 7, 0).first;
      final back = PlannedReminder.fromJson(p.toJson());
      expect([back.time, back.index, back.ayahId], [p.time, p.index, p.ayahId]);
    });
  });
}

/// Recorded from the Dart VM; the web test run must produce the same order.
const kExpectedOrder = ['1:3', '1:2', '1:4', '1:7', '1:6', '1:1', '1:5'];
