import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/format/initials.dart';
import 'package:investanco/core/format/number_format.dart';
import 'package:investanco/features/allocation/domain/asset_allocation.dart';
import 'package:investanco/features/allocation/domain/entities/asset_class.dart';
import 'package:investanco/features/allocation/domain/repositories/asset_class_repository.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/presentation/asset_labels.dart';
import 'package:investanco/features/assets/presentation/asset_visuals.dart';
import 'package:investanco/features/assets/presentation/cubit/assets_cubit.dart';
import 'package:investanco/features/assets/presentation/cubit/assets_state.dart';
import 'package:investanco/features/assets/presentation/widgets/asset_form_sheet.dart';
import 'package:investanco/features/portfolio_import/presentation/widgets/assets_csv_import_dialog.dart';
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
  ) =>
      confirmAndRemove(
        context,
        title: asset.ticker,
        message: t.assets.deleteConfirm,
        onConfirm: () => cubit.remove(asset.id),
        inUseError: t.assets.inUseError,
      );

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssetsCubit>();
    return Scaffold(
      appBar: InvestancoAppBar(title: t.assets.title),
      floatingActionButton: ImportAddFab(
        heroPrefix: 'assets',
        addTooltip: t.assets.add,
        importTooltip: t.importAssets.title,
        onAdd: () => AssetFormSheet.show(context, cubit),
        onImport: () => showAssetsCsvImportDialog(context),
      ),
      body: StreamBuilder<List<AssetClass>>(
        stream: sl<AssetClassRepository>().watchAll(),
        builder: (context, snapshot) {
          final classesById = {
            for (final c in snapshot.data ?? const <AssetClass>[]) c.id: c,
          };
          return BlocBuilder<AssetsCubit, AssetsState>(
            builder: (context, state) {
              return switch (state) {
                AssetsLoading() => const LoadingShimmerList(),
                AssetsError() => ErrorView(
                  message: t.assets.saveError,
                ),
                AssetsLoaded(:final assets) when assets.isEmpty => EmptyState(
                  icon: FontAwesomeIcons.coins,
                  title: t.assets.title,
                  message: t.assets.empty,
                  actionLabel: t.assets.add,
                  onAction: () => AssetFormSheet.show(context, cubit),
                ),
                AssetsLoaded(:final assets) => EntityListView(
                  itemCount: assets.length,
                  itemBuilder: (context, index) => _AssetTile(
                    asset: assets[index],
                    assetClass: classesById[allocationClassIdOf(assets[index])],
                    onTap: () => AssetFormSheet.show(
                      context,
                      cubit,
                      existing: assets[index],
                    ),
                    onDelete: () =>
                        _confirmDelete(context, cubit, assets[index]),
                  ),
                ),
              };
            },
          );
        },
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({
    required this.asset,
    required this.assetClass,
    required this.onTap,
    required this.onDelete,
  });

  final Asset asset;

  /// The allocation class this asset is assigned to, or null when unassigned.
  final AssetClass? assetClass;

  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _allocationLabel(AssetClass cls) {
    final target = allocationTargetOf(asset);
    if (target <= 0) return cls.name;
    return '${cls.name} · ${formatTrimmedDouble(target)}%';
  }

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
            initials: tickerInitials(asset.ticker),
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
                  runSpacing: 6,
                  children: [
                    InvestancoChip(
                      label: assetKindLabel(asset.kind),
                      color: assetKindColor(asset.kind),
                    ),
                    InvestancoChip(
                      label: asset.currency.code,
                      color: colors.neutral,
                    ),
                    if (assetClass case final cls?)
                      InvestancoChip(
                        label: _allocationLabel(cls),
                        color: Color(cls.colorValue),
                      )
                    else
                      InvestancoChip(
                        label: t.assets.allocationUnassigned,
                        color: colors.onBackgroundLight,
                      ),
                  ],
                ),
              ],
            ),
          ),
          EntityDeleteButton(onPressed: onDelete),
        ],
      ),
    );
  }
}
