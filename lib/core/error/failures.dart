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

/// Domain validation rejected the input (e.g. oversell, duplicate name).
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid data']);
}

/// A record cannot be deleted because it is referenced by others.
class InUseFailure extends Failure {
  const InUseFailure([super.message = 'Record is in use']);
}

/// The requested record does not exist.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found']);
}
