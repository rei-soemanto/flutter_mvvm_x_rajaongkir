import 'package:flutter/material.dart';

/// A labelled dropdown whose value is owned by the caller.
///
/// `DropdownButtonFormField` keeps its selection in form state and does not
/// re-read `initialValue` when it rebuilds, so a cascade reset in a view model
/// would leave a stale name on screen. This widget is fully controlled: what
/// the view model holds is what is displayed.
class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    super.key,
    this.hint,
    this.enabled = true,
    this.errorText,
  });

  /// Field label.
  final String label;

  /// Currently selected item, or null when nothing is selected.
  final T? value;

  /// Items to choose from.
  final List<T> items;

  /// Builds the text shown for an item.
  final String Function(T item) itemLabel;

  /// Called with the newly selected item.
  final ValueChanged<T?>? onChanged;

  /// Placeholder shown while nothing is selected.
  final String? hint;

  /// Whether the field accepts input.
  final bool enabled;

  /// Validation or loading message shown under the field.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onChanged = this.onChanged;
    final hint = this.hint;
    final isEnabled = enabled && items.isNotEmpty && onChanged != null;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        enabled: isEnabled,
      ),
      isEmpty: value == null,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: hint == null
              ? null
              : Text(
                  hint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
          items: [
            for (final item in items)
              DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemLabel(item),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
          ],
          onChanged: isEnabled ? onChanged : null,
        ),
      ),
    );
  }
}
