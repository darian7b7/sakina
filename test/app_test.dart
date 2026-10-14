import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/content.dart';
import 'package:sakina/main.dart';
import 'package:sakina/state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'helpers.dart';

Future<AppState> pump(WidgetTester tester, {Content? content}) async {
  SharedPreferences.setMockInitialValues({});
  final state = AppState(content ?? testContent, await SharedPreferences.getInstance(), FakeReminders());
  await state.setLang('de');
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
    await tester.tap(find.text('Gespeichert'));
    await tester.pumpAndSettle();
    expect(find.text('Sure 9, Vers ${state.current!.ayah}'), findsOneWidget);
  });

  testWidgets('categories can be switched off and Today explains what to do', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Kategorien'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kategorie A'));
    await tester.tap(find.text('Kategorie B'));
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
}
