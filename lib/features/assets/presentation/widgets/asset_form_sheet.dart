import 'dart:async';

import 'package:flutter/material.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/format/money_input.dart';
import 'package:investanco/core/l10n/currency_label.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/allocation/domain/asset_allocation.dart';
import 'package:investanco/features/allocation/domain/entities/asset_class.dart';
import 'package:investanco/features/allocation/domain/repositories/asset_class_repository.dart';
import 'package:investanco/features/allocation/presentation/allocation_visuals.dart';
import 'package:investanco/features/assets/domain/asset_kind_defaults.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/presentation/asset_labels.dart';
import 'package:investanco/features/assets/presentation/asset_visuals.dart';
import 'package:investanco/features/assets/presentation/cubit/assets_cubit.dart';
import 'package:investanco/features/valuation/domain/entities/fixed_income_terms.dart';
import 'package:investanco/features/valuation/domain/fixed_income_metadata.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Bottom sheet to add or edit an [Asset].
class AssetFormSheet extends StatefulWidget {
  /// Creates the form, optionally pre-filled with [existing] for editing.
  const AssetFormSheet({
    required this.cubit,
    this.existing,
    this.presetAllocationClassId,
    super.key,
  });

  /// Cubit used to persist the asset.
  final AssetsCubit cubit;

  /// When non-null, the sheet edits this asset instead of creating one.
  final Asset? existing;

  /// When set (e.g. opened from a class detail), pre-selects the allocation
  /// class for a new asset.
  final String? presetAllocationClassId;

  /// Opens the sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context,
    AssetsCubit cubit, {
    Asset? existing,
    String? presetAllocationClassId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AssetFormSheet(
        cubit: cubit,
        existing: existing,
        presetAllocationClassId: presetAllocationClassId,
      ),
    );
  }

  @override
  State<AssetFormSheet> createState() => _AssetFormSheetState();
}

