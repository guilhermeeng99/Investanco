import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/error/validation_message.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Localized, user-facing message for a [Failure], chosen by its type — so the
/// presentation layer never shows a raw `Failure.message` (English, developer-
/// facing). Use at every display site (error screens, snackbars). A
/// [ValidationFailure] with a code defers to [validationMessage].
String failureMessage(Failure failure) => switch (failure) {
      NetworkFailure() => t.errors.network,
      ServerFailure() => t.errors.server,
      CacheFailure() => t.errors.storage,
      ParseFailure() => t.errors.unexpected,
      ValidationFailure() => validationMessage(failure) ?? t.errors.invalid,
      InUseFailure() => t.errors.inUse,
      NotFoundFailure() => t.errors.notFound,
    };
