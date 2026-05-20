import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/presentation/asset_labels.dart';
import 'package:investanco/features/assets/presentation/asset_visuals.dart';
import 'package:investanco/features/assets/presentation/cubit/assets_cubit.dart';
import 'package:investanco/features/assets/presentation/cubit/assets_state.dart';
import 'package:investanco/features/assets/presentation/widgets/asset_form_sheet.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

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
        title: Text(asset.ticker),
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
      appBar: InvestancoAppBar(
        title: t.assets.title,
        actions: [
          IconButton(
            tooltip: t.assets.add,
            onPressed: () => AssetFormSheet.show(context, cubit),
            icon: const FaIcon(FontAwesomeIcons.plus, size: 18),
          ),
        ],
      ),
      body: BlocBuilder<AssetsCubit, AssetsState>(
        builder: (context, state) {
          return switch (state) {
            AssetsLoading() => const LoadingShimmerList(),
            AssetsError() => ErrorView(
                message: t.assets.saveError,
                onRetry: () {},
              ),
            AssetsLoaded(:final assets) when assets.isEmpty => EmptyState(
                icon: FontAwesomeIcons.coins,
                title: t.assets.title,
                message: t.assets.empty,
                actionLabel: t.assets.add,
                onAction: () => AssetFormSheet.show(context, cubit),
              ),
            AssetsLoaded(:final assets) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: assets.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _AssetTile(
                  asset: assets[index],
                  onTap: () =>
                      AssetFormSheet.show(context, cubit, existing: assets[index]),
                  onDelete: () => _confirmDelete(context, cubit, assets[index]),
                ),
              ),
          };
        },
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({
    required this.asset,
    required this.onTap,
    required this.onDelete,
  });

  final Asset asset;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InvestancoCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          BrandAvatar(
            background: assetKindColor(asset.kind),
            initials: _initials(asset.ticker),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(asset.ticker, style: context.textTheme.titleSmall),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        asset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.onBackgroundLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    _Tag(assetKindLabel(asset.kind), assetKindColor(asset.kind)),
                    _Tag(asset.currency.code, colors.neutral),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: t.common.delete,
            icon: FaIcon(
              FontAwesomeIcons.trashCan,
              size: 16,
              color: colors.onBackgroundLight,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  String _initials(String ticker) {
    final clean = ticker.trim().toUpperCase();
    return clean.length <= 4 ? clean : clean.substring(0, 4);
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
