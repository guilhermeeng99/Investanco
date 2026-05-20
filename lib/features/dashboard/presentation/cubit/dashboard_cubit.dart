import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/domain/repositories/asset_repository.dart';
import 'package:investanco/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:investanco/features/holdings/domain/holding_calculator.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/institutions/domain/repositories/institution_repository.dart';
import 'package:investanco/features/quotes/domain/datasources/quote_data_source.dart';
import 'package:investanco/features/quotes/domain/repositories/quote_repository.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/domain/repositories/transaction_repository.dart';
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

  late final StreamSubscription<List<AssetTransaction>> _transactionSub;
  late final StreamSubscription<List<Asset>> _assetSub;
  late final StreamSubscription<List<Institution>> _institutionSub;

  List<AssetTransaction>? _transactions;
  List<Asset>? _assets;
  List<Institution>? _institutions;

  double _fxUsdToBrl = 1;
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
    if (heldAssets.any((a) => a.currency != Currency.brl)) {
      final fx = await _fxDataSource.rate(Currency.usd, Currency.brl);
      fx.fold((_) {}, (rate) => _fxUsdToBrl = rate);
    }

    _lastSyncAt = DateTime.now();
    _refreshing = false;
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

    final inputs = [
      for (final holding in holdings)
        if (assetsById[holding.assetId] case final asset?)
          ValuationInput(
            holding: holding,
            asset: asset,
            quote: quotesById[holding.assetId],
            fxToBase: asset.currency == Currency.brl ? 1.0 : _fxUsdToBrl,
          ),
    ];

    final portfolio = _valuationService.valuatePortfolio(
      inputs,
      now: DateTime.now(),
    );

    emit(
      DashboardLoaded(
        portfolio: portfolio,
        assetsById: assetsById,
        institutionsById: {for (final i in institutions) i.id: i},
        lastSyncAt: _lastSyncAt,
        isRefreshing: _refreshing,
      ),
    );

    if (!_autoRefreshed && holdings.any((h) => h.quantity > 0)) {
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
