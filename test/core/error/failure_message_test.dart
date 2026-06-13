import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failure_message.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/error/validation_message.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

void main() {
  group('failureMessage', () {
    test('maps each failure type to its localized copy', () {
      expect(failureMessage(const NetworkFailure()), t.errors.network);
      expect(failureMessage(const ServerFailure()), t.errors.server);
      expect(failureMessage(const CacheFailure()), t.errors.storage);
      expect(failureMessage(const ParseFailure()), t.errors.unexpected);
      expect(failureMessage(const InUseFailure()), t.errors.inUse);
      expect(failureMessage(const NotFoundFailure()), t.errors.notFound);
      expect(
        failureMessage(const UnauthorizedFailure()),
        t.auth.unauthorizedAccount,
      );
    });

    test('a codeless ValidationFailure falls back to the generic message', () {
      expect(failureMessage(const ValidationFailure()), t.errors.invalid);
    });

    test('a coded ValidationFailure defers to validationMessage', () {
      const failure = ValidationFailure('x', ValidationCode.oversell);
      expect(failureMessage(failure), validationMessage(failure));
      expect(failureMessage(failure), t.transactions.oversellError);
    });

    test('never surfaces the raw developer-facing message', () {
      // The point of this mapper: the English Failure.message must not leak.
      expect(
        failureMessage(const ServerFailure('raw dev text')),
        isNot(contains('raw dev text')),
      );
    });
  });
}
