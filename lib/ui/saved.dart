import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../state.dart';
import 'common.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen(this.state, {super.key});

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
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(tr(lang, 'removed')),
                action: SnackBarAction(label: tr(lang, 'undo'), onPressed: undo),
              ));
          },
          child: AyahCard(ayah, lang: lang, arabicScale: state.arabicScale, compact: true, onTap: () => state.open(ayah.id)),
        );
      },
    );
  }
}
