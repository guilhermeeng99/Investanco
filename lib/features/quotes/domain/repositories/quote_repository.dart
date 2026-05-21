import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';

/// Cached-first access to quotes. See `docs/specs/quotes.md`.
abstract class QuoteRepository {
  /// Returns cached quotes for the given asset ids (may be empty/stale).
  Future<Either<Failure, List<Quote>>> getCached(List<String> assetIds);

  /// Fetches fresh quotes from the data sources and updates the cache. Returns
  /// the quotes obtained (a partial set on partial failure).
  Future<Either<Failure, List<Quote>>> refresh(List<Asset> assets);
}
