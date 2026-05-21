import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/institutions/presentation/cubit/institutions_cubit.dart';
import 'package:investanco/features/institutions/presentation/cubit/institutions_state.dart';
import 'package:investanco/features/institutions/presentation/institution_labels.dart';
import 'package:investanco/features/institutions/presentation/institution_visuals.dart';
import 'package:investanco/features/institutions/presentation/widgets/institution_form_sheet.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Manage institutions (Nubank, Avenue, …). See `docs/specs/institutions.md`.
class InstitutionsPage extends StatelessWidget {
  /// Creates the page.
  const InstitutionsPage({super.key});

  /// Route path.
  static const String routePath = '/institutions';

  /// Route name.
  static const String routeName = 'institutions';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InstitutionsCubit>(
      create: (_) => sl<InstitutionsCubit>(),
      child: const _InstitutionsView(),
    );
  }
}

class _InstitutionsView extends StatelessWidget {
  const _InstitutionsView();

  Future<void> _confirmDelete(
    BuildContext context,
    InstitutionsCubit cubit,
    Institution institution,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: t.institutions.edit,
      message: t.institutions.deleteConfirm,
    );
    if (!confirmed || !context.mounted) return;

    final failure = await cubit.remove(institution.id);
    if (failure is InUseFailure && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.institutions.inUseError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InstitutionsCubit>();
    return Scaffold(
      appBar: InvestancoAppBar(
        title: t.institutions.title,
        showBack: true,
        actions: [
          IconButton(
            tooltip: t.institutions.add,
            onPressed: () => InstitutionFormSheet.show(context, cubit),
            icon: const FaIcon(FontAwesomeIcons.plus, size: 18),
          ),
        ],
      ),
      body: BlocBuilder<InstitutionsCubit, InstitutionsState>(
        builder: (context, state) {
          return switch (state) {
            InstitutionsLoading() => const LoadingShimmerList(),
            InstitutionsError() => ErrorView(
                message: t.institutions.saveError,
                onRetry: () {},
              ),
            InstitutionsLoaded(:final institutions)
                when institutions.isEmpty =>
              EmptyState(
                icon: FontAwesomeIcons.buildingColumns,
                title: t.institutions.title,
                message: t.institutions.empty,
                actionLabel: t.institutions.add,
                onAction: () => InstitutionFormSheet.show(context, cubit),
              ),
            InstitutionsLoaded(:final institutions) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: institutions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _InstitutionTile(
                  institution: institutions[index],
                  onTap: () => InstitutionFormSheet.show(
                    context,
                    cubit,
                    existing: institutions[index],
                  ),
                  onDelete: () =>
                      _confirmDelete(context, cubit, institutions[index]),
                ),
              ),
          };
        },
      ),
    );
  }
}

class _InstitutionTile extends StatelessWidget {
  const _InstitutionTile({
    required this.institution,
    required this.onTap,
    required this.onDelete,
  });

  final Institution institution;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InvestancoCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          BrandAvatar(
            background: institutionKindColor(institution.kind),
            icon: institutionKindIcon(institution.kind),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(institution.name, style: context.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${institutionKindLabel(institution.kind)}  ·  '
                  '${institution.currency.code}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onBackgroundLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: t.common.delete,
            icon: FaIcon(
              FontAwesomeIcons.trashCan,
              size: 16,
              color: colors.onBackgroundLight,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
