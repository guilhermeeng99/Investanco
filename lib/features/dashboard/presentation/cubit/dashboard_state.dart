import 'package:equatable/equatable.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/valuation/domain/entities/portfolio_valuation.dart';

/// State for the dashboard. See `docs/specs/dashboard.md`.
sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// Loading the first snapshot from cache.
class DashboardLoading extends DashboardState {
  /// Creates the loading state.
  const DashboardLoading();
}

/// Loaded portfolio (rendered from cache, refreshed in the background).
class DashboardLoaded extends DashboardState {
  /// Creates the loaded state.
  const DashboardLoaded({
    required this.portfolio,
    required this.assetsById,
    required this.institutionsById,
    required this.isRefreshing,
    this.lastSyncAt,
  });

  /// The valued portfolio.
  final PortfolioValuation portfolio;

  /// Assets keyed by id (for display).
  final Map<String, Asset> assetsById;

  /// Institutions keyed by id (for display).
  final Map<String, Institution> institutionsById;

  /// When quotes were last refreshed.
  final DateTime? lastSyncAt;

  /// Whether a background refresh is in flight.
  final bool isRefreshing;

  /// Whether there is at least one open position.
  bool get hasHoldings => portfolio.holdings.any((h) => h.quantity > 0);

  @override
  List<Object?> get props =>
      [portfolio, assetsById, institutionsById, lastSyncAt, isRefreshing];
}

/// No data could be loaded at all.
class DashboardError extends DashboardState {
  /// Creates the error state.
  const DashboardError();
}
