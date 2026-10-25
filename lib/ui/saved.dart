import 'package:family_ui/family_ui.dart';
import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../state.dart';
import 'common.dart';

/// Saved verses, and the verses your reminders brought.
class SavedScreen extends StatefulWidget {
  const SavedScreen(this.state, {super.key});

  final AppState state;

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  bool _received = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final lang = state.lang;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(tr(lang, 'saved.mine')), icon: const Icon(Icons.bookmark_outline)),
                ButtonSegment(value: true, label: Text(tr(lang, 'saved.received')), icon: const Icon(Icons.notifications_none)),
              ],
              selected: {_received},
              onSelectionChanged: (s) => setState(() => _received = s.first),
            ),
          ),
        ),
        Expanded(child: _received ? _Received(state) : _Saved(state)),
      ],
    );
  }
}

class _Saved extends StatelessWidget {
  const _Saved(this.state);

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final lang = state.lang;
    final ayat = [for (final id in state.saved) ?state.content.byId(id)];
    if (ayat.isEmpty) return EmptyState(icon: Icons.bookmark_outline, text: tr(lang, 'empty.saved'));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: ayat.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final ayah = ayat[i];
        return Dismissible(
          key: ValueKey(ayah.id),
          onDismissed: (_) {
            final undo = state.toggleSaved(ayah.id);
            showUndo(context, lang: lang, message: tr(lang, 'removed'), onUndo: undo);
          },
          child: AyahCard(ayah, lang: lang, arabicScale: state.arabicScale, compact: true, onTap: () => state.open(ayah.id)),
        );
      },
    );
  }
}

class _Received extends StatelessWidget {
  const _Received(this.state);

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final lang = state.lang;
    final items = [
      for (final r in state.received)
        if (state.content.byId(r.ayahId) case final ayah?) (DateTime.fromMillisecondsSinceEpoch(r.time), ayah),
    ];
    if (items.isEmpty) return EmptyState(icon: Icons.notifications_none, text: tr(lang, 'empty.received'));

    final muted = Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final (t, ayah) = items[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: Text('${weekdayNames(lang)[t.weekday - 1]} ${lang == 'de' ? '${t.day}.${t.month}.' : '${t.day}/${t.month}'} · ${hhmm(t.hour * 60 + t.minute)}', style: muted),
            ),
            AyahCard(ayah, lang: lang, arabicScale: state.arabicScale, compact: true, onTap: () => state.open(ayah.id)),
          ]),
        );
      },
    );
  }
}
