import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/format/currency_formatter.dart';
import 'package:investanco/features/allocation/domain/entities/asset_class.dart';
import 'package:investanco/features/allocation/presentation/cubit/allocation_cubit.dart';
import 'package:investanco/features/allocation/presentation/cubit/allocation_state.dart';
import 'package:investanco/features/allocation/presentation/pages/asset_class_detail_page.dart';
import 'package:investanco/features/allocation/presentation/widgets/allocation_class_donut.dart';
import 'package:investanco/features/allocation/presentation/widgets/asset_class_form_sheet.dart';
import 'package:investanco/features/allocation/presentation/widgets/investment_class_row.dart';
import 'package:investanco/features/allocation/presentation/widgets/investment_rebalance_row.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Allocation home: target vs current per class, with a rebalancing plan. See
/// `docs/specs/allocation.md`.
class InvestmentsPage extends StatelessWidget {
  /// Creates the page.
  const InvestmentsPage({super.key});

  /// Route path.
  static const String routePath = '/allocation';

  /// Route name.
  static const String routeName = 'allocation';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AllocationCubit>(
      create: (_) => sl<AllocationCubit>(),
      child: const _InvestmentsView(),
    );
  }
}

class _InvestmentsView extends StatelessWidget {
  const _InvestmentsView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AllocationCubit>().state;
    final classes = state is AllocationLoaded ? state.classes : const <AssetClass>[];
    return Scaffold(
      appBar: InvestancoAppBar(
        title: t.nav.allocation,
        actions: [
          BlocBuilder<AllocationCubit, AllocationState>(
            builder: (context, state) {
              final refreshing = state is AllocationLoaded && state.isRefreshing;
              return IconButton(
                tooltip: t.allocation.refresh,
                onPressed: refreshing
                    ? null
                    : () => context.read<AllocationCubit>().refresh(),
                icon: refreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const FaIcon(FontAwesomeIcons.arrowsRotate, size: 18),
              );
            },
          ),
        ],
      ),
      floatingActionButton: state is AllocationLoaded
          ? FloatingActionButton(
              onPressed: () => AssetClassFormSheet.show(
                context,
                context.read<AllocationCubit>(),
                classes: classes,
              ),
              child: const FaIcon(FontAwesomeIcons.plus, size: 18),
            )
          : null,
      body: BlocBuilder<AllocationCubit, AllocationState>(
        builder: (context, state) {
          return switch (state) {
            AllocationLoading() => const LoadingShimmerList(itemHeight: 96),
            AllocationError() => ErrorView(
                message: t.allocation.loadError,
                onRetry: () => context.read<AllocationCubit>().refresh(),
              ),
            AllocationLoaded() => _LoadedView(state: state),
          };
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});

  final AllocationLoaded state;

  @override
  Widget build(BuildContext context) {
    final overview = state.overview;
    final hasClasses = overview.classes.isNotEmpty;

    if (!hasClasses && !overview.hasInvestments) {
      return _EmptyState(cubit: context.read<AllocationCubit>(), classes: state.classes);
    }

    final colors = context.appColors;
    return RefreshIndicator(
      onRefresh: () => context.read<AllocationCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          AllocationClassDonut(overview: overview),
          const SizedBox(height: 12),
          if (hasClasses && !overview.targetsBalanced) ...[
            _TargetsBanner(percent: overview.targetSumPercent),
            const SizedBox(height: 12),
          ],
          InvestancoSectionHeader(title: t.allocation.sectionClasses),
          if (!hasClasses)
            _Hint(text: t.allocation.noClassesHint)
          else
            for (final slice in overview.classes) ...[
              InvestmentClassRow(
                slice: slice,
                onTap: () => context.push(
                  AssetClassDetailPage.fullPath,
                  extra: slice.id,
                ),
              ),
              const SizedBox(height: 8),
            ],
          if (overview.rebalanceActions.isNotEmpty || overview.hasPending) ...[
            const SizedBox(height: 8),
            InvestancoSectionHeader(title: t.allocation.sectionRebalance),
            InvestancoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (overview.hasPending)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        t.allocation.rebalanceAllocatePending(
                          amount: formatCurrency(overview.pending),
                        ),
                        style: context.textTheme.bodyMedium
                            ?.copyWith(color: colors.warning),
                      ),
                    ),
                  for (final action in overview.rebalanceActions)
                    InvestmentRebalanceRow(action: action),
                  if (overview.rebalanceActions.isEmpty && !overview.hasPending)
                    Text(
                      t.allocation.rebalanceBalanced,
                      style: context.textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TargetsBanner extends StatelessWidget {
  const _TargetsBanner({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          FaIcon(FontAwesomeIcons.triangleExclamation,
              size: 13, color: colors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t.allocation.targetsBanner(percent: percent.toStringAsFixed(0)),
              style: context.textTheme.bodySmall?.copyWith(color: colors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.textTheme.bodyMedium
            ?.copyWith(color: context.appColors.onBackgroundLight),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.cubit, required this.classes});

  final AllocationCubit cubit;
  final List<AssetClass> classes;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: FontAwesomeIcons.scaleBalanced,
      title: t.allocation.emptyTitle,
      message: t.allocation.emptyMessage,
      actionLabel: t.allocation.emptyAction,
      onAction: () =>
          AssetClassFormSheet.show(context, cubit, classes: classes),
    );
  }
}
