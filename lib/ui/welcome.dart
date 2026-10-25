// First start only: what Sakina is for, and the one choice that matters (reminders on or not).
import 'package:family_ui/family_ui.dart';
import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../state.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen(this.state, {super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final lang = state.lang;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            PopIn(child: AppWordmark(FamilyApps.sakina, style: theme.textTheme.headlineMedium)),
            const SizedBox(height: 12),
            PopIn(
              delay: const Duration(milliseconds: 100),
              child: Text(tr(lang, 'welcome.title'), style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 32),
            for (final (i, (icon, key)) in const [
              (Icons.favorite_outline, 'welcome.feel'),
              (Icons.notifications_none, 'welcome.remind'),
              (Icons.bookmark_outline, 'welcome.keep'),
            ].indexed)
              PopIn(
                delay: Duration(milliseconds: 200 + 100 * i),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(icon, color: theme.colorScheme.primary),
                    const SizedBox(width: 16),
                    Expanded(child: Text(tr(lang, key), style: theme.textTheme.bodyLarge?.copyWith(height: 1.4))),
                  ]),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                // The messenger outlives this screen, which is replaced once the welcome ends.
                final messenger = ScaffoldMessenger.of(context);
                if (!await state.finishWelcome(reminders: true)) {
                  messenger.showSnackBar(SnackBar(content: Text(tr(lang, 'reminders.denied'))));
                }
              },
              child: Text(tr(lang, 'welcome.on')),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: state.finishWelcome, child: Text(tr(lang, 'welcome.later'))),
          ],
        ),
      ),
    );
  }
}
