import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/allocation/domain/entities/asset_class.dart';
import 'package:investanco/features/allocation/domain/repositories/asset_class_repository.dart';
import 'package:investanco/features/allocation/domain/services/compute_investment_overview.dart';
import 'package:investanco/features/allocation/domain/usecases/save_asset_class_usecase.dart';
import 'package:investanco/features/allocation/presentation/cubit/allocation_state.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/domain/repositories/asset_repository.dart';
import 'package:investanco/features/holdings/domain/holding_calculator.dart';
import 'package:investanco/features/quotes/domain/datasources/index_data_source.dart';
import 'package:investanco/features/quotes/domain/datasources/quote_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/index_point.dart';
import 'package:investanco/features/quotes/domain/market_cache_store.dart';
import 'package:investanco/features/quotes/domain/quote_freshness.dart';
import 'package:investanco/features/quotes/domain/repositories/quote_repository.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:investanco/features/valuation/domain/portfolio_inputs_builder.dart';
import 'package:investanco/features/valuation/domain/valuation_service.dart';

/// Values the portfolio (like the dashboard) and projects it onto the user's
/// allocation classes/targets, producing the rebalancing overview. See
/// `docs/specs/allocation.md`.
class AllocationCubit extends Cubit<AllocationState> {
  /// Subscribes to the local data streams on creation.
  AllocationCubit(
    this._transactionRepository,
    this._assetRepository,
    this._assetClassRepository,
    this._saveAssetClass,
    this._calculator,
    this._quoteRepository,
    this._fxDataSource,
    this._valuationService,
    this._indexDataSource,
    this._marketCacheStore,
    this._idGenerator, [
    this._inputsBuilder = const PortfolioInputsBuilder(),
  ]) : super(const AllocationLoading()) {
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
    _classSub = _assetClassRepository.watchAll().listen(
      (value) {
        _classes = value;
        unawaited(_recompute());
      },
      onError: _onError,
    );
  }

  final TransactionRepository _transactionRepository;
  final AssetRepository _assetRepository;
  final AssetClassRepository _assetClassRepository;
  final SaveAssetClassUseCase _saveAssetClass;
  final HoldingCalculator _calculator;
  final QuoteRepository _quoteRepository;
  final FxDataSource _fxDataSource;
  final ValuationService _valuationService;
  final IndexDataSource _indexDataSource;
  final MarketCacheStore _marketCacheStore;
  final IdGenerator _idGenerator;
  final PortfolioInputsBuilder _inputsBuilder;

  late final StreamSubscription<List<AssetTransaction>> _transactionSub;
  late final StreamSubscription<List<Asset>> _assetSub;
  late final StreamSubscription<List<AssetClass>> _classSub;

  List<AssetTransaction>? _transactions;
  List<Asset>? _assets;
  List<AssetClass>? _classes;

  double _fxUsdToBrl = 1;
  bool _fxLoaded = false;
  final Map<EconomicIndex, List<IndexPoint>> _indexSeries = {};
  bool _refreshing = false;
  bool _autoRefreshed = false;

  /// Creates a new class/subclass (generates id + timestamp), validated.
  Future<Either<Failure, Unit>> createClass({
    required String name,
    required double targetPercent,
    required String iconKey,
    required int colorValue,
    String? parentId,
  }) {
    return saveClass(
      AssetClass(
        id: _idGenerator.newId(),
        name: name,
        iconKey: iconKey,
        colorValue: colorValue,
        targetPercent: targetPercent,
        parentId: parentId,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Saves (creates/updates) a class or subclass, validated against the current
  /// classes. The classes stream re-emits on success → recompute.
  Future<Either<Failure, Unit>> saveClass(AssetClass assetClass) =>
      _saveAssetClass(assetClass, existing: _classes ?? const []);

  /// Deletes a class. Assets pointing at it become unassigned automatically.
  Future<Either<Failure, Unit>> deleteClass(String id) =>
      _assetClassRepository.delete(id);

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
  /// (manual refresh / pull-to-refresh), so opening this screen right after the
  /// dashboard refreshed does not re-fetch.
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
    } on Object catch (_) {
      // Best-effort: a network/persist failure keeps the cached values on
      // screen and must never leave the refresh indicator spinning forever.
    } finally {
      _refreshing = false;
      await _recompute();
    }
  }

  /// True when the held assets' newest cached quote is within [quoteFreshness]
  /// (or nothing is held). Shares the freshness signal with the dashboard via
  /// `quotes.fetchedAt`, so the two screens don't double-fetch.
  Future<bool> _quotesAreFresh(Set<String> heldIds) async {
    if (heldIds.isEmpty) return true;
    final last = await _quoteRepository.lastFetchedAt(heldIds.toList());
    return last != null && DateTime.now().difference(last) < quoteFreshness;
  }

  Future<void> _recompute() async {
    final transactions = _transactions;
    final assets = _assets;
    final classes = _classes;
    if (transactions == null || assets == null || classes == null) return;

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

    final overview = computeInvestmentOverview(
      classes: classes,
      assets: assets,
      holdings: portfolio.holdings,
      base: portfolio.totalValueBase.currency,
    );

    emit(
      AllocationLoaded(
        overview: overview,
        classes: classes,
        assets: assets,
        isRefreshing: _refreshing,
      ),
    );

    if (!_autoRefreshed && holdings.any((h) => h.quantity > 0)) {
      _autoRefreshed = true;
      unawaited(refresh());
    }
  }

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

  void _onError(Object _, StackTrace _) => emit(const AllocationError());

  @override
  Future<void> close() async {
    await _transactionSub.cancel();
    await _assetSub.cancel();
    await _classSub.cancel();
    return super.close();
  }
}
