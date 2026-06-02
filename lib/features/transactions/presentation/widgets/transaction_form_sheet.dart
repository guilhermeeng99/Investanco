import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/format/date_formatter.dart';
import 'package:investanco/core/format/initials.dart';
import 'package:investanco/core/format/money_input.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/presentation/asset_visuals.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/domain/transaction_amounts.dart';
import 'package:investanco/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:investanco/features/transactions/presentation/transaction_labels.dart';
import 'package:investanco/features/transactions/presentation/transaction_visuals.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Bottom sheet to add or edit an [AssetTransaction].
class TransactionFormSheet extends StatefulWidget {
  /// Creates the form.
  const TransactionFormSheet({
    required this.cubit,
    required this.assets,
    this.existing,
    super.key,
  });

  /// Cubit used to persist.
  final TransactionsCubit cubit;

  /// Assets available to pick.
  final List<Asset> assets;

  /// When non-null, the sheet edits this transaction.
  final AssetTransaction? existing;

  /// Opens the sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context,
    TransactionsCubit cubit, {
    required List<Asset> assets,
    AssetTransaction? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransactionFormSheet(
        cubit: cubit,
        assets: assets,
        existing: existing,
      ),
    );
  }

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _feesController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  late String _assetId;
  late TransactionKind _kind;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _quantityController = TextEditingController(
      text: existing?.quantity.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: existing == null ? '' : existing.unitPrice.major.toString(),
    );
    _feesController = TextEditingController(
      text: existing == null ? '' : existing.fees.major.toString(),
    );
    _amountController = TextEditingController(
      text: existing == null ? '' : existing.amount.major.toString(),
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _assetId =
        existing?.assetId ?? _firstLinkedAssetId() ?? widget.assets.first.id;
    _kind = existing?.kind ?? TransactionKind.buy;
    _date = existing?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _feesController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _firstLinkedAssetId() {
    for (final asset in widget.assets) {
      if (asset.institutionId != null &&
          asset.institutionId!.trim().isNotEmpty) {
        return asset.id;
      }
    }
    return null;
  }

  Asset get _selectedAsset => widget.assets.firstWhere((a) => a.id == _assetId);

  bool get _isDividend => _kind == TransactionKind.dividend;

  Future<void> _pickAsset() async {
    final picked = await showOptionPicker<String>(
      context,
      title: t.transactions.asset,
      selected: _assetId,
      items: [
        for (final asset in widget.assets)
          OptionPickerItem(
            value: asset.id,
            label: '${asset.ticker}  ·  ${asset.name}',
            leading: BrandAvatar(
              size: 32,
              background: assetKindColor(asset.kind),
              initials: tickerInitials(asset.ticker),
            ),
          ),
      ],
    );
    if (picked == null) return;
    setState(() => _assetId = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<Failure?> _persist() async {
    final institutionId = _selectedAsset.institutionId?.trim();
    if (institutionId == null || institutionId.isEmpty) {
      return const ValidationFailure(
        'The asset must be linked to an institution first.',
        ValidationCode.assetInstitutionRequired,
      );
    }
    final currency = _selectedAsset.currency;
    final amounts = resolveTransactionAmounts(
      kind: _kind,
      quantity: parseMajor(_quantityController.text) ?? 0,
      unitPrice: Money.fromMajor(
        parseMajor(_priceController.text) ?? 0,
        currency,
      ),
      amount: Money.fromMajor(
        parseMajor(_amountController.text) ?? 0,
        currency,
      ),
      currency: currency,
    );
    final fees = Money.fromMajor(
      parseMajor(_feesController.text) ?? 0,
      currency,
    );

    final existing = widget.existing;
    return existing == null
        ? widget.cubit.add(
            institutionId: institutionId,
            assetId: _assetId,
            kind: _kind,
            quantity: amounts.quantity,
            unitPrice: amounts.unitPrice,
            fees: fees,
            amount: amounts.amount,
            date: _date,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          )
        : widget.cubit.edit(
            existing.copyWith(
              institutionId: institutionId,
              assetId: _assetId,
              kind: _kind,
              quantity: amounts.quantity,
              unitPrice: amounts.unitPrice,
              fees: fees,
              amount: amounts.amount,
              date: _date,
              notes: _notesController.text.trim(),
            ),
          );
  }

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) return t.common.required;
    return parseMajor(value) == null ? t.common.required : null;
  }

  static const _decimalKeyboard = TextInputType.numberWithOptions(
    decimal: true,
  );

  List<TextInputFormatter> get _decimalFormatters => [
    FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
  ];

  @override
  Widget build(BuildContext context) {
    final symbol = _selectedAsset.currency.symbol;
    return InvestancoFormSheetScaffold(
      formKey: _formKey,
      title: widget.existing == null ? t.transactions.add : t.transactions.edit,
      onSubmit: _persist,
      errorText: t.transactions.saveError,
      children: [
        InvestancoPillToggle<TransactionKind>(
          selected: _kind,
          onChanged: (value) => setState(() => _kind = value),
          options: [
            for (final kind in TransactionKind.values)
              InvestancoPillToggleOption(
                value: kind,
                label: transactionKindLabel(kind),
                icon: transactionKindIcon(kind),
                accent: transactionKindColor(kind, context.appColors),
              ),
          ],
        ),
        const SizedBox(height: 16),
        InvestancoPickerField(
          label: t.transactions.asset,
          value: '${_selectedAsset.ticker}  ·  ${_selectedAsset.name}',
          placeholder: t.transactions.asset,
          onTap: _pickAsset,
          leading: BrandAvatar(
            size: 32,
            background: assetKindColor(_selectedAsset.kind),
            initials: tickerInitials(_selectedAsset.ticker),
          ),
        ),
        const SizedBox(height: 12),
        if (!_isDividend)
          Row(
            children: [
              Expanded(
                child: InvestancoTextField(
                  label: t.transactions.quantity,
                  controller: _quantityController,
                  keyboardType: _decimalKeyboard,
                  inputFormatters: _decimalFormatters,
                  validator: _requiredNumber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InvestancoTextField(
                  label: t.transactions.unitPrice,
                  controller: _priceController,
                  keyboardType: _decimalKeyboard,
                  inputFormatters: _decimalFormatters,
                  prefixText: '$symbol ',
                  validator: _requiredNumber,
                ),
              ),
            ],
          )
        else
          InvestancoTextField(
            label: t.transactions.amount,
            controller: _amountController,
            keyboardType: _decimalKeyboard,
            inputFormatters: _decimalFormatters,
            prefixText: '$symbol ',
            validator: _requiredNumber,
          ),
        const SizedBox(height: 12),
        InvestancoTextField(
          label: t.transactions.fees,
          controller: _feesController,
          keyboardType: _decimalKeyboard,
          inputFormatters: _decimalFormatters,
          prefixText: '$symbol ',
        ),
        const SizedBox(height: 12),
        InvestancoPickerField(
          label: t.transactions.date,
          value: formatShortDate(_date),
          placeholder: t.transactions.date,
          onTap: _pickDate,
        ),
        const SizedBox(height: 12),
        InvestancoTextField(
          label: t.transactions.notes,
          controller: _notesController,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}
