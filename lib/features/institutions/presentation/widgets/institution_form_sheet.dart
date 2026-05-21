import 'package:flutter/material.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/l10n/currency_label.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/institutions/presentation/cubit/institutions_cubit.dart';
import 'package:investanco/features/institutions/presentation/institution_labels.dart';
import 'package:investanco/features/institutions/presentation/institution_visuals.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

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

  Future<void> _pickKind() async {
    final picked = await showOptionPicker<InstitutionKind>(
      context,
      title: t.institutions.kind,
      selected: _kind,
      items: [
        for (final kind in InstitutionKind.values)
          OptionPickerItem(
            value: kind,
            label: institutionKindLabel(kind),
            leading: BrandAvatar(
              size: 32,
              background: institutionKindColor(kind),
              icon: institutionKindIcon(kind),
            ),
          ),
      ],
    );
    if (picked != null) setState(() => _kind = picked);
  }

  Future<void> _pickCurrency() async {
    final picked = await showOptionPicker<Currency>(
      context,
      title: t.institutions.currency,
      selected: _currency,
      items: [
        for (final currency in Currency.values)
          OptionPickerItem(value: currency, label: currencyLabel(currency)),
      ],
    );
    if (picked != null) setState(() => _currency = picked);
  }

  Future<Failure?> _persist() {
    final existing = widget.existing;
    return existing == null
        ? widget.cubit.add(
            name: _nameController.text,
            kind: _kind,
            currency: _currency,
          )
        : widget.cubit.edit(
            existing.copyWith(
              name: _nameController.text.trim(),
              kind: _kind,
              currency: _currency,
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return InvestancoFormSheetScaffold(
      formKey: _formKey,
      title: widget.existing == null ? t.institutions.add : t.institutions.edit,
      onSubmit: _persist,
      errorText: t.institutions.saveError,
      children: [
        InvestancoTextField(
          label: t.institutions.name,
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? t.common.required : null,
        ),
        const SizedBox(height: 12),
        InvestancoPickerField(
          label: t.institutions.kind,
          value: institutionKindLabel(_kind),
          placeholder: t.institutions.kind,
          onTap: _pickKind,
          leading: BrandAvatar(
            size: 32,
            background: institutionKindColor(_kind),
            icon: institutionKindIcon(_kind),
          ),
        ),
        const SizedBox(height: 12),
        InvestancoPickerField(
          label: t.institutions.currency,
          value: currencyLabel(_currency),
          placeholder: t.institutions.currency,
          onTap: _pickCurrency,
        ),
      ],
    );
  }
}
