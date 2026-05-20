// Ports for market data. FxDataSource is intentionally single-method so it can
// be injected and faked in tests.
// ignore_for_file: one_member_abstracts
import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';

/// A source of unit prices for some kinds of asset.
abstract class QuoteDataSource {
  /// Whether this source can price [asset].
  bool supports(Asset asset);

  /// Fetches quotes for the supported subset of [assets]. Unsupported assets
  /// are ignored; failures return a [Failure].
  Future<Either<Failure, List<Quote>>> fetch(List<Asset> assets);
}

/// A source of FX rates.
abstract class FxDataSource {
  /// Returns the multiplier converting [from] into [to] (1.0 when equal).
  Future<Either<Failure, double>> rate(Currency from, Currency to);
}
