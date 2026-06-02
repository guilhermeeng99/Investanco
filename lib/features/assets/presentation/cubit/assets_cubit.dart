import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/allocation/domain/entities/asset_class.dart';
import 'package:investanco/features/allocation/domain/repositories/asset_class_repository.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/domain/repositories/asset_repository.dart';
import 'package:investanco/features/assets/presentation/cubit/assets_state.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/institutions/domain/repositories/institution_repository.dart';

/// Orchestrates the assets list and CRUD. Reactive list via a stream.
class AssetsCubit extends Cubit<AssetsState> {
  /// Subscribes to the assets stream on creation.
  AssetsCubit(
    this._repository,
    this._idGenerator,
    this._assetClassRepository,
    this._institutionRepository,
  ) : super(const AssetsLoading()) {
    _subscription = _repository.watchAll().listen(
      (items) => emit(AssetsLoaded(items)),
      onError: (Object _, StackTrace _) => emit(const AssetsError()),
    );
  }

  final AssetRepository _repository;
  final IdGenerator _idGenerator;
  final AssetClassRepository _assetClassRepository;
  final InstitutionRepository _institutionRepository;
  late final StreamSubscription<List<Asset>> _subscription;

  /// Creates a new asset. Returns a [Failure] on error, else null.
  Future<Failure?> add({
    required String ticker,
    required String name,
    required AssetKind kind,
    required Market market,
    required Currency currency,
    required String institutionId,
    Map<String, String> metadata = const {},
  }) {
    final asset = Asset(
      id: _idGenerator.newId(),
      ticker: ticker.trim().toUpperCase(),
      name: name.trim(),
      kind: kind,
      market: market,
      currency: currency,
      institutionId: institutionId,
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
    return result.failureOrNull;
  }

  /// One-shot load of the allocation classes for the asset form's class picker.
  /// Lives on the cubit so the form pulls its data through the orchestration
  /// layer instead of reaching into the service locator directly.
  Future<List<AssetClass>> loadAllocationClasses() =>
      _assetClassRepository.watchAll().first;

  /// One-shot load of institutions for the asset form's custodian picker.
  Future<List<Institution>> loadInstitutions() =>
      _institutionRepository.watchAll().first;

  Future<Failure?> _save(Asset asset) async {
    final result = await _repository.save(asset);
    return result.failureOrNull;
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
