import 'package:equatable/equatable.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/snapshots/domain/entities/snapshot.dart';
import 'package:investanco/features/valuation/domain/entities/portfolio_valuation.dart';

/// The next entity the user must add before the portfolio can show anything —
/// drives the onboarding empty-state call to action. See `docs/specs/dashboard.md`.
enum PortfolioSetupStep {
  /// No institution registered yet.
  institution,

  /// Institutions exist but no asset yet.
  asset,

  /// Institutions and assets exist but no (open) position yet.
  transaction,
}

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
    required this.snapshots,
    this.lastSyncAt,
    this.institutionFilter,
  });

  /// The **full** valued portfolio (every institution). The header, allocation
  /// and positions render [visiblePortfolio], which applies [institutionFilter];
  /// snapshots are always written from this full figure.
  final PortfolioValuation portfolio;

  /// Historical daily snapshots (oldest first). Persisted for cloud sync and
  /// future charting; the dashboard does not currently render an evolution
  /// chart (see `docs/specs/dashboard.md`).
  final List<Snapshot> snapshots;

  /// Assets keyed by id (for display).
  final Map<String, Asset> assetsById;

  /// Institutions keyed by id (for display).
  final Map<String, Institution> institutionsById;

  /// When quotes were last refreshed.
  final DateTime? lastSyncAt;

  /// Whether a background refresh is in flight.
  final bool isRefreshing;

  /// Active institution filter (an institution id), or `null` for all. Affects
  /// only what's shown ([visiblePortfolio]); the full [portfolio] is kept.
  final String? institutionFilter;

  /// The portfolio narrowed to [institutionFilter] (the full one when unset).
  PortfolioValuation get visiblePortfolio =>
      portfolio.forInstitution(institutionFilter);

  /// Institution ids that hold value, biggest first — the filter bar's chips.
  /// Built from the full portfolio so every bank with an open position is
  /// offered; zero-value (fully sold) institutions are excluded.
  List<String> get filterableInstitutionIds {
    final entries = portfolio.byInstitution.entries
        .where((e) => e.value.minorUnits > 0)
        .toList()
      ..sort((a, b) => b.value.minorUnits.compareTo(a.value.minorUnits));
    return [for (final e in entries) e.key];
  }

  /// Whether there is at least one open position **across all institutions**
  /// (drives the onboarding empty state — independent of the filter).
  bool get hasHoldings => portfolio.holdings.any((h) => h.quantity > 0);

  /// Whether the filtered view has any open position (false → "no positions for
  /// this institution", keeping the filter bar so the user can clear it).
  bool get hasVisibleHoldings =>
      visiblePortfolio.holdings.any((h) => h.quantity > 0);

  /// Whether any institution has been registered.
  bool get hasInstitutions => institutionsById.isNotEmpty;

  /// Whether any asset has been registered.
  bool get hasAssets => assetsById.isNotEmpty;

  /// The next onboarding step, so the empty state can point the user at what's
  /// actually missing (institution → asset → transaction) instead of always
  /// suggesting "add institution".
  PortfolioSetupStep get nextSetupStep {
    if (!hasInstitutions) return PortfolioSetupStep.institution;
    if (!hasAssets) return PortfolioSetupStep.asset;
    return PortfolioSetupStep.transaction;
  }

  @override
  List<Object?> get props => [
        portfolio,
        assetsById,
        institutionsById,
        lastSyncAt,
        isRefreshing,
        snapshots,
        institutionFilter,
      ];
}

/// No data could be loaded at all.
class DashboardError extends DashboardState {
  /// Creates the error state.
  const DashboardError();
}
