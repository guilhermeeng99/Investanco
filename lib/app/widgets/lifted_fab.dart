import 'package:flutter/material.dart';

/// Lifts a [FloatingActionButton] above the floating pill bottom bar shown on
/// narrow layouts. Primary-tab pages have their own `Scaffold` nested in the
/// shell body, so without this the FAB sits at the very bottom and the bar (the
/// shell's `bottomNavigationBar`, painted on top) covers it. Wide layouts use a
/// side rail with no bottom bar, so no lift is applied. Mirrors financo.
class LiftedFab extends StatelessWidget {
  /// Wraps [child] (typically a FAB).
  const LiftedFab({required this.child, super.key});

  /// The button to lift.
  final Widget child;

  // Pill bar footprint ≈ 12 + 64 + safe area; lift just above it.
  static const double _liftAmount = 80;

  // Matches `HomeShell._wideBreakpoint`: below it the bottom bar is shown.
  static const double _wideBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    if (isWide) return child;
    return Padding(
      padding: const EdgeInsets.only(bottom: _liftAmount),
      child: child,
    );
  }
}
