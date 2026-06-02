import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/format/currency_formatter.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/allocation/domain/asset_allocation.dart';
import 'package:investanco/features/allocation/domain/entities/investment_overview.dart';
import 'package:investanco/features/allocation/presentation/allocation_visuals.dart';
import 'package:investanco/features/allocation/presentation/cubit/allocation_cubit.dart';
import 'package:investanco/features/allocation/presentation/cubit/allocation_state.dart';
import 'package:investanco/features/allocation/presentation/widgets/asset_class_form_sheet.dart';
import 'package:investanco/features/assets/presentation/cubit/assets_cubit.dart';
import 'package:investanco/features/assets/presentation/widgets/asset_form_sheet.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Detail of one class: target progress + the assets in it (each with a target
/// share + suggested aporte). Lives inside the shell so the nav stays visible.
/// See `docs/specs/allocation.md`.
class AssetClassDetailPage extends StatelessWidget {
  /// Creates the page for [classId].
  const AssetClassDetailPage({required this.classId, super.key});

  /// The class id this page shows.
  final String classId;

  /// Route path (a child of the Investimentos branch; receives the id via `extra`).
  static const String routePath = 'class';

  /// Full path used to navigate.
  static const String fullPath = '/allocation/class';

  /// Route name.
  static const String routeName = 'allocationClass';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AllocationCubit>(
      create: (_) => sl<AllocationCubit>(),
      child: _DetailView(classId: classId),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AllocationCubit, AllocationState>(
      listenWhen: (_, current) =>
          current is AllocationLoaded && current.classById(classId) == null,
      listener: (context, state) {
        if (context.canPop()) context.pop();
      },
      builder: (context, state) {
        final cubit = context.read<AllocationCubit>();
        final entity = state is AllocationLoaded
            ? state.classById(classId)
            : null;
        final slice = state is AllocationLoaded
            ? state.sliceById(classId)
            : null;
        return Scaffold(
          appBar: InvestancoAppBar(
            title: entity?.name ?? t.allocation.classDetailTitle,
            showBack: true,
            actions: [
              if (state is AllocationLoaded && entity != null)
                _AppBarChip(
                  icon: FontAwesomeIcons.penToSquare,
                  onTap: () => unawaited(
                    AssetClassFormSheet.show(
                      context,
                      cubit,
                      classes: state.classes,
                      existing: entity,
                    ),
                  ),
                ),
            ],
          ),
          body: switch (state) {
            AllocationLoading() => const LoadingShimmerList(itemHeight: 96),
            AllocationError() => ErrorView(
              message: t.allocation.loadError,
              onRetry: cubit.refresh,
            ),
            AllocationLoaded() =>
              slice == null
                  ? const SizedBox.shrink()
                  : _Loaded(state: state, slice: slice),
          },
        );
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state, required this.slice});

  final AllocationLoaded state;
  final InvestmentClassSlice slice;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _HeroCard(slice: slice),
        const SizedBox(height: 16),
        InvestancoSectionHeader(title: t.allocation.detailAssets),
        if (slice.subclasses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              t.allocation.detailNoAssets,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.appColors.onBackgroundLight,
              ),
            ),
          )
        else
          for (final sub in slice.subclasses) ...[
            _AssetRow(
              sub: sub,
              tint: Color(slice.colorValue),
              onTap: () => _editAsset(context, sub.id),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 8),
        InvestancoButton(
          label: t.allocation.addAsset,
          onPressed: () => unawaited(
            AssetFormSheet.show(
              context,
              sl<AssetsCubit>(),
              presetAllocationClassId: slice.id,
            ),
          ),
        ),
      ],
    );
  }

  void _editAsset(BuildContext context, String assetId) {
    final asset = state.assetById(assetId);
    if (asset == null) return;
    unawaited(
      AssetFormSheet.show(context, sl<AssetsCubit>(), existing: asset),
    );
  }
}

/// A soft circular app-bar action chip, matching the back chip.
class _AppBarChip extends StatelessWidget {
  const _AppBarChip({required this.icon, required this.onTap});

  final FaIconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Material(
          color: colors.surfaceVariant,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: FaIcon(icon, size: 14, color: colors.onBackground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.slice});

