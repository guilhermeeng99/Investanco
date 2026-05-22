import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/domain/repositories/asset_repository.dart';
import 'package:investanco/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:investanco/features/holdings/domain/holding_calculator.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/institutions/domain/repositories/institution_repository.dart';
import 'package:investanco/features/quotes/domain/datasources/index_data_source.dart';
import 'package:investanco/features/quotes/domain/datasources/quote_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/index_point.dart';
import 'package:investanco/features/quotes/domain/market_cache_store.dart';
import 'package:investanco/features/quotes/domain/quote_freshness.dart';
import 'package:investanco/features/quotes/domain/repositories/quote_repository.dart';
import 'package:investanco/features/snapshots/domain/repositories/snapshot_repository.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:investanco/features/valuation/domain/entities/portfolio_valuation.dart';
import 'package:investanco/features/valuation/domain/portfolio_inputs_builder.dart';
import 'package:investanco/features/valuation/domain/valuation_service.dart';

/// Builds the consolidated portfolio from local data, then refreshes quotes/FX
/// in the background. Renders cached data immediately. See
/// `docs/specs/dashboard.md`.
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

  late final StreamSubscription<List<AssetTransaction>> _transactionSub;
  late final StreamSubscription<List<Asset>> _assetSub;
  late final StreamSubscription<List<Institution>> _institutionSub;

  List<AssetTransaction>? _transactions;
  List<Asset>? _assets;
  List<Institution>? _institutions;

  double _fxUsdToBrl = 1;

  /// Whether a real USD→BRL rate has been fetched. Until it has, foreign
  /// holdings are passed a null FX so valuation excludes them (with a warning)
  /// instead of consolidating at a bogus 1:1. See `docs/specs/valuation.md`.
  bool _fxLoaded = false;

  /// Index series fetched on refresh, reused by `_recompute` to accrue fixed
  /// income. Keyed by index; each holding filters it from its own purchase date.
  final Map<EconomicIndex, List<IndexPoint>> _indexSeries = {};

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

  /// Seeds FX + index series from the durable cache so the first paint already
  /// consolidates foreign holdings and accrues fixed income from last-known
  /// data — a closed-then-reopened app shows the previous values instead of a
  /// wrong total until the network responds. See `docs/specs/quotes.md`.
  Future<void> _warmStart() async {
    final fx = await _marketCacheStore.lastFxRate(Currency.usd, Currency.brl);
    if (fx != null) {
      _fxUsdToBrl = fx;
      _fxLoaded = true;
    }
    _indexSeries.addAll(await _marketCacheStore.allIndexSeries());
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

    final holdings = _calculator.derive(transactions);
    final heldIds = _inputsBuilder.heldAssetIds(holdings, assets, transactions);
    final heldAssets = assets.where((a) => heldIds.contains(a.id)).toList();

    if (!force && await _quotesAreFresh(heldIds)) return;

    _refreshing = true;
    await _recompute();
    try {
      await _quoteRepository.refresh(heldAssets);
      await _refreshIndices(heldAssets, transactions);
      if (heldAssets.any((a) => a.currency != Currency.brl)) {
        final fx = await _fxDataSource.rate(Currency.usd, Currency.brl);
        await fx.fold((_) async {}, (rate) async {
          _fxUsdToBrl = rate;
          _fxLoaded = true;
          await _marketCacheStore.saveFxRate(Currency.usd, Currency.brl, rate);
        });
      }
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

  /// True when the held assets' newest cached quote is within [quoteFreshness]
  /// (or nothing is held). Lets the second portfolio screen skip a refresh the
  /// first one just did; the freshness signal is shared via `quotes.fetchedAt`.
  Future<bool> _quotesAreFresh(Set<String> heldIds) async {
    if (heldIds.isEmpty) return true;
    final last = await _quoteRepository.lastFetchedAt(heldIds.toList());
    return last != null && DateTime.now().difference(last) < quoteFreshness;
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

  /// Prices the held positions from the local quote cache (no network), returning
  /// the valuation and an id→asset lookup for the UI.
  Future<
      ({
        PortfolioValuation portfolio,
        Map<String, Asset> assetsById,
        bool hasOpenPosition,
      })> _priceFromCache(
    List<AssetTransaction> transactions,
    List<Asset> assets,
  ) async {
    final assetsById = {for (final a in assets) a.id: a};
    final holdings = _calculator.derive(transactions);
    final cached = await _quoteRepository.getCached(
      holdings.map((h) => h.assetId).toList(),
    );
    final quotes = cached.getOrElse(() => const []);
    final quotesById = {for (final q in quotes) q.assetId: q};
    final inputs = _inputsBuilder.build(
      holdings: holdings,
      assetsById: assetsById,
      transactions: transactions,
      quotesById: quotesById,
      indexSeries: _indexSeries,
      fxUsdToBrl: _fxLoaded ? _fxUsdToBrl : null,
    );
    final portfolio = _valuationService.valuatePortfolio(
      inputs,
      now: DateTime.now(),
    );
    return (
      portfolio: portfolio,
      assetsById: assetsById,
      hasOpenPosition: holdings.any((h) => h.quantity > 0),
    );
  }

  Future<void> _recompute() async {
    final transactions = _transactions;
    final assets = _assets;
    final institutions = _institutions;
    if (transactions == null || assets == null || institutions == null) return;

    final priced = await _priceFromCache(transactions, assets);
    final portfolio = priced.portfolio;
    final assetsById = priced.assetsById;

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
        assetsById: assetsById,
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

  /// Fetches the index series each held fixed-income asset needs, from the
  /// earliest purchase across positions using that index. Failures are ignored
  /// (the holding shows cost until a series arrives).
  Future<void> _refreshIndices(
    List<Asset> heldAssets,
    List<AssetTransaction> transactions,
  ) async {
    final earliestByIndex =
        _inputsBuilder.earliestIndexDates(heldAssets, transactions);
    for (final entry in earliestByIndex.entries) {
      final result = await _indexDataSource.series(entry.key, entry.value);
      await result.fold((_) async {}, (points) async {
        _indexSeries[entry.key] = points;
        await _marketCacheStore.saveIndexSeries(entry.key, points);
      });
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
