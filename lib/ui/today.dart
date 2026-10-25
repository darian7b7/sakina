import 'package:family_ui/family_ui.dart';
import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../state.dart';
import 'common.dart';
import 'settings.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen(this.state, {super.key, required this.onChooseCategories});

  final AppState state;
  final VoidCallback onChooseCategories;

  @override
  Widget build(BuildContext context) {
    final lang = state.lang;
    if (state.content.ayat.isEmpty) {
      return EmptyState(icon: Icons.menu_book_outlined, text: tr(lang, 'empty.content'));
    }
    final ayah = state.current;
    if (ayah == null && state.mood == null) {
      return EmptyState(
        icon: Icons.category_outlined,
        text: tr(lang, 'empty.selection'),
        action: tr(lang, 'chooseCategories'),
        onAction: onChooseCategories,
      );
    }

    if (ayah == null) return const SizedBox.shrink(); // a mood topic always has verses
    final saved = state.isSaved(ayah.id);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _Feelings(state),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: AyahCard(ayah, key: ValueKey(ayah.id), lang: lang, arabicScale: state.arabicScale),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton.filledTonal(
              tooltip: tr(lang, 'previous'),
              onPressed: state.canGoBack ? state.previous : null,
              icon: const Icon(Icons.chevron_left),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: tr(lang, saved ? 'unsave' : 'save'),
              isSelected: saved,
              onPressed: () => state.toggleSaved(ayah.id),
              icon: const Icon(Icons.bookmark_outline),
              selectedIcon: const Icon(Icons.bookmark),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: tr(lang, 'share'),
              onPressed: () => shareAyah(ayah, lang),
              icon: const Icon(Icons.share_outlined),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: state.next,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right),
              label: Text(tr(lang, 'next')),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _NextReminder(state),
      ],
    );
  }
}

/// "How do you feel?": one tap shows verses for that feeling, a second tap goes back to all verses.
class _Feelings extends StatelessWidget {
  const _Feelings(this.state);

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final lang = state.lang;
    final topics = {for (final c in state.content.categories) c.id};
    final available = [for (final (mood, topic) in moods) if (topics.contains(topic)) (mood, topic)];
    if (available.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Text(tr(lang, 'feel'), style: Theme.of(context).textTheme.titleSmall),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(children: [
            for (final (mood, topic) in available)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(tr(lang, 'mood.$mood')),
                  selected: state.mood == topic,
                  onSelected: (_) => state.feel(topic),
                ),
              ),
          ]),
        ),
      ],
    );
  }
}

/// "Next reminder: today 13:00" — or a link to switch reminders on.
class _NextReminder extends StatelessWidget {
  const _NextReminder(this.state);

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = state.lang;
    final now = DateTime.now();
    final next = state.remindersOn ? state.nextReminder(now.millisecondsSinceEpoch) : null;

    final String text;
    if (next == null) {
      text = tr(lang, state.remindersOn ? 'reminders.none' : 'remindersOff');
    } else {
      final t = DateTime.fromMillisecondsSinceEpoch(next.time);
      final days = DateTime(t.year, t.month, t.day).difference(DateTime(now.year, now.month, now.day)).inDays;
      final day = switch (days) { 0 => tr(lang, 'today'), 1 => tr(lang, 'tomorrow'), _ => weekdayNames(lang)[t.weekday - 1] };
      text = tr(lang, 'nextReminder', {'when': '$day ${hhmm(t.hour * 60 + t.minute)}'});
    }

    return Center(
      child: TextButton.icon(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsScreen(state))),
        icon: Icon(next == null ? Icons.notifications_off_outlined : Icons.notifications_outlined, size: 18),
        label: Text(text),
        style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
