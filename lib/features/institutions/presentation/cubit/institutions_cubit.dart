import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/institutions/domain/repositories/institution_repository.dart';
import 'package:investanco/features/institutions/presentation/cubit/institutions_state.dart';

/// Orchestrates the institutions list and CRUD. UI calls these methods; the
/// repository executes persistence. The list updates reactively via a stream.
class InstitutionsCubit extends Cubit<InstitutionsState> {
  /// Subscribes to the institutions stream on creation.
  InstitutionsCubit(this._repository, this._idGenerator)
      : super(const InstitutionsLoading()) {
    _subscription = _repository.watchAll().listen(
      (items) => emit(InstitutionsLoaded(items)),
      onError: (Object _, StackTrace _) => emit(const InstitutionsError()),
    );
  }

  final InstitutionRepository _repository;
  final IdGenerator _idGenerator;
  late final StreamSubscription<List<Institution>> _subscription;

  /// Creates a new institution. Returns a [Failure] on error, else null.
  Future<Failure?> add({
    required String name,
    required InstitutionKind kind,
    required Currency currency,
  }) {
    final institution = Institution(
      id: _idGenerator.newId(),
      name: name.trim(),
      kind: kind,
      currency: currency,
      createdAt: DateTime.now(),
    );
    return _save(institution);
  }

  /// Persists edits to an existing institution.
  Future<Failure?> edit(Institution institution) => _save(institution);

  /// Deletes an institution. Returns [InUseFailure] when it has transactions.
  Future<Failure?> remove(String id) async {
    final result = await _repository.delete(id);
    return result.failureOrNull;
  }

  Future<Failure?> _save(Institution institution) async {
    final result = await _repository.save(institution);
    return result.failureOrNull;
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
