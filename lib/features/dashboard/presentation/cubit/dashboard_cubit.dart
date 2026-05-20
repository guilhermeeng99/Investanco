import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/domain/repositories/asset_repository.dart';
import 'package:investanco/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:investanco/features/holdings/domain/entities/holding.dart';
import 'package:investanco/features/holdings/domain/holding_calculator.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/institutions/domain/repositories/institution_repository.dart';
import 'package:investanco/features/quotes/domain/datasources/index_data_source.dart';
import 'package:investanco/features/quotes/domain/datasources/quote_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/index_point.dart';
import 'package:investanco/features/quotes/domain/repositories/quote_repository.dart';
import 'package:investanco/features/snapshots/domain/repositories/snapshot_repository.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:investanco/features/valuation/domain/entities/fixed_income_terms.dart';
import 'package:investanco/features/valuation/domain/fixed_income_metadata.dart';
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
  ) : super(const DashboardLoading()) {
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

  late final StreamSubscription<List<AssetTransaction>> _transactionSub;
  late final StreamSubscription<List<Asset>> _assetSub;
  late final StreamSubscription<List<Institution>> _institutionSub;

  List<AssetTransaction>? _transactions;
  List<Asset>? _assets;
  List<Institution>? _institutions;

  double _fxUsdToBrl = 1;

  /// Index series fetched on refresh, reused by `_recompute` to accrue fixed
  /// income. Keyed by index; each holding filters it from its own purchase date.
  final Map<EconomicIndex, List<IndexPoint>> _indexSeries = {};

  DateTime? _lastSyncAt;
  bool _refreshing = false;
  bool _autoRefreshed = false;

  /// Fetches fresh quotes and FX, then recomputes.
  Future<void> refresh() async {
    final assets = _assets;
    final transactions = _transactions;
    if (assets == null || transactions == null) return;

    _refreshing = true;
    await _recompute();

    final holdings = _calculator.derive(transactions);
    final heldIds = holdings
        .where((h) => h.quantity > 0)
        .map((h) => h.assetId)
        .toSet();
    final heldAssets = assets.where((a) => heldIds.contains(a.id)).toList();

    await _quoteRepository.refresh(heldAssets);
    await _refreshIndices(heldAssets, transactions);
    if (heldAssets.any((a) => a.currency != Currency.brl)) {
      final fx = await _fxDataSource.rate(Currency.usd, Currency.brl);
      fx.fold((_) {}, (rate) => _fxUsdToBrl = rate);
    }

    _lastSyncAt = DateTime.now();
    _refreshing = false;
    await _recompute();
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

    final assetsById = {for (final a in assets) a.id: a};
    final holdings = _calculator.derive(transactions);
    final quotes = await _quoteRepository.getCached(
      holdings.map((h) => h.assetId).toList(),
    );
    final quotesById = {for (final q in quotes) q.assetId: q};
    final earliestBuy = _earliestBuyByHolding(transactions);

    final inputs = [
      for (final holding in holdings)
        if (assetsById[holding.assetId] case final asset?)
          ValuationInput(
            holding: holding,
            asset: asset,
            quote: quotesById[holding.assetId],
            fxToBase: asset.currency == Currency.brl ? 1.0 : _fxUsdToBrl,
            fixedIncome: _termsFor(asset, holding, earliestBuy),
          ),
    ];

    final portfolio = _valuationService.valuatePortfolio(
      inputs,
      now: DateTime.now(),
    );

    final snapshots = await _snapshotRepository.range(
      DateTime.now().subtract(const Duration(days: 365)),
      DateTime.now(),
    );

    emit(
      DashboardLoaded(
        portfolio: portfolio,
        assetsById: assetsById,
        institutionsById: {for (final i in institutions) i.id: i},
        lastSyncAt: _lastSyncAt,
        isRefreshing: _refreshing,
        snapshots: snapshots,
      ),
    );

    if (!_autoRefreshed && holdings.any((h) => h.quantity > 0)) {
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
    final earliestByIndex = <EconomicIndex, DateTime>{};
    for (final asset in heldAssets) {
      final index = _indexFor(asset);
      final purchase = _earliestBuyForAsset(asset.id, transactions);
      if (index == null || purchase == null) continue;
      final current = earliestByIndex[index];
      if (current == null || purchase.isBefore(current)) {
        earliestByIndex[index] = purchase;
      }
    }
    for (final entry in earliestByIndex.entries) {
      final result = await _indexDataSource.series(entry.key, entry.value);
      result.fold((_) {}, (points) => _indexSeries[entry.key] = points);
    }
  }

  /// The BCB index a fixed-income asset accrues against, or null otherwise.
  EconomicIndex? _indexFor(Asset asset) {
    if (asset.kind != AssetKind.fixedIncome) return null;
    return FixedIncomeMetadata.read(asset)?.$1.economicIndex;
  }

  /// Accrual terms for a fixed-income holding, or null when not applicable.
  FixedIncomeTerms? _termsFor(
    Asset asset,
    Holding holding,
    Map<String, DateTime> earliestBuy,
  ) {
    if (asset.kind != AssetKind.fixedIncome) return null;
    final parsed = FixedIncomeMetadata.read(asset);
    final purchase =
        earliestBuy[_holdingKey(holding.assetId, holding.institutionId)];
    if (parsed == null || purchase == null) return null;
    final (basis, rate) = parsed;
    final index = basis.economicIndex;
    return FixedIncomeTerms(
      basis: basis,
      ratePercent: rate,
      purchaseDate: purchase,
      series: index == null ? const [] : (_indexSeries[index] ?? const []),
    );
  }

  /// Earliest buy date per holding key (`assetId|institutionId`).
  Map<String, DateTime> _earliestBuyByHolding(List<AssetTransaction> txns) {
    final earliest = <String, DateTime>{};
    for (final tx in txns) {
      if (tx.kind != TransactionKind.buy) continue;
      final key = _holdingKey(tx.assetId, tx.institutionId);
      final current = earliest[key];
      if (current == null || tx.date.isBefore(current)) earliest[key] = tx.date;
    }
    return earliest;
  }

  DateTime? _earliestBuyForAsset(String assetId, List<AssetTransaction> txns) {
    DateTime? earliest;
    for (final tx in txns) {
      if (tx.kind != TransactionKind.buy || tx.assetId != assetId) continue;
      if (earliest == null || tx.date.isBefore(earliest)) earliest = tx.date;
    }
    return earliest;
  }

  String _holdingKey(String assetId, String institutionId) =>
      '$assetId|$institutionId';

  void _onError(Object _, StackTrace _) => emit(const DashboardError());

  @override
  Future<void> close() async {
    await _transactionSub.cancel();
    await _assetSub.cancel();
    await _institutionSub.cancel();
    return super.close();
  }
}
