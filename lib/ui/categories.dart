// The library: every verse in the app, by topic and searchable. The tick chooses the reminder topics.
import 'package:family_ui/family_ui.dart';
import 'package:flutter/material.dart';

import '../core/content.dart';
import '../core/strings.dart';
import '../state.dart';
import 'common.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen(this.state, {super.key});

  final AppState state;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final lang = state.lang;
    final categories = state.content.categories;
    if (categories.isEmpty) return EmptyState(icon: Icons.category_outlined, text: tr(lang, 'empty.content'));

    final results = _query.isEmpty ? null : search(state.content, _query, lang);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: tr(lang, 'search'),
              isDense: true,
            ),
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ),
        if (results == null) ...[
          Hint(tr(lang, 'categories.hint'), padding: const EdgeInsets.fromLTRB(16, 4, 16, 8)),
          for (final c in categories)
            ListTile(
              leading: Checkbox(value: state.categories.contains(c.id), onChanged: (_) => state.toggleCategory(c.id)),
              title: Text(c.name(lang)),
              subtitle: Text(tr(lang, 'categories.count', {'n': state.content.count(c.id)})),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TopicScreen(state, c))),
            ),
        ] else if (results.isEmpty)
          Hint(tr(lang, 'search.none'), padding: const EdgeInsets.all(16))
        else
          for (final ayah in results.take(50))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: AyahCard(ayah, lang: lang, arabicScale: state.arabicScale, compact: true, onTap: () => state.open(ayah.id)),
            ),
      ],
    );
  }
}

/// Verses whose reference ("2:153"), translation or Arabic text contains [query].
List<Ayah> search(Content content, String query, String lang) {
  final q = query.toLowerCase();
  return [
    for (final a in content.ayat)
      if (a.id == q || a.id.startsWith('$q:') || (a.translation(lang)?.toLowerCase().contains(q) ?? false) || a.arabic.contains(query)) a,
  ];
}

/// All verses of one topic. Tapping one opens it on Today.
class TopicScreen extends StatelessWidget {
  const TopicScreen(this.state, this.category, {super.key});

  final AppState state;
  final Category category;

  @override
  Widget build(BuildContext context) {
    final lang = state.lang;
    final ayat = [for (final id in state.content.poolIds({category.id})) state.content.byId(id)!];
    return Scaffold(
      appBar: AppBar(title: Text(category.name(lang))),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: ayat.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => AyahCard(
          ayat[i],
          lang: lang,
          arabicScale: state.arabicScale,
          compact: true,
          onTap: () {
            Navigator.of(context).pop();
            state.open(ayat[i].id);
          },
        ),
      ),
    );
  }
}