  final InvestmentClassSlice slice;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tint = Color(slice.colorValue);
    final actual = (slice.currentPercent * 100).toStringAsFixed(0);
    final target = slice.targetPercent.toStringAsFixed(0);
    final deltaMinor = slice.deltaValue.minorUnits;
    final onTarget = deltaMinor.abs() < kRebalanceThresholdMinor;
    final deltaColor = onTarget
        ? colors.positive
        : (slice.isUnderTarget ? colors.warning : colors.negative);
    final deltaLabel = onTarget
        ? t.allocation.classRowOnTarget
        : (slice.isUnderTarget
              ? t.allocation.classRowUnderTarget(
                  amount: formatCurrency(
                    Money(deltaMinor.abs(), slice.deltaValue.currency),
                  ),
                )
              : t.allocation.classRowOverTarget(
                  amount: formatCurrency(
                    Money(deltaMinor.abs(), slice.deltaValue.currency),
                  ),
                ));

    final targetFraction = slice.targetPercent / 100;
    final progress = targetFraction <= 0
        ? slice.currentPercent.clamp(0.0, 1.0)
        : (slice.currentPercent / targetFraction).clamp(0.0, 1.0);

    return InvestancoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: FaIcon(
                    allocationIcon(slice.iconKey),
                    size: 20,
                    color: tint,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatCurrency(slice.currentValue),
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    t.allocation.classRowSubtitle(
                      actual: '$actual%',
                      target: '$target%',
                    ),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.onBackgroundLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(tint),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.allocation.detailTargetAmount(
                  amount: formatCurrency(slice.targetValue),
                ),
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onBackgroundLight,
                ),
              ),
              Text(
                deltaLabel,
                style: context.textTheme.bodySmall?.copyWith(
                  color: deltaColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({required this.sub, required this.tint, required this.onTap});

  final InvestmentSubclassSlice sub;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final actual = (sub.percentOfClass * 100).toStringAsFixed(0);
    final target = sub.targetPercent.toStringAsFixed(0);
    final hasTarget = sub.targetPercent > 0;
    final deltaMinor = sub.suggestedDelta.minorUnits;
    final isBelow = hasTarget && deltaMinor >= kRebalanceThresholdMinor;
    final isAbove = hasTarget && deltaMinor <= -kRebalanceThresholdMinor;
    final deltaAmount = _formatSuggestionAmount(sub);
    final suggestionColor = !hasTarget
        ? colors.onBackgroundLight
        : isBelow
        ? colors.warning
        : (isAbove ? colors.negative : colors.positive);
    final suggestionLabel = !hasTarget
        ? t.allocation.subclassSuggestionNoTarget
        : isBelow
        ? t.allocation.subclassSuggestionAdd(amount: deltaAmount)
        : (isAbove
              ? t.allocation.subclassSuggestionTrim(amount: deltaAmount)
              : t.allocation.subclassSuggestionBalanced);

    return InvestancoCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(width: 4, height: 44, color: tint.withValues(alpha: 0.55)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasTarget
                      ? t.allocation.subclassDetailLineTarget(
                          amount: formatCurrency(sub.currentValue),
                          actual: '$actual%',
                          target: '$target%',
                        )
                      : t.allocation.subclassDetailLine(
                          amount: formatCurrency(sub.currentValue),
                          percent: '$actual%',
                        ),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onBackgroundLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  suggestionLabel,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: suggestionColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          FaIcon(
            FontAwesomeIcons.chevronRight,
            size: 11,
            color: colors.onBackgroundLight,
          ),
        ],
      ),
    );
  }

  String _formatSuggestionAmount(InvestmentSubclassSlice sub) {
    final baseAmount = Money(
      sub.suggestedDelta.minorUnits.abs(),
      sub.suggestedDelta.currency,
    );
    final nativeDelta = sub.suggestedDeltaNative;
    if (nativeDelta == null) return formatCurrency(baseAmount);
    final nativeAmount = Money(
      nativeDelta.minorUnits.abs(),
      nativeDelta.currency,
    );
    return '${formatCurrency(baseAmount)} (${formatCurrency(nativeAmount)})';
  }
}
