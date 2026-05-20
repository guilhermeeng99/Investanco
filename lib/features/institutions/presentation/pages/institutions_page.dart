import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/institutions/presentation/cubit/institutions_cubit.dart';
import 'package:investanco/features/institutions/presentation/cubit/institutions_state.dart';
import 'package:investanco/features/institutions/presentation/institution_labels.dart';
import 'package:investanco/features/institutions/presentation/widgets/institution_form_sheet.dart';
import 'package:investanco/gen/strings.g.dart';

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(t.institutions.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

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
      appBar: AppBar(title: Text(t.institutions.title)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => InstitutionFormSheet.show(context, cubit),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<InstitutionsCubit, InstitutionsState>(
        builder: (context, state) {
          return switch (state) {
            InstitutionsLoading() =>
              const Center(child: CircularProgressIndicator()),
            InstitutionsError() => Center(child: Text(t.institutions.saveError)),
            InstitutionsLoaded(:final institutions)
                when institutions.isEmpty =>
              const _EmptyState(),
            InstitutionsLoaded(:final institutions) => ListView.builder(
                itemCount: institutions.length,
                itemBuilder: (context, index) {
                  final institution = institutions[index];
                  return ListTile(
                    leading: const Icon(Icons.account_balance_outlined),
                    title: Text(institution.name),
                    subtitle: Text(
                      '${institutionKindLabel(institution.kind)} · '
                      '${institution.currency.code}',
                    ),
                    onTap: () => InstitutionFormSheet.show(
                      context,
                      cubit,
                      existing: institution,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          _confirmDelete(context, cubit, institution),
                    ),
                  );
                },
              ),
          };
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          t.institutions.empty,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
