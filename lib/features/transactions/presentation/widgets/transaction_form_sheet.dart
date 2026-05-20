import 'package:flutter/material.dart';
import 'package:investanco/core/format/money_input.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:investanco/features/transactions/presentation/transaction_labels.dart';
import 'package:investanco/gen/strings.g.dart';

/// Bottom sheet to add or edit an [AssetTransaction].
class TransactionFormSheet extends StatefulWidget {
  /// Creates the form.
  const TransactionFormSheet({
    required this.cubit,
    required this.assets,
    required this.institutions,
    this.existing,
    super.key,
  });

  /// Cubit used to persist.
  final TransactionsCubit cubit;

  /// Assets available to pick.
  final List<Asset> assets;

  /// Institutions available to pick.
  final List<Institution> institutions;

  /// When non-null, the sheet edits this transaction.
  final AssetTransaction? existing;

  /// Opens the sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context,
    TransactionsCubit cubit, {
    required List<Asset> assets,
    required List<Institution> institutions,
    AssetTransaction? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransactionFormSheet(
        cubit: cubit,
        assets: assets,
        institutions: institutions,
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

  late String _institutionId;
  late String _assetId;
  late TransactionKind _kind;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _quantityController =
        TextEditingController(text: existing?.quantity.toString() ?? '');
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
    _institutionId = existing?.institutionId ?? widget.institutions.first.id;
    _assetId = existing?.assetId ?? widget.assets.first.id;
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

  Asset get _selectedAsset =>
      widget.assets.firstWhere((a) => a.id == _assetId);

  bool get _isDividend => _kind == TransactionKind.dividend;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final currency = _selectedAsset.currency;
    final fees = Money.fromMajor(parseMajor(_feesController.text) ?? 0, currency);
    final quantity = _isDividend ? 0.0 : parseMajor(_quantityController.text)!;
    final unitPrice = _isDividend
        ? Money.zero(currency)
        : Money.fromMajor(parseMajor(_priceController.text) ?? 0, currency);
    final amount = _isDividend
        ? Money.fromMajor(parseMajor(_amountController.text) ?? 0, currency)
        : unitPrice * quantity;

    final existing = widget.existing;
    final failure = existing == null
        ? await widget.cubit.add(
            institutionId: _institutionId,
            assetId: _assetId,
            kind: _kind,
            quantity: quantity,
            unitPrice: unitPrice,
            fees: fees,
            amount: amount,
            date: _date,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          )
        : await widget.cubit.edit(
            existing.copyWith(
              institutionId: _institutionId,
              assetId: _assetId,
              kind: _kind,
              quantity: quantity,
              unitPrice: unitPrice,
              fees: fees,
              amount: amount,
              date: _date,
              notes: _notesController.text.trim(),
            ),
          );

    if (!mounted) return;
    if (failure != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.transactions.saveError)),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) return t.common.required;
    return parseMajor(value) == null ? t.common.required : null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null
                    ? t.transactions.add
                    : t.transactions.edit,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TransactionKind>(
                initialValue: _kind,
                decoration: InputDecoration(labelText: t.transactions.kind),
                items: [
                  for (final kind in TransactionKind.values)
                    DropdownMenuItem(
                      value: kind,
                      child: Text(transactionKindLabel(kind)),
                    ),
                ],
                onChanged: (value) => setState(() => _kind = value ?? _kind),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _assetId,
                decoration: InputDecoration(labelText: t.transactions.asset),
                items: [
                  for (final asset in widget.assets)
                    DropdownMenuItem(
                      value: asset.id,
                      child: Text('${asset.ticker} · ${asset.name}'),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _assetId = value ?? _assetId),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _institutionId,
                decoration:
                    InputDecoration(labelText: t.transactions.institution),
                items: [
                  for (final institution in widget.institutions)
                    DropdownMenuItem(
                      value: institution.id,
                      child: Text(institution.name),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _institutionId = value ?? _institutionId),
              ),
              const SizedBox(height: 12),
              if (!_isDividend) ...[
                TextFormField(
                  controller: _quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(labelText: t.transactions.quantity),
                  validator: _requiredNumber,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(labelText: t.transactions.unitPrice),
                  validator: _requiredNumber,
                ),
              ] else
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(labelText: t.transactions.amount),
                  validator: _requiredNumber,
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _feesController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: t.transactions.fees),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.transactions.date),
                subtitle: Text(
                  '${_date.day.toString().padLeft(2, '0')}/'
                  '${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDate,
              ),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(labelText: t.transactions.notes),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(t.common.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