class _AssetFormSheetState extends State<AssetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tickerController;
  late final TextEditingController _nameController;
  late final TextEditingController _tesouroNameController;
  late final TextEditingController _fiRateController;
  late AssetKind _kind;
  late FixedIncomeBasis _fiBasis;
  late Market _market;
  late Currency _currency;
  late final TextEditingController _allocationTargetController;
  String? _allocationClassId;
  List<AssetClass> _allocationClasses = const [];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _tickerController = TextEditingController(text: existing?.ticker ?? '');
    _nameController = TextEditingController(text: existing?.name ?? '');
    _tesouroNameController = TextEditingController(
      text: existing?.metadata['tesouroName'] ?? '',
    );
    _fiRateController = TextEditingController(
      text: existing?.metadata[FixedIncomeMetadata.rateKey] ?? '',
    );
    final fiBasis =
        existing == null ? null : FixedIncomeMetadata.read(existing)?.$1;
    _fiBasis = fiBasis ?? FixedIncomeBasis.cdi;
    // New assets default to the first selectable kind (and its usual
    // market/currency) so the pre-filled Type is one the picker can re-select.
    final defaultKind = AssetKind.selectableKinds.first;
    final (defaultMarket, defaultCurrency) = assetKindDefaults(defaultKind);
    _kind = existing?.kind ?? defaultKind;
    _market = existing?.market ?? defaultMarket;
    _currency = existing?.currency ?? defaultCurrency;

    _allocationClassId = existing == null
        ? widget.presetAllocationClassId
        : allocationClassIdOf(existing);
    _allocationTargetController = TextEditingController(
      text: existing == null
          ? ''
          : (existing.metadata[allocationTargetKey] ?? ''),
    );
    unawaited(_loadAllocationClasses());
  }

  Future<void> _loadAllocationClasses() async {
    final classes = await sl<AssetClassRepository>().watchAll().first;
    if (mounted) setState(() => _allocationClasses = classes);
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _nameController.dispose();
    _tesouroNameController.dispose();
    _fiRateController.dispose();
    _allocationTargetController.dispose();
    super.dispose();
  }

  AssetClass? _classOf(String? id) {
    if (id == null) return null;
    for (final c in _allocationClasses) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Picking a kind pre-fills market and currency to the usual pairing
  /// (US kinds → EUA/USD, BR kinds → Brasil/BRL); both remain editable.
  Future<void> _pickKind() async {
    final picked = await showOptionPicker<AssetKind>(
      context,
      title: t.assets.kind,
      selected: _kind,
      items: [
        for (final kind in AssetKind.selectableKinds)
          OptionPickerItem(
            value: kind,
            label: assetKindLabel(kind),
            leading: BrandAvatar(
              size: 32,
              background: assetKindColor(kind),
              icon: assetKindIcon(kind),
            ),
          ),
      ],
    );
    if (picked == null) return;
    final (market, currency) = assetKindDefaults(picked);
    setState(() {
      _kind = picked;
      _market = market;
      _currency = currency;
    });
  }

  Future<void> _pickMarket() async {
    final picked = await showOptionPicker<Market>(
      context,
      title: t.assets.market,
      selected: _market,
      items: [
        for (final market in Market.values)
          OptionPickerItem(value: market, label: marketLabel(market)),
      ],
    );
    if (picked == null) return;
    setState(() {
      _market = picked;
      _currency = switch (picked) {
        Market.us => Currency.usd,
        Market.br => Currency.brl,
        Market.global => _currency,
      };
    });
  }

  Future<void> _pickCurrency() async {
    final picked = await showOptionPicker<Currency>(
      context,
      title: t.assets.currency,
      selected: _currency,
      items: [
        for (final currency in Currency.values)
          OptionPickerItem(value: currency, label: currencyLabel(currency)),
      ],
    );
    if (picked != null) setState(() => _currency = picked);
  }

  Future<void> _pickFiBasis() async {
    final picked = await showOptionPicker<FixedIncomeBasis>(
      context,
      title: t.assets.fixedIncomeBasis,
      selected: _fiBasis,
      items: [
        for (final basis in FixedIncomeBasis.values)
          OptionPickerItem(value: basis, label: fixedIncomeBasisLabel(basis)),
      ],
    );
    if (picked != null) setState(() => _fiBasis = picked);
  }

  void _noop() {}

  Future<void> _pickAllocationClass(FormFieldState<String> field) async {
    final picked = await showOptionPicker<String>(
      context,
      title: t.assets.allocationClass,
      selected: _allocationClassId ?? '',
      items: [
        for (final c in _allocationClasses)
          OptionPickerItem(
            value: c.id,
            label: c.name,
            leading: BrandAvatar(
              size: 32,
              background: Color(c.colorValue),
              icon: allocationIcon(c.iconKey),
            ),
          ),
      ],
    );
    if (picked == null) return;
    setState(() => _allocationClassId = picked);
    field.didChange(picked);
  }

  /// Carries kind-specific metadata. Each block is dropped when the kind no
  /// longer matches so stale keys don't linger after a kind change.
  Map<String, String> _buildMetadata() {
    final metadata = Map<String, String>.from(widget.existing?.metadata ?? {});
    _applyTesouroName(metadata);
    _applyFixedIncome(metadata);
    final target = double.tryParse(
          _allocationTargetController.text.trim().replaceAll(',', '.'),
        ) ??
        0;
    return applyAllocation(
      metadata,
      classId: _allocationClassId,
      targetPercent: target,
    );
  }

  void _applyTesouroName(Map<String, String> metadata) {
    final tesouroName = _tesouroNameController.text.trim();
    if (_kind == AssetKind.treasury && tesouroName.isNotEmpty) {
      metadata['tesouroName'] = tesouroName;
    } else {
      metadata.remove('tesouroName');
    }
  }

  void _applyFixedIncome(Map<String, String> metadata) {
    final rate = parseMajor(_fiRateController.text);
    if (_kind == AssetKind.fixedIncome && rate != null) {
      metadata.addAll(FixedIncomeMetadata.write(_fiBasis, rate));
    } else {
      metadata
        ..remove(FixedIncomeMetadata.basisKey)
        ..remove(FixedIncomeMetadata.rateKey);
    }
  }

  Future<Failure?> _persist() {
    final existing = widget.existing;
    return existing == null
        ? widget.cubit.add(
            ticker: _tickerController.text,
            name: _nameController.text,
            kind: _kind,
            market: _market,
            currency: _currency,
            metadata: _buildMetadata(),
          )
        : widget.cubit.edit(
            existing.copyWith(
              ticker: _tickerController.text.trim().toUpperCase(),
              name: _nameController.text.trim(),
              kind: _kind,
              market: _market,
              currency: _currency,
              metadata: _buildMetadata(),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return InvestancoFormSheetScaffold(
      formKey: _formKey,
      title: widget.existing == null ? t.assets.add : t.assets.edit,
      onSubmit: _persist,
      errorText: t.assets.saveError,
      children: [
        InvestancoTextField(
          label: t.assets.ticker,
          controller: _tickerController,
          textCapitalization: TextCapitalization.characters,
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? t.common.required : null,
        ),
        const SizedBox(height: 12),
        InvestancoTextField(
          label: t.assets.name,
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? t.common.required : null,
        ),
        const SizedBox(height: 12),
        InvestancoPickerField(
          label: t.assets.kind,
          value: assetKindLabel(_kind),
          placeholder: t.assets.kind,
          onTap: _pickKind,
          leading: BrandAvatar(
            size: 32,
            background: assetKindColor(_kind),
            icon: assetKindIcon(_kind),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InvestancoPickerField(
                label: t.assets.market,
                value: marketLabel(_market),
                placeholder: t.assets.market,
                onTap: _pickMarket,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InvestancoPickerField(
                label: t.assets.currency,
                value: _currency.code,
                placeholder: t.assets.currency,
                onTap: _pickCurrency,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FormField<String>(
          initialValue: _allocationClassId,
          validator: (v) =>
              (_allocationClasses.isNotEmpty && (v == null || v.isEmpty))
                  ? t.assets.allocationClassRequired
                  : null,
          builder: (field) {
            final selected = _classOf(field.value);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InvestancoPickerField(
                  label: t.assets.allocationClass,
                  value: selected?.name ?? '',
                  placeholder: _allocationClasses.isEmpty
                      ? t.assets.allocationNoClasses
                      : t.assets.allocationClassPlaceholder,
                  isError: field.hasError,
                  leading: selected == null
                      ? null
                      : BrandAvatar(
                          size: 32,
                          background: Color(selected.colorValue),
                          icon: allocationIcon(selected.iconKey),
                        ),
                  onTap: _allocationClasses.isEmpty
                      ? _noop
                      : () => _pickAllocationClass(field),
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      field.errorText!,
                      style: context.textTheme.bodySmall
                          ?.copyWith(color: context.appColors.error),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        InvestancoTextField(
          label: t.assets.allocationTarget,
          controller: _allocationTargetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          suffixText: '%',
          helperText: t.assets.allocationTargetHelp,
          validator: (v) {
            if (_allocationClassId == null) return null;
            final parsed = double.tryParse((v ?? '').replaceAll(',', '.'));
            if (parsed == null || parsed <= 0) {
              return t.assets.allocationTargetRequired;
            }
            return null;
          },
        ),
        if (_kind == AssetKind.treasury) ...[
          const SizedBox(height: 12),
          InvestancoTextField(
            label: t.assets.tesouroName,
            controller: _tesouroNameController,
            textCapitalization: TextCapitalization.words,
            helperText: t.assets.tesouroNameHelp,
          ),
        ],
        if (_kind == AssetKind.fixedIncome) ...[
          const SizedBox(height: 12),
          InvestancoPickerField(
            label: t.assets.fixedIncomeBasis,
            value: fixedIncomeBasisLabel(_fiBasis),
            placeholder: t.assets.fixedIncomeBasis,
            onTap: _pickFiBasis,
          ),
          const SizedBox(height: 12),
          InvestancoTextField(
            label: t.assets.fixedIncomeRate,
            controller: _fiRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            helperText: t.assets.fixedIncomeRateHelp,
          ),
        ],
      ],
    );
  }
}
