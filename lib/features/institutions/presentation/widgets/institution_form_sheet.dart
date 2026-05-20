import 'package:flutter/material.dart';
import 'package:investanco/core/l10n/currency_label.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/institutions/presentation/cubit/institutions_cubit.dart';
import 'package:investanco/features/institutions/presentation/institution_labels.dart';
import 'package:investanco/gen/strings.g.dart';

/// Bottom sheet to add or edit an [Institution].
class InstitutionFormSheet extends StatefulWidget {
  /// Creates the form, optionally pre-filled with [existing] for editing.
  const InstitutionFormSheet({required this.cubit, this.existing, super.key});

  /// Cubit used to persist the institution.
  final InstitutionsCubit cubit;

  /// When non-null, the sheet edits this institution instead of creating one.
  final Institution? existing;

  /// Opens the sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context,
    InstitutionsCubit cubit, {
    Institution? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => InstitutionFormSheet(cubit: cubit, existing: existing),
    );
  }

  @override
  State<InstitutionFormSheet> createState() => _InstitutionFormSheetState();
}

class _InstitutionFormSheetState extends State<InstitutionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late InstitutionKind _kind;
  late Currency _currency;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _kind = existing?.kind ?? InstitutionKind.bank;
    _currency = existing?.currency ?? Currency.brl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final existing = widget.existing;
    final failure = existing == null
        ? await widget.cubit.add(
            name: _nameController.text,
            kind: _kind,
            currency: _currency,
          )
        : await widget.cubit.edit(
            existing.copyWith(
              name: _nameController.text.trim(),
              kind: _kind,
              currency: _currency,
            ),
          );

    if (!mounted) return;
    if (failure != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.institutions.saveError)),
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null
                  ? t.institutions.add
                  : t.institutions.edit,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(labelText: t.institutions.name),
              validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? t.common.required
                      : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<InstitutionKind>(
              initialValue: _kind,
              decoration: InputDecoration(labelText: t.institutions.kind),
              items: [
                for (final kind in InstitutionKind.values)
                  DropdownMenuItem(
                    value: kind,
                    child: Text(institutionKindLabel(kind)),
                  ),
              ],
              onChanged: (value) => setState(() => _kind = value ?? _kind),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Currency>(
              initialValue: _currency,
              decoration: InputDecoration(labelText: t.institutions.currency),
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
    );
  }
}
