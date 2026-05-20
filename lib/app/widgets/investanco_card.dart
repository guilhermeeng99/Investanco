import 'package:flutter/material.dart';

/// Rounded, hairline-bordered surface used as the base building block for
/// every grouped block in the app. Mirrors financo's `FinancoCard`.
///
/// Example:
/// ```dart
/// InvestancoCard(
///   onTap: () => openDetails(),
///   child: Text('PETR4'),
/// )
/// ```
class InvestancoCard extends StatelessWidget {
  /// Creates a card. Pass [onTap] to make it tappable (adds an ink ripple).
  const InvestancoCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  /// Card content.
  final Widget child;

  /// Optional tap handler; when set the card shows an ink ripple.
  final VoidCallback? onTap;

  /// Inner padding around [child].
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: card,
    );
  }
}
