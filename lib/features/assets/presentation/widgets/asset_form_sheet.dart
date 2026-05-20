import 'package:flutter/material.dart';
import 'package:investanco/core/l10n/currency_label.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/presentation/asset_labels.dart';
import 'package:investanco/features/assets/presentation/cubit/assets_cubit.dart';
import 'package:investanco/gen/strings.g.dart';

/// Bottom sheet to add or edit an [Asset].
class AssetFormSheet extends StatefulWidget {
  /// Creates the form, optionally pre-filled with [existing] for editing.
  const AssetFormSheet({required this.cubit, this.existing, super.key});

  /// Cubit used to persist the asset.
  final AssetsCubit cubit;

  /// When non-null, the sheet edits this asset instead of creating one.
  final Asset? existing;

  /// Opens the sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context,
    AssetsCubit cubit, {
    Asset? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AssetFormSheet(cubit: cubit, existing: existing),
    );
  }

  @override
  State<AssetFormSheet> createState() => _AssetFormSheetState();
}

class _AssetFormSheetState extends State<AssetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tickerController;
  late final TextEditingController _nameController;
  late AssetKind _kind;
  late Market _market;
  late Currency _currency;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _tickerController = TextEditingController(text: existing?.ticker ?? '');
    _nameController = TextEditingController(text: existing?.name ?? '');
    _kind = existing?.kind ?? AssetKind.stockBr;
    _market = existing?.market ?? Market.br;
    _currency = existing?.currency ?? Currency.brl;
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onMarketChanged(Market? value) {
    if (value == null) return;
    setState(() {
      _market = value;
      _currency = switch (value) {
        Market.us => Currency.usd,
        Market.br => Currency.brl,
        Market.global => _currency,
      };
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final existing = widget.existing;
    final failure = existing == null
        ? await widget.cubit.add(
            ticker: _tickerController.text,
            name: _nameController.text,
            kind: _kind,
            market: _market,
            currency: _currency,
          )
        : await widget.cubit.edit(
            existing.copyWith(
              ticker: _tickerController.text.trim().toUpperCase(),
              name: _nameController.text.trim(),
              kind: _kind,
              market: _market,
              currency: _currency,
            ),
          );

    if (!mounted) return;
    if (failure != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.assets.saveError)),
      );
      return;
    }
    Navigator.of(context).pop();
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
                widget.existing == null ? t.assets.add : t.assets.edit,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tickerController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: t.assets.ticker),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? t.common.required
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: t.assets.name),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? t.common.required
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AssetKind>(
                initialValue: _kind,
                decoration: InputDecoration(labelText: t.assets.kind),
                items: [
                  for (final kind in AssetKind.values)
                    DropdownMenuItem(
                      value: kind,
                      child: Text(assetKindLabel(kind)),
                    ),
                ],
                onChanged: (value) => setState(() => _kind = value ?? _kind),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Market>(
                initialValue: _market,
                decoration: InputDecoration(labelText: t.assets.market),
                items: [
                  for (final market in Market.values)
                    DropdownMenuItem(
                      value: market,
                      child: Text(marketLabel(market)),
                    ),
                ],
                onChanged: _onMarketChanged,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Currency>(
                initialValue: _currency,
                decoration: InputDecoration(labelText: t.assets.currency),
                items: [
                  for (final currency in Currency.values)
                    DropdownMenuItem(
                      value: currency,
                      child: Text(currencyLabel(currency)),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _currency = value ?? _currency),
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
