// Small pieces shared by the screens.
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/content.dart';
import '../core/strings.dart';

/// "07:30"
String hhmm(int minutesOfDay) =>
    '${(minutesOfDay ~/ 60).toString().padLeft(2, '0')}:${(minutesOfDay % 60).toString().padLeft(2, '0')}';

String reference(Ayah ayah, String lang) => tr(lang, 'reference', {'s': ayah.surah, 'a': ayah.ayah});

void shareAyah(Ayah ayah, String lang) {
  final translation = ayah.translation(lang);
  SharePlus.instance.share(ShareParams(
    text: [ayah.arabic, ?translation, '— ${reference(ayah, lang)}'].join('\n\n'),
  ));
}

/// A verse: reference, Arabic text (right to left) and the translation.
class AyahCard extends StatelessWidget {
  const AyahCard(this.ayah, {super.key, required this.lang, required this.arabicScale, this.compact = false, this.onTap});

  final Ayah ayah;
  final String lang;
  final double arabicScale;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final translation = ayah.translation(lang);
    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                reference(ayah, lang),
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                textAlign: compact ? TextAlign.start : TextAlign.center,
              ),
              SizedBox(height: compact ? 8 : 20),
              Text(
                ayah.arabic,
                textDirection: TextDirection.rtl,
                textAlign: compact ? TextAlign.right : TextAlign.center,
                maxLines: compact ? 3 : null,
                overflow: compact ? TextOverflow.ellipsis : null,
                style: TextStyle(fontSize: (compact ? 20 : 28) * arabicScale, height: 1.9, color: theme.colorScheme.onSurface),
              ),
              if (translation != null) ...[
                SizedBox(height: compact ? 8 : 20),
                if (!compact) Divider(color: theme.colorScheme.outlineVariant),
                if (!compact) const SizedBox(height: 12),
                Text(
                  translation,
                  maxLines: compact ? 3 : null,
                  overflow: compact ? TextOverflow.ellipsis : null,
                  style: (compact ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge)?.copyWith(height: 1.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Centered icon + message (+ optional button) for empty screens.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text, this.action, this.onAction});

  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (action != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}
