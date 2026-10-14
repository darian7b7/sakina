import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../state.dart';
import 'common.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen(this.state, {super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final lang = state.lang;
    final categories = state.content.categories;
    if (categories.isEmpty) return EmptyState(icon: Icons.category_outlined, text: tr(lang, 'empty.content'));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(tr(lang, 'categories.hint'), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        for (final c in categories)
          CheckboxListTile(
            value: state.categories.contains(c.id),
            onChanged: (_) => state.toggleCategory(c.id),
            title: Text(c.name(lang)),
            subtitle: Text(tr(lang, 'categories.count', {'n': state.content.count(c.id)})),
          ),
      ],
    );
  }
}
