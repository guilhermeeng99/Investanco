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
import 'package:investanco/features/dashboard/presentation/widgets/evolution_chart.dart';
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
            DashboardLoaded(hasHoldings: false) => const _EmptyState(),
            DashboardLoaded() => _LoadedView(state: state),
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
    final anyStale = state.portfolio.holdings.any((h) => h.priceStale);

    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          PortfolioSummaryCard(portfolio: state.portfolio),
          const SizedBox(height: 16),
          AllocationChart(byClass: state.portfolio.byClass),
          const SizedBox(height: 12),
          EvolutionChart(snapshots: state.snapshots),
          InvestancoSectionHeader(title: t.dashboard.holdings),
          HoldingsList(state: state),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: FontAwesomeIcons.seedling,
      title: t.dashboard.emptyTitle,
      message: t.dashboard.empty,
      actionLabel: t.dashboard.addFirst,
      onAction: () => context.push('/institutions'),
    );
  }
}
