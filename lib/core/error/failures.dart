import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

/// Base type for all recoverable errors crossing an architecture boundary.
///
/// Repositories return `Either<Failure, T>`; the presentation layer maps each
/// concrete failure to a user-facing message.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// A remote/data-source returned an error or unexpected status.
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

/// No connectivity / request could not reach the network.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

/// Local persistence (Drift) read/write error.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local storage error']);
}

/// A response could not be parsed into the expected model.
class ParseFailure extends Failure {
  const ParseFailure([super.message = 'Unexpected response format']);
}

/// The specific rule a [ValidationFailure] broke, so the UI can show targeted,
/// localized copy. Mapped to a message by `core/error/validation_message.dart`.
enum ValidationCode {
  /// Another institution already uses this name.
  duplicateInstitutionName,

  /// Another asset already uses this (ticker, market) pair.
  duplicateAsset,

  /// A transaction dated after today.
  futureTransactionDate,

  /// A sell exceeds the quantity held in the position on its date.
  oversell,

  /// Allocation-class targets sum to more than 100%.
  classTargetSum,
}

/// Domain validation rejected the input (e.g. oversell, duplicate name). [code]
/// names the specific rule so the presentation layer can localize it.
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid data', this.code]);

  /// The specific rule that failed, or null for a generic rejection.
  final ValidationCode? code;

  @override
  List<Object?> get props => [message, code];
}

/// A record cannot be deleted because it is referenced by others.
class InUseFailure extends Failure {
  const InUseFailure([super.message = 'Record is in use']);
}

/// The requested record does not exist.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found']);
}

/// The signed-in account is not on the owner allow-list of this single-owner
/// app. The client signs the user back out and shows a localized error; the
/// Firestore security rules enforce the same restriction server-side.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Account not authorized']);
}

/// Collapses a repository result to its [Failure], or null on success — for
/// fire-and-forget writes whose only interesting outcome is the error (e.g. a
/// cubit returning `Future<Failure?>` to the form that triggered the save).
extension FailureOrNull<T> on Either<Failure, T> {
  /// The [Failure] if this is a `Left`, otherwise null.
  Failure? get failureOrNull => fold((failure) => failure, (_) => null);
}
