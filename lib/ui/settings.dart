import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../state.dart';
import 'common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen(this.state, {super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final lang = state.lang;
        final theme = Theme.of(context);
        final muted = TextStyle(color: theme.colorScheme.onSurfaceVariant);

        void snack(String key) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(tr(lang, key))));

        return Scaffold(
          appBar: AppBar(title: Text(tr(lang, 'settings'))),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _Header(tr(lang, 'reminders')),
              SwitchListTile(
                title: Text(tr(lang, 'reminders.on')),
                value: state.remindersOn,
                onChanged: (on) async {
                  if (!await state.setRemindersOn(on)) snack('reminders.denied');
                },
              ),
              if (kIsWeb) _Note(tr(lang, 'reminders.web')),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: state.remindersOn ? 1 : 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label(tr(lang, 'reminders.times')),
                    _Chips([
                      for (final m in state.times)
                        InputChip(label: Text(hhmm(m)), onDeleted: state.times.length > 1 ? () => state.removeTime(m) : null),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: Text(tr(lang, 'reminders.addTime')),
                        onPressed: () async {
                          final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
                          if (t != null) state.addTime(t.hour * 60 + t.minute);
                        },
                      ),
                    ]),
                    _Label(tr(lang, 'reminders.days')),
                    _Chips([
                      for (final (i, name) in weekdayNames(lang).indexed)
                        FilterChip(
                          label: Text(name),
                          selected: state.weekdays.contains(i + 1),
                          showCheckmark: false,
                          onSelected: (_) => state.toggleWeekday(i + 1),
                        ),
                    ]),
                    _Label(tr(lang, 'reminders.upcoming')),
                    ..._upcoming(state, muted),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(tr(lang, 'reminders.test')),
                onTap: () async {
                  if (!await state.sendTest()) snack('reminders.denied');
                },
              ),
              const Divider(height: 32),
              _Header(tr(lang, 'display')),
              _Label(tr(lang, 'language')),
              _Padded(SegmentedButton<String>(
                segments: [for (final e in languages.entries) ButtonSegment(value: e.key, label: Text(e.value))],
                selected: {lang},
                onSelectionChanged: (s) => state.setLang(s.first),
              )),
              _Label(tr(lang, 'theme')),
              _Padded(SegmentedButton<ThemeMode>(
                segments: [
                  for (final m in ThemeMode.values) ButtonSegment(value: m, label: Text(tr(lang, 'theme.${m.name}'))),
                ],
                selected: {state.themeMode},
                onSelectionChanged: (s) => state.setThemeMode(s.first),
              )),
              _Label(tr(lang, 'arabicSize')),
              Slider(
                value: state.arabicScale,
                min: 0.8,
                max: 1.6,
                divisions: 4,
                onChanged: state.setArabicScale,
              ),
              const Divider(height: 32),
              _Header(tr(lang, 'about')),
              _Note(tr(lang, 'about.text')),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _upcoming(AppState state, TextStyle muted) {
    final lang = state.lang;
    final now = DateTime.now().millisecondsSinceEpoch;
    final next = state.plan.where((p) => p.time > now).take(3).toList();
    if (!state.remindersOn || next.isEmpty) return [_Note(tr(lang, 'reminders.none'))];
    return [
      for (final p in next)
        ListTile(
          dense: true,
          leading: const Icon(Icons.schedule, size: 20),
          title: Text(() {
            final t = DateTime.fromMillisecondsSinceEpoch(p.time);
            return '${weekdayNames(lang)[t.weekday - 1]} ${hhmm(t.hour * 60 + t.minute)}';
          }()),
          trailing: Text(reference(state.content.byId(p.ayahId)!, lang), style: muted),
        ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

class _Chips extends StatelessWidget {
  const _Chips(this.children);
  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      _Padded(Wrap(spacing: 8, runSpacing: 8, children: children));
}

class _Padded extends StatelessWidget {
  const _Padded(this.child);
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);
}
