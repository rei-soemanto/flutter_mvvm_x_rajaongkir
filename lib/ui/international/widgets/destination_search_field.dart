import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_radius.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_spacing.dart';

/// A search box with its suggestions underneath.
///
/// This is the direct search method on screen: type a few letters, the view
/// model asks the API after a short pause, and the answers appear as a list.
class DestinationSearchField<T> extends StatelessWidget {
  const DestinationSearchField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onQueryChanged,
    required this.isSearching,
    required this.results,
    required this.itemTitle,
    required this.onSelected,
    super.key,
    this.itemSubtitle,
    this.errorText,
    this.emptyHint,
  });

  /// Field label.
  final String label;

  /// Placeholder inside the field.
  final String hint;

  /// Controls the typed text.
  final TextEditingController controller;

  /// Called on every keystroke.
  final ValueChanged<String> onQueryChanged;

  /// Whether a search is running.
  final bool isSearching;

  /// Suggestions to show.
  final List<T> results;

  /// Builds the main line of a suggestion.
  final String Function(T item) itemTitle;

  /// Builds the secondary line of a suggestion.
  final String Function(T item)? itemSubtitle;

  /// Called when a suggestion is tapped.
  final ValueChanged<T> onSelected;

  /// Search failure, if any.
  final String? errorText;

  /// Line shown when a finished search found nothing.
  final String? emptyHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorText = this.errorText;
    final emptyHint = this.emptyHint;
    final itemSubtitle = this.itemSubtitle;
    final hasQuery = controller.text.trim().length >= 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onQueryChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: isSearching
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: SizedBox(
                      width: AppSpacing.lg,
                      height: AppSpacing.lg,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        if (results.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final item = results[index];
                  return ListTile(
                    title: Text(itemTitle(item)),
                    subtitle: itemSubtitle == null
                        ? null
                        : Text(
                            itemSubtitle(item),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    onTap: () => onSelected(item),
                  );
                },
              ),
            ),
          ),
        ] else if (emptyHint != null && hasQuery && !isSearching) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            emptyHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Shows what was picked, with a button to search again.
class SelectedDestinationTile extends StatelessWidget {
  const SelectedDestinationTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onChange,
    super.key,
  });

  /// Main line.
  final String title;

  /// Secondary line.
  final String subtitle;

  /// Leading icon.
  final IconData icon;

  /// Called when the user wants to pick something else.
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onChange, child: const Text('Change')),
        ],
      ),
    );
  }
}
