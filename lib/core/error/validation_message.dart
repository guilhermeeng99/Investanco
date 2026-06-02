import 'package:investanco/core/error/failures.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Localized message for a [ValidationFailure] carrying a [ValidationCode], or
/// null when the failure has no specific code (the caller then falls back to a
/// generic error). Centralizes the code→copy mapping so each form's submit flow
/// doesn't repeat it. See `InvestancoFormSheetScaffold`.
String? validationMessage(ValidationFailure failure) {
  final code = failure.code;
  if (code == null) return null;
  return switch (code) {
    ValidationCode.duplicateInstitutionName => t.institutions.duplicateName,
    ValidationCode.duplicateAsset => t.assets.duplicateAsset,
    ValidationCode.assetInstitutionRequired => t.assets.institutionRequired,
    ValidationCode.transactionInstitutionMismatch =>
      t.transactions.institutionMismatchError,
    ValidationCode.futureTransactionDate => t.transactions.futureDateError,
    ValidationCode.oversell => t.transactions.oversellError,
    ValidationCode.nonPositiveQuantity => t.transactions.quantityError,
    ValidationCode.classTargetSum => t.allocation.targetSumError,
  };
}
