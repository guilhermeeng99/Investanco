import 'package:flutter/material.dart';

/// A vertically-spaced list of entity cards with the manage-pages' standard
/// padding (leaving room for the bottom bar / FAB) and 12px gaps. Shared by the
/// institution, asset and transaction lists.
class EntityListView extends StatelessWidget {
  /// Creates the list.
  const EntityListView({
    required this.itemCount,
    required this.itemBuilder,
    super.key,
  });

  /// Number of items.
  final int itemCount;

  /// Builds the card at a given row index.
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: itemBuilder,
    );
  }
}
