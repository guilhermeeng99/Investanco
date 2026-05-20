import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/presentation/asset_labels.dart';
import 'package:investanco/features/assets/presentation/cubit/assets_cubit.dart';
import 'package:investanco/features/assets/presentation/cubit/assets_state.dart';
import 'package:investanco/features/assets/presentation/widgets/asset_form_sheet.dart';
import 'package:investanco/gen/strings.g.dart';

/// Manage assets (PETR4, AAPL, …). See `docs/specs/assets.md`.
class AssetsPage extends StatelessWidget {
  /// Creates the page.
  const AssetsPage({super.key});

  /// Route path.
  static const String routePath = '/assets';

  /// Route name.
  static const String routeName = 'assets';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AssetsCubit>(
      create: (_) => sl<AssetsCubit>(),
      child: const _AssetsView(),
    );
  }
}

class _AssetsView extends StatelessWidget {
  const _AssetsView();

  Future<void> _confirmDelete(
    BuildContext context,
    AssetsCubit cubit,
    Asset asset,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(t.assets.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final failure = await cubit.remove(asset.id);
    if (failure is InUseFailure && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.assets.inUseError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssetsCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(t.assets.title)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AssetFormSheet.show(context, cubit),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<AssetsCubit, AssetsState>(
        builder: (context, state) {
          return switch (state) {
            AssetsLoading() => const Center(child: CircularProgressIndicator()),
            AssetsError() => Center(child: Text(t.assets.saveError)),
            AssetsLoaded(:final assets) when assets.isEmpty =>
              const _EmptyState(),
            AssetsLoaded(:final assets) => ListView.builder(
                itemCount: assets.length,
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(_initials(asset.ticker))),
                    title: Text('${asset.ticker} · ${asset.name}'),
                    subtitle: Text(
                      '${assetKindLabel(asset.kind)} · '
                      '${marketLabel(asset.market)} · ${asset.currency.code}',
                    ),
                    onTap: () =>
                        AssetFormSheet.show(context, cubit, existing: asset),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, cubit, asset),
                    ),
                  );
                },
              ),
          };
        },
      ),
    );
  }

  String _initials(String ticker) =>
      ticker.isEmpty ? '?' : ticker.substring(0, ticker.length >= 2 ? 2 : 1);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          t.assets.empty,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
