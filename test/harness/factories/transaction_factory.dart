import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';

/// Test factory for [AssetTransaction]. Defaults to a 1-unit BRL buy.
AssetTransaction transactionFactory({
  String id = 't1',
  String institutionId = 'i1',
  String assetId = 'a1',
  TransactionKind kind = TransactionKind.buy,
  double quantity = 1,
  Money? unitPrice,
  Money? fees,
  Money? amount,
  DateTime? date,
  String? notes,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  const currency = Currency.brl;
  final price = unitPrice ?? Money.fromMajor(10, currency);
  final when = date ?? DateTime(2026);
  return AssetTransaction(
    id: id,
    institutionId: institutionId,
    assetId: assetId,
    kind: kind,
    quantity: quantity,
    unitPrice: price,
    fees: fees ?? const Money.zero(Currency.brl),
    amount: amount ?? price * quantity,
    date: when,
    notes: notes,
    createdAt: createdAt ?? when,
    updatedAt: updatedAt ?? when,
  );
}
