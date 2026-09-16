import 'package:flutter/material.dart';
import 'package:flutter_mvvm_x_rajaongkir/domain/models/shipping_history_entry.dart';
import 'package:flutter_mvvm_x_rajaongkir/routing/app_routes.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/formatters/error_message.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/theme/app_spacing.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/responsive_body.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/core/widgets/status_views.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/history/view_models/history_view_model.dart';
import 'package:flutter_mvvm_x_rajaongkir/ui/history/widgets/history_entry_tile.dart';
import 'package:provider/provider.dart';

/// Page three: every calculation made on the other two pages.
///
/// Entries are saved on the device, so they survive a restart. Swipe one away
/// to delete it, with an undo, or tap it to reopen the full result list.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HistoryViewModel>();
    final entries = viewModel.entries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (viewModel.totalCount > 0)
            IconButton(
              tooltip: 'Clear all',
              onPressed: () => _confirmClear(context, viewModel),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: ResponsiveBody(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: SegmentedButton<HistoryFilter>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: HistoryFilter.all, label: Text('All')),
                  ButtonSegment(
                    value: HistoryFilter.domestic,
                    label: Text('Domestic'),
                  ),
                  ButtonSegment(
                    value: HistoryFilter.international,
                    label: Text('International'),
                  ),
                ],
                selected: {viewModel.filter},
                onSelectionChanged: (selection) =>
                    viewModel.setFilter(selection.first),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: viewModel.load,
                builder: (context, _) {
                  if (viewModel.load.running && entries.isEmpty) {
                    return const LoadingView();
                  }
                  if (viewModel.load.failed && entries.isEmpty) {
                    return ErrorView(
                      message: describeError(viewModel.load.error),
                      onRetry: viewModel.load.execute,
                    );
                  }
                  if (entries.isEmpty) {
                    return EmptyView(
                      icon: Icons.history,
                      title: viewModel.totalCount == 0
                          ? 'Nothing saved yet'
                          : 'Nothing in this filter',
                      message: viewModel.totalCount == 0
                          ? 'Every calculation you make is saved here '
                                'automatically.'
                          : 'Try another filter to see your saved '
                                'calculations.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Dismissible(
                          key: ValueKey(entry.id),
                          direction: DismissDirection.endToStart,
                          background: const _DeleteBackground(),
                          onDismissed: (_) =>
                              _delete(context, viewModel, entry),
                          child: HistoryEntryTile(
                            entry: entry,
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.historyDetail,
                              arguments: entry.id,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    HistoryViewModel viewModel,
    ShippingHistoryEntry entry,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await viewModel.delete(entry.id);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Calculation deleted.'),
        action: error != null
            ? null
            : SnackBarAction(
                label: 'Undo',
                onPressed: () => viewModel.restore(entry),
              ),
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    HistoryViewModel viewModel,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history'),
        content: const Text(
          'This removes every saved calculation from this device. It cannot be '
          'undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final error = await viewModel.clear();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'History cleared.')),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: Icon(
        Icons.delete_outline,
        color: theme.colorScheme.onErrorContainer,
      ),
    );
  }
}
