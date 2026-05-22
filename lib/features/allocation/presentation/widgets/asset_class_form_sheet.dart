import 'package:flutter/material.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/allocation/domain/entities/asset_class.dart';
import 'package:investanco/features/allocation/presentation/allocation_visuals.dart';
import 'package:investanco/features/allocation/presentation/cubit/allocation_cubit.dart';
import 'package:investanco/features/allocation/presentation/widgets/allocation_pickers.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Add/edit form for an allocation class (name, target %, icon, color). Assets
/// are linked from the asset form, not here. See `docs/specs/allocation.md`.
class AssetClassFormSheet extends StatefulWidget {
  const AssetClassFormSheet._({
    required this.cubit,
    required this.classes,
    this.existing,
  });

  final AllocationCubit cubit;
  final List<AssetClass> classes;
  final AssetClass? existing;

  /// Opens the form. [existing] edits an existing class.
  static Future<void> show(
    BuildContext context,
    AllocationCubit cubit, {
    required List<AssetClass> classes,
    AssetClass? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AssetClassFormSheet._(
        cubit: cubit,
        classes: classes,
        existing: existing,
      ),
    );
  }

  @override
  State<AssetClassFormSheet> createState() => _AssetClassFormSheetState();
}

class _AssetClassFormSheetState extends State<AssetClassFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late String _iconKey;
  late int _colorValue;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _targetController = TextEditingController(
      text: existing == null ? '' : _formatTarget(existing.targetPercent),
    );
    _iconKey = existing?.iconKey ?? defaultAllocationIconKey;
    _colorValue = existing?.colorValue ??
        defaultAllocationColor(widget.classes.length);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  String _formatTarget(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';

  @override
  Widget build(BuildContext context) {
    return InvestancoFormSheetScaffold(
      formKey: _formKey,
      title: _isEditing ? t.allocation.editClassTitle : t.allocation.newClassTitle,
      errorText: t.allocation.saveError,
      onSubmit: _persist,
      children: [
        InvestancoTextField(
          label: t.allocation.classNameLabel,
          controller: _nameController,
          hintText: t.allocation.classNameHint,
          textCapitalization: TextCapitalization.words,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? t.common.required : null,
        ),
        const SizedBox(height: 12),
        InvestancoTextField(
          label: t.allocation.targetPercentLabel,
          controller: _targetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          suffixText: '%',
          helperText: t.allocation.targetHelper,
        ),
        const SizedBox(height: 12),
        InvestancoPickerField(
          label: t.allocation.classIcon,
          value: t.allocation.classIcon,
          placeholder: t.allocation.classIcon,
          leading: _IconDot(iconKey: _iconKey, colorValue: _colorValue),
          onTap: _pickIcon,
        ),
        const SizedBox(height: 12),
        InvestancoPickerField(
          label: t.allocation.classColor,
          value: t.allocation.classColor,
          placeholder: t.allocation.classColor,
          leading: _ColorDot(colorValue: _colorValue),
          onTap: _pickColor,
        ),
        if (_isEditing) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(t.common.delete),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickIcon() async {
    final picked = await showAllocationIconPicker(context, selected: _iconKey);
    if (picked != null) setState(() => _iconKey = picked);
  }

  Future<void> _pickColor() async {
    final picked = await showAllocationColorPicker(context, selected: _colorValue);
    if (picked != null) setState(() => _colorValue = picked);
  }

  Future<void> _confirmDelete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final confirmed = await showInvestancoConfirmDialog(
      context,
      title: t.allocation.deleteClassTitle,
      message: t.allocation.deleteClassConfirm,
      confirmLabel: t.common.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await widget.cubit.deleteClass(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<Failure?> _persist() async {
    final name = _nameController.text.trim();
    final target =
        double.tryParse(_targetController.text.trim().replaceAll(',', '.')) ?? 0;

    final existing = widget.existing;
    final result = existing == null
        ? await widget.cubit.createClass(
            name: name,
            targetPercent: target,
            iconKey: _iconKey,
            colorValue: _colorValue,
          )
        : await widget.cubit.saveClass(
            existing.copyWith(
              name: name,
              targetPercent: target,
              iconKey: _iconKey,
              colorValue: _colorValue,
            ),
          );
    return result.fold((failure) => failure, (_) => null);
  }
}

class _IconDot extends StatelessWidget {
  const _IconDot({required this.iconKey, required this.colorValue});

  final String iconKey;
  final int colorValue;

  @override
  Widget build(BuildContext context) => BrandAvatar(
        size: 32,
        background: Color(colorValue),
        icon: allocationIcon(iconKey),
      );
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.colorValue});

  final int colorValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: Color(colorValue), shape: BoxShape.circle),
    );
  }
}
