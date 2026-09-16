import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_spacing.dart';

/// A titled card that groups one step of a form.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.children,
    super.key,
    this.icon,
    this.subtitle,
  });

  /// Headline of the section.
  final String title;

  /// Optional line under the title.
  final String? subtitle;

  /// Optional icon in front of the title.
  final IconData? icon;

  /// Content of the section.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = this.icon;
    final subtitle = this.subtitle;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}
