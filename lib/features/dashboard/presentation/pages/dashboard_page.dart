import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:investanco/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:investanco/features/dashboard/presentation/widgets/allocation_chart.dart';
import 'package:investanco/features/dashboard/presentation/widgets/evolution_chart.dart';
import 'package:investanco/features/dashboard/presentation/widgets/holdings_list.dart';
import 'package:investanco/features/dashboard/presentation/widgets/portfolio_summary_card.dart';
import 'package:investanco/gen/strings.g.dart';

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
      appBar: AppBar(
        title: Text(t.dashboard.title),
        actions: [
          IconButton(
            tooltip: t.dashboard.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DashboardCubit>().refresh(),
          ),
        ],
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          return switch (state) {
            DashboardLoading() =>
              const Center(child: CircularProgressIndicator()),
            DashboardError() => Center(child: Text(t.dashboard.empty)),
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
    final theme = Theme.of(context);
    final anyStale = state.portfolio.holdings.any((h) => h.priceStale);

    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (state.isRefreshing) const LinearProgressIndicator(),
          PortfolioSummaryCard(portfolio: state.portfolio),
          const SizedBox(height: 8),
          AllocationChart(byClass: state.portfolio.byClass),
          const SizedBox(height: 8),
          EvolutionChart(snapshots: state.snapshots),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(t.dashboard.holdings, style: theme.textTheme.titleMedium),
          ),
          HoldingsList(state: state),
          if (anyStale)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                t.dashboard.pricesStale,
                style: theme.textTheme.bodySmall,
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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              t.dashboard.empty,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
