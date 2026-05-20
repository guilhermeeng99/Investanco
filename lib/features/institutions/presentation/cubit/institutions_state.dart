import 'package:equatable/equatable.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';

/// State for the institutions cubit. See `docs/specs/institutions.md`.
sealed class InstitutionsState extends Equatable {
  const InstitutionsState();

  @override
  List<Object?> get props => [];
}

/// Initial loading state.
class InstitutionsLoading extends InstitutionsState {
  /// Creates the loading state.
  const InstitutionsLoading();
}

/// Loaded with the current list (possibly empty).
class InstitutionsLoaded extends InstitutionsState {
  /// Creates the loaded state.
  const InstitutionsLoaded(this.institutions);

  /// Current institutions, ordered by name.
  final List<Institution> institutions;

  @override
  List<Object?> get props => [institutions];
}

/// The list stream failed.
class InstitutionsError extends InstitutionsState {
  /// Creates the error state.
  const InstitutionsError();
}
