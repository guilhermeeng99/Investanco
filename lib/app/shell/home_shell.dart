import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// App shell with a persistent navigation across the main sections. Each tab
/// keeps its own navigation state (`StatefulShellRoute`).
///
/// Responsive: a floating pill bottom bar on phones, a side
/// [NavigationRail] on wide layouts (web/desktop), mirroring financo's
/// adaptive shell.
class HomeShell extends StatelessWidget {
  /// Creates the shell around [navigationShell].
  const HomeShell({required this.navigationShell, super.key});

  /// The branch navigator provided by `StatefulShellRoute`.
  final StatefulNavigationShell navigationShell;

  static const double _wideBreakpoint = 900;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  List<_NavSpec> _destinations() => [
        _NavSpec(FontAwesomeIcons.chartPie, t.nav.dashboard),
        _NavSpec(FontAwesomeIcons.buildingColumns, t.nav.institutions),
        _NavSpec(FontAwesomeIcons.coins, t.nav.assets),
        _NavSpec(FontAwesomeIcons.rightLeft, t.nav.transactions),
        _NavSpec(FontAwesomeIcons.gear, t.nav.settings),
      ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    final destinations = _destinations();

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _SideRail(
              destinations: destinations,
              currentIndex: navigationShell.currentIndex,
              onSelected: _goBranch,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _PillBottomBar(
        destinations: destinations,
        currentIndex: navigationShell.currentIndex,
        onSelected: _goBranch,
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec(this.icon, this.label);
  final FaIconData icon;
  final String label;
}

/// Floating pill bottom bar: the active item expands into a labelled pill,
/// inactive items stay as compact icons.
class _PillBottomBar extends StatelessWidget {
  const _PillBottomBar({
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<_NavSpec> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void onTap(int i) {
      if (i != currentIndex) unawaited(HapticFeedback.selectionClick());
      onSelected(i);
    }

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: colors.surfaceVariant),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < destinations.length; i++)
              _PillItem(
                spec: destinations[i],
                isActive: i == currentIndex,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _PillItem extends StatelessWidget {
  const _PillItem({
    required this.spec,
    required this.isActive,
    required this.onTap,
  });

  final _NavSpec spec;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final foreground = isActive ? colors.primary : colors.onBackgroundLight;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? 16 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? colors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(spec.icon, size: 16, color: foreground),
              ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  widthFactor: isActive ? 1 : 0,
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      spec.label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      softWrap: false,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Side navigation rail for wide layouts.
class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<_NavSpec> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      backgroundColor: colors.surface,
      indicatorColor: colors.primary.withValues(alpha: 0.14),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: FaIcon(FontAwesomeIcons.seedling, color: colors.primary),
      ),
      destinations: [
        for (final spec in destinations)
          NavigationRailDestination(
            icon: FaIcon(spec.icon, size: 18, color: colors.onBackgroundLight),
            selectedIcon: FaIcon(spec.icon, size: 18, color: colors.primary),
            label: Text(spec.label),
          ),
      ],
    );
  }
}
