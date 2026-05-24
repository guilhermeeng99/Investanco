import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/domain/repositories/asset_repository.dart';
import 'package:investanco/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:investanco/features/holdings/domain/holding_calculator.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/institutions/domain/repositories/institution_repository.dart';
import 'package:investanco/features/quotes/domain/datasources/index_data_source.dart';
import 'package:investanco/features/quotes/domain/datasources/quote_data_source.dart';
import 'package:investanco/features/quotes/domain/market_cache_store.dart';
import 'package:investanco/features/quotes/domain/repositories/quote_repository.dart';
import 'package:investanco/features/snapshots/domain/repositories/snapshot_repository.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:investanco/features/valuation/domain/portfolio_inputs_builder.dart';
import 'package:investanco/features/valuation/domain/valuation_service.dart';
import 'package:investanco/features/valuation/presentation/portfolio_pricing_engine.dart';

/// Builds the consolidated portfolio from local data, then refreshes quotes/FX
/// in the background. Renders cached data immediately. The shared pricing/refresh
/// logic lives in [PortfolioPricingEngine]; this cubit owns the dashboard's data
/// streams, institution filter and daily snapshot. See `docs/specs/dashboard.md`.
class DashboardCubit extends Cubit<DashboardState> {
  /// Subscribes to the local data streams on creation.
  DashboardCubit(
    this._transactionRepository,
    this._assetRepository,
    this._institutionRepository,
    this._calculator,
    this._quoteRepository,
    this._fxDataSource,
    this._valuationService,
    this._snapshotRepository,
    this._indexDataSource,
    this._marketCacheStore, [
    this._inputsBuilder = const PortfolioInputsBuilder(),
  ]) : super(const DashboardLoading()) {
    _engine = PortfolioPricingEngine(
      _quoteRepository,
      _fxDataSource,
      _valuationService,
      _indexDataSource,
      _marketCacheStore,
      _calculator,
      _inputsBuilder,
    );
    unawaited(_warmStart());
    _transactionSub = _transactionRepository.watchAll().listen(
      (value) {
        _transactions = value;
        unawaited(_recompute());
      },
      onError: _onError,
    );
    _assetSub = _assetRepository.watchAll().listen(
      (value) {
        _assets = value;
        unawaited(_recompute());
      },
      onError: _onError,
    );
    _institutionSub = _institutionRepository.watchAll().listen(
      (value) {
        _institutions = value;
        unawaited(_recompute());
      },
      onError: _onError,
    );
  }

  final TransactionRepository _transactionRepository;
  final AssetRepository _assetRepository;
  final InstitutionRepository _institutionRepository;
  final HoldingCalculator _calculator;
  final QuoteRepository _quoteRepository;
  final FxDataSource _fxDataSource;
  final ValuationService _valuationService;
  final SnapshotRepository _snapshotRepository;
  final IndexDataSource _indexDataSource;
  final MarketCacheStore _marketCacheStore;
  final PortfolioInputsBuilder _inputsBuilder;

  late final PortfolioPricingEngine _engine;

  late final StreamSubscription<List<AssetTransaction>> _transactionSub;
  late final StreamSubscription<List<Asset>> _assetSub;
  late final StreamSubscription<List<Institution>> _institutionSub;

  List<AssetTransaction>? _transactions;
  List<Asset>? _assets;
  List<Institution>? _institutions;

  DateTime? _lastSyncAt;
  bool _refreshing = false;
  bool _autoRefreshed = false;

  /// Selected institution id, or null for all. Drives the dashboard's global
  /// filter; the underlying portfolio is always computed in full.
  String? _institutionFilter;

  /// Filters the whole dashboard (totals, allocation, positions) to one
  /// institution, or all when null. Re-emits without recomputing — the full
  /// portfolio is already in state.
  void setInstitutionFilter(String? institutionId) {
    if (_institutionFilter == institutionId) return;
    _institutionFilter = institutionId;
    final current = state;
    if (current is DashboardLoaded) {
      emit(_withFilter(current, institutionId));
    }
  }

  DashboardLoaded _withFilter(DashboardLoaded state, String? institutionId) {
    return DashboardLoaded(
      portfolio: state.portfolio,
      assetsById: state.assetsById,
      institutionsById: state.institutionsById,
      isRefreshing: state.isRefreshing,
      snapshots: state.snapshots,
      lastSyncAt: state.lastSyncAt,
      institutionFilter: institutionId,
    );
  }

  Future<void> _warmStart() async {
    await _engine.warmStart();
    await _recompute();
  }

  /// Fetches fresh quotes, FX and indices, persists them, then recomputes.
  /// Skips the network when the cached quotes are still fresh, unless [force]
  /// (manual refresh / pull-to-refresh), so opening the second portfolio screen
  /// right after the first refreshed does not re-fetch.
  Future<void> refresh({bool force = false}) async {
    final assets = _assets;
    final transactions = _transactions;
    if (assets == null || transactions == null) return;

    final held = _engine.heldPositions(transactions, assets);
    if (!force && await _engine.quotesAreFresh(held.ids)) return;

    _refreshing = true;
    await _recompute();
    try {
      await _engine.refreshNetwork(held.assets, transactions);
      _lastSyncAt = DateTime.now();
    } on Object catch (_) {
      // Best-effort: a network/persist failure keeps the cached values on
      // screen and must never leave the refresh indicator spinning forever.
    } finally {
      _refreshing = false;
      await _recompute();
    }
    await _writeSnapshot();
  }

  Future<void> _writeSnapshot() async {
    final current = state;
    if (current is! DashboardLoaded || !current.hasHoldings) return;
    final fresh = current.portfolio.holdings
        .any((h) => h.quantity > 0 && !h.priceStale);
    if (!fresh) return;

    await _snapshotRepository.upsertToday(
      totalValue: current.portfolio.totalValueBase,
      totalInvested: current.portfolio.totalInvestedBase,
      totalPL: current.portfolio.totalUnrealizedPL,
    );
    await _recompute();
  }

  Future<void> _recompute() async {
    final transactions = _transactions;
    final assets = _assets;
    final institutions = _institutions;
    if (transactions == null || assets == null || institutions == null) return;

    final priced = await _engine.priceFromCache(transactions, assets);
    final portfolio = priced.portfolio;

    final snapshotsResult = await _snapshotRepository.range(
      DateTime.now().subtract(const Duration(days: 365)),
      DateTime.now(),
    );
    final snapshots = snapshotsResult.getOrElse(() => const []);

    // Drop a dangling filter so a deleted institution (or one whose positions
    // were all closed) can't strand the view on an empty result.
    final filteredValue = portfolio.byInstitution[_institutionFilter];
    if (_institutionFilter != null &&
        (filteredValue == null || filteredValue.minorUnits <= 0)) {
      _institutionFilter = null;
    }

    emit(
      DashboardLoaded(
        portfolio: portfolio,
        assetsById: priced.assetsById,
        institutionsById: {for (final i in institutions) i.id: i},
        lastSyncAt: _lastSyncAt,
        isRefreshing: _refreshing,
        snapshots: snapshots,
        institutionFilter: _institutionFilter,
      ),
    );

    if (!_autoRefreshed && priced.hasOpenPosition) {
      _autoRefreshed = true;
      unawaited(refresh());
    }
  }

  void _onError(Object _, StackTrace _) => emit(const DashboardError());

  @override
  Future<void> close() async {
    await _transactionSub.cancel();
    await _assetSub.cancel();
    await _institutionSub.cancel();
    return super.close();
  }
}
