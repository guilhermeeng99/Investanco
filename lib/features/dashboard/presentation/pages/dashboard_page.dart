import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:investanco/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:investanco/features/dashboard/presentation/widgets/allocation_chart.dart';
import 'package:investanco/features/dashboard/presentation/widgets/holdings_list.dart';
import 'package:investanco/features/dashboard/presentation/widgets/portfolio_summary_card.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Portfolio home: consolidated value, allocation and positions. See
/// `docs/specs/dashboard.md`.
class DashboardPage extends StatelessWidget {
  /// Creates the page.
  const DashboardPage({super.key});

  /// Route path.
  static const String routePath = '/dashboard';

  /// Route name.
  static const String routeName = 'dashboard';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardCubit>(
      create: (_) => sl<DashboardCubit>(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: InvestancoAppBar(
        title: t.dashboard.title,
        actions: [
          BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
              final refreshing = state is DashboardLoaded && state.isRefreshing;
              return IconButton(
                tooltip: t.dashboard.refresh,
                onPressed: refreshing
                    ? null
                    : () => context.read<DashboardCubit>().refresh(),
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
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          return switch (state) {
            DashboardLoading() => const LoadingShimmerList(itemHeight: 120),
            DashboardError() => ErrorView(
                message: t.dashboard.loadError,
                onRetry: () => context.read<DashboardCubit>().refresh(),
              ),
            DashboardLoaded() => state.hasHoldings
                ? _LoadedView(state: state)
                : _EmptyState(state: state),
          };
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});

  final DashboardLoaded state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final visible = state.visiblePortfolio;
    final anyStale = visible.holdings.any((h) => h.priceStale);
    final showFilter = state.filterableInstitutionIds.length > 1;

    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          if (showFilter) ...[
            _InstitutionFilterBar(state: state),
            const SizedBox(height: 12),
          ],
          PortfolioSummaryCard(portfolio: visible),
          const SizedBox(height: 16),
          AllocationChart(byClass: visible.byClass),
          const SizedBox(height: 12),
          InvestancoSectionHeader(title: t.dashboard.holdings),
          if (state.hasVisibleHoldings)
            HoldingsList(
              holdings: visible.holdings,
              assetsById: state.assetsById,
              institutionsById: state.institutionsById,
            )
          else
            _NoPositions(),
          if (anyStale)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.clock,
                    size: 12,
                    color: colors.onBackgroundLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.dashboard.pricesStale,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.onBackgroundLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontal chips to scope the whole dashboard to one institution ("All" +
/// each institution that holds value). Mirrors the transactions filter.
class _InstitutionFilterBar extends StatelessWidget {
  const _InstitutionFilterBar({required this.state});

  final DashboardLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    final selected = state.institutionFilter;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          InvestancoFilterChip(
            label: t.dashboard.filterAll,
            selected: selected == null,
            onTap: () => cubit.setInstitutionFilter(null),
          ),
          for (final id in state.filterableInstitutionIds) ...[
            const SizedBox(width: 8),
            InvestancoFilterChip(
              label: state.institutionsById[id]?.name ?? id,
              selected: selected == id,
              onTap: () => cubit.setInstitutionFilter(id),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoPositions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          t.dashboard.noPositionsForFilter,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.appColors.onBackgroundLight,
          ),
        ),
      ),
    );
  }
}

/// Onboarding empty state whose CTA targets the next missing step
/// (institution → asset → transaction) rather than always "add institution".
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.state});

  final DashboardLoaded state;

  @override
  Widget build(BuildContext context) {
    return switch (state.nextSetupStep) {
      PortfolioSetupStep.institution => _cta(
          t.dashboard.addFirst,
          () => context.push('/institutions'),
        ),
      PortfolioSetupStep.asset => _cta(
          t.assets.add,
          () => context.go('/assets'),
        ),
      PortfolioSetupStep.transaction => _cta(
          t.transactions.add,
          () => context.go('/transactions'),
        ),
    };
  }

  Widget _cta(String label, VoidCallback onAction) => EmptyState(
        icon: FontAwesomeIcons.seedling,
        title: t.dashboard.emptyTitle,
        message: t.dashboard.empty,
        actionLabel: label,
        onAction: onAction,
      );
}
