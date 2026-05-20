import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/domain/repositories/asset_repository.dart';
import 'package:investanco/features/assets/presentation/cubit/assets_state.dart';

/// Orchestrates the assets list and CRUD. Reactive list via a stream.
class AssetsCubit extends Cubit<AssetsState> {
  /// Subscribes to the assets stream on creation.
  AssetsCubit(this._repository, this._idGenerator)
      : super(const AssetsLoading()) {
    _subscription = _repository.watchAll().listen(
      (items) => emit(AssetsLoaded(items)),
      onError: (Object _, StackTrace _) => emit(const AssetsError()),
    );
  }

  final AssetRepository _repository;
  final IdGenerator _idGenerator;
  late final StreamSubscription<List<Asset>> _subscription;

  /// Creates a new asset. Returns a [Failure] on error, else null.
  Future<Failure?> add({
    required String ticker,
    required String name,
    required AssetKind kind,
    required Market market,
    required Currency currency,
    Map<String, String> metadata = const {},
  }) {
    final asset = Asset(
      id: _idGenerator.newId(),
      ticker: ticker.trim().toUpperCase(),
      name: name.trim(),
      kind: kind,
      market: market,
      currency: currency,
      metadata: metadata,
      createdAt: DateTime.now(),
    );
    return _save(asset);
  }

  /// Persists edits to an existing asset.
  Future<Failure?> edit(Asset asset) => _save(asset);

  /// Deletes an asset. Returns [InUseFailure] when it has transactions.
  Future<Failure?> remove(String id) async {
    final result = await _repository.delete(id);
    return result.fold((failure) => failure, (_) => null);
  }

  Future<Failure?> _save(Asset asset) async {
    final result = await _repository.save(asset);
    return result.fold((failure) => failure, (_) => null);
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
