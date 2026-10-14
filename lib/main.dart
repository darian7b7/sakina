import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'core/content.dart';
import 'core/strings.dart';
import 'notifications.dart';
import 'state.dart';
import 'ui/categories.dart';
import 'ui/saved.dart';
import 'ui/settings.dart';
import 'ui/today.dart';

const seedColor = Color(0xFF0F766E); // calm teal

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
  } catch (_) {
    // Unknown zone: times fall back to UTC.
  }

  final Content content;
  try {
    content = Content.fromJson(jsonDecode(await rootBundle.loadString('assets/ayat.json')) as Map<String, dynamic>);
  } on FormatException catch (e) {
    return runApp(_ContentError(e.message));
  }

  final reminders = LocalReminders();
  final state = AppState(content, await SharedPreferences.getInstance(), reminders);
  reminders.onOpen = state.open;
  final launchedWith = await reminders.init();
  if (launchedWith != null) state.open(launchedWith);
  await state.refresh();
  runApp(SakinaApp(state));
}

ThemeData _theme(Brightness brightness) => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
    );

class SakinaApp extends StatefulWidget {
  const SakinaApp(this.state, {super.key});

  final AppState state;

  @override
  State<SakinaApp> createState() => _SakinaAppState();
}

class _SakinaAppState extends State<SakinaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Coming back to the app: show the newest reminder and top up the plan.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) widget.state.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => MaterialApp(
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: state.themeMode,
        locale: Locale(state.lang),
        supportedLocales: [for (final l in languages.keys) Locale(l)],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: HomeShell(state),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell(this.state, {super.key});

  final AppState state;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    widget.state.showToday.addListener(_goToday);
  }

  @override
  void dispose() {
    widget.state.showToday.removeListener(_goToday);
    super.dispose();
  }

  void _goToday() => setState(() => _tab = 0);

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final lang = state.lang;
    final titles = [appName, tr(lang, 'nav.categories'), tr(lang, 'nav.saved')];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        actions: [
          IconButton(
            tooltip: tr(lang, 'settings'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen(state))),
          ),
        ],
      ),
      body: switch (_tab) {
        0 => TodayScreen(state, onChooseCategories: () => setState(() => _tab = 1)),
        1 => CategoriesScreen(state),
        _ => SavedScreen(state),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.auto_stories_outlined), selectedIcon: const Icon(Icons.auto_stories), label: tr(lang, 'nav.today')),
          NavigationDestination(icon: const Icon(Icons.category_outlined), selectedIcon: const Icon(Icons.category), label: tr(lang, 'nav.categories')),
          NavigationDestination(icon: const Icon(Icons.bookmark_outline), selectedIcon: const Icon(Icons.bookmark), label: tr(lang, 'nav.saved')),
        ],
      ),
    );
  }
}

/// Shown instead of the app when assets/ayat.json can't be read, so the mistake is easy to fix.
class _ContentError extends StatelessWidget {
  const _ContentError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final lang = WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'de' ? 'de' : 'en';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 16),
                Text(tr(lang, 'error.content')),
                const SizedBox(height: 8),
                SelectableText(message, style: const TextStyle(fontFamily: 'monospace')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
