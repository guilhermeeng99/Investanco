import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/gen/strings.g.dart';

/// Localized label for a [TransactionKind].
String transactionKindLabel(TransactionKind kind) => switch (kind) {
      TransactionKind.buy => t.transactions.kinds.buy,
      TransactionKind.sell => t.transactions.kinds.sell,
      TransactionKind.dividend => t.transactions.kinds.dividend,
    };
