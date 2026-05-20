import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';

/// Test factory for [Institution]. Never hardcode entities in tests.
Institution institutionFactory({
  String id = 'i1',
  String name = 'Nubank',
  InstitutionKind kind = InstitutionKind.bank,
  Currency currency = Currency.brl,
  DateTime? createdAt,
}) {
  return Institution(
    id: id,
    name: name,
    kind: kind,
    currency: currency,
    createdAt: createdAt ?? DateTime(2026),
  );
}
