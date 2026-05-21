import 'package:investanco/features/quotes/domain/entities/index_point.dart';

/// Test factory for [IndexPoint] (a single daily index reading). Never hardcode
/// entities in tests.
IndexPoint indexPointFactory({DateTime? date, double rate = 1}) {
  return IndexPoint(date: date ?? DateTime(2026, 5, 4), rate: rate);
}
