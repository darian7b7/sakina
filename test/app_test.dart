import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/content.dart';
import 'package:sakina/main.dart';
import 'package:sakina/state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'helpers.dart';

Future<AppState> pump(WidgetTester tester, {Content? content, bool welcome = false}) async {
  SharedPreferences.setMockInitialValues({});
  final state = AppState(content ?? testContent, await SharedPreferences.getInstance(), FakeReminders());
  await state.setLang('de');
  if (!welcome) await state.finishWelcome();
  await tester.pumpWidget(SakinaApp(state));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Berlin'));

  testWidgets('Today shows a verse and Weiter moves on', (tester) async {
    final state = await pump(tester);
    final first = state.current!;
    expect(find.text('Sure 9, Vers ${first.ayah}'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(state.current!.id, isNot(first.id));
  });

  testWidgets('saving a verse shows it on the Saved tab', (tester) async {
    final state = await pump(tester);
    await tester.tap(find.byTooltip('Speichern'));
    await tester.tap(find.text('Meine Verse'));
    await tester.pumpAndSettle();
    expect(find.text('Sure 9, Vers ${state.current!.ayah}'), findsOneWidget);
  });

  testWidgets('categories can be switched off and Today explains what to do', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Bibliothek'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Heute'));
    await tester.pumpAndSettle();
    expect(find.text('Wähle mindestens eine Kategorie, um Verse zu sehen.'), findsOneWidget);
  });

  testWidgets('an empty content file shows how to add verses', (tester) async {
    await pump(tester, content: Content.fromJson({}));
    expect(find.textContaining('assets/ayat.json'), findsOneWidget);
  });

  testWidgets('settings turn reminders on and list what comes next', (tester) async {
    final state = await pump(tester);
    await tester.tap(find.byTooltip('Einstellungen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erinnerungen senden'));
    await tester.pumpAndSettle();
    expect(state.remindersOn, isTrue);
    expect(find.text('Als Nächstes'), findsOneWidget);
    expect(find.textContaining('Sure 9, Vers'), findsWidgets);
  });

  testWidgets('first start: the welcome explains Sakina and can switch reminders on', (tester) async {
    final state = await pump(tester, welcome: true);
    expect(find.text('Ein ruhiger Vers, wenn du ihn brauchst'), findsOneWidget);
    await tester.tap(find.text('Erinnerungen einschalten'));
    await tester.pumpAndSettle();
    expect(state.welcomed, isTrue);
    expect(state.remindersOn, isTrue);
    expect(find.text('Weiter'), findsOneWidget, reason: 'Today is shown next');
  });

  testWidgets('a feeling shows verses from its topic, and tapping it again goes back', (tester) async {
    final content = Content.fromJson({
      'categories': [
        {'id': 'hope', 'name': {'de': 'Hoffnung'}},
        {'id': 'trust', 'name': {'de': 'Gottvertrauen'}},
      ],
      'ayat': [
        {'surah': 94, 'ayah': 5, 'arabic': 'أ', 'translation': {'de': 'Hoffnungsvers'}, 'categories': ['hope']},
        {'surah': 65, 'ayah': 3, 'arabic': 'ب', 'translation': {'de': 'Vertrauensvers'}, 'categories': ['trust']},
      ],
    });
    final state = await pump(tester, content: content);
    expect(find.text('Wie fühlst du dich?'), findsOneWidget);
    expect(find.text('Dankbar'), findsNothing, reason: 'no gratitude topic in this content');
    await tester.tap(find.text('Traurig'));
    await tester.pumpAndSettle();
    expect(state.current!.id, '94:5');
    await tester.tap(find.text('Besorgt'));
    await tester.pumpAndSettle();
    expect(state.current!.id, '65:3');
    await tester.tap(find.text('Besorgt'));
    await tester.pumpAndSettle();
    expect(state.mood, isNull);
  });

  testWidgets('the library searches verses and opens a topic', (tester) async {
    final state = await pump(tester);
    await tester.tap(find.text('Bibliothek'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Text 5');
    await tester.pumpAndSettle();
    expect(find.text('Sure 9, Vers 5'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'nichts');
    await tester.pumpAndSettle();
    expect(find.text('Kein Vers gefunden.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kategorie B'));
    await tester.pumpAndSettle();
    expect(find.text('Sure 9, Vers 6'), findsOneWidget);
    await tester.tap(find.text('Sure 9, Vers 6'));
    await tester.pumpAndSettle();
    expect(state.current!.id, '9:6');
    expect(find.text('Weiter'), findsOneWidget, reason: 'back on Today');
  });

  testWidgets('received reminders are listed on the Saved tab', (tester) async {
    final state = await pump(tester);
    await tester.tap(find.text('Meine Verse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erhalten'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hier erscheinen die Verse'), findsOneWidget);
    await state.setRemindersOn(true);
    final first = state.plan.first;
    await state.refresh(tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, first.time + 60000));
    await tester.pumpAndSettle();
    expect(find.text('Sure 9, Vers ${state.content.byId(first.ayahId)!.ayah}'), findsOneWidget);
  });
}
