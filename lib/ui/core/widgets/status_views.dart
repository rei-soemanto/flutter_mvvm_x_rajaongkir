import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_spacing.dart';

/// Shown while a request is running.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  /// Optional line under the spinner.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xlg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shown when a request failed, with an optional retry button.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.message, super.key, this.onRetry});

  /// Sentence explaining what went wrong.
  final String message;

  /// Called when the user asks to try again.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onRetry = this.onRetry;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xlg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: AppSpacing.xxlg,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shown when there is nothing to display yet.
class EmptyView extends StatelessWidget {
  const EmptyView({required this.message, super.key, this.icon, this.title});

  /// Sentence describing what is missing.
  final String message;

  /// Optional illustration icon.
  final IconData? icon;

  /// Optional headline above [message].
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = this.icon;
    final title = this.title;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xlg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: AppSpacing.xxlg,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (title != null) ...[
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
