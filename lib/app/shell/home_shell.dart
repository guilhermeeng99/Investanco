import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:investanco/app/theme/app_colors.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/features/auth/domain/entities/auth_user.dart';
import 'package:investanco/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// App shell with a persistent navigation across the main sections. Each tab
/// keeps its own navigation state (`StatefulShellRoute`).
///
/// Responsive, mirroring financo: a collapsible side rail on wide layouts
/// (brand + nav items + a profile tile pinned at the bottom) and a floating
/// pill bottom bar on phones.
class HomeShell extends StatelessWidget {
  /// Creates the shell around [navigationShell].
  const HomeShell({required this.navigationShell, super.key});

  /// The branch navigator provided by `StatefulShellRoute`.
  final StatefulNavigationShell navigationShell;

  static const double _wideBreakpoint = 900;

  /// Index of the profile branch (last shell branch).
  static const int profileIndex = 4;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              currentIndex: navigationShell.currentIndex,
              onSelected: _goBranch,
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _PillBottomBar(
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

/// The four primary sections (indices 0–3). Profile (index 4) is rendered
/// separately — as a user tile in the rail, a user-icon pill in the bottom bar.
List<_NavSpec> _mainDestinations() => [
      _NavSpec(FontAwesomeIcons.chartPie, t.nav.dashboard),
      _NavSpec(FontAwesomeIcons.buildingColumns, t.nav.institutions),
      _NavSpec(FontAwesomeIcons.coins, t.nav.assets),
      _NavSpec(FontAwesomeIcons.rightLeft, t.nav.transactions),
    ];

const _railCollapsedWidth = 80.0;
const _railExpandedWidth = 240.0;
const _railAnimDuration = Duration(milliseconds: 240);
const Curve _railAnimCurve = Curves.easeOutCubic;

/// Collapsible side rail: brand + collapse toggle, primary nav items with an
/// active left-accent bar, and a profile tile pinned at the bottom.
class _Sidebar extends StatefulWidget {
  const _Sidebar({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  bool _expanded = false;

  void _toggle() {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _expanded = !_expanded);
  }

  void _select(int index) {
    unawaited(HapticFeedback.selectionClick());
    widget.onSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final destinations = _mainDestinations();
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return AnimatedContainer(
      duration: _railAnimDuration,
      curve: _railAnimCurve,
      width: _expanded ? _railExpandedWidth : _railCollapsedWidth,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          right: BorderSide(
            color: colors.surfaceVariant.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BrandRow(expanded: _expanded, onToggle: _toggle),
              const SizedBox(height: 24),
              for (var i = 0; i < destinations.length; i++)
                _RailItem(
                  spec: destinations[i],
                  expanded: _expanded,
                  isActive: widget.currentIndex == i,
                  onTap: () => _select(i),
                ),
              const Spacer(),
              _ProfileTile(
                expanded: _expanded,
                user: user,
                isActive: widget.currentIndex == HomeShell.profileIndex,
                onTap: () => _select(HomeShell.profileIndex),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox(width: 52, child: Center(child: _BrandMark(onTap: onToggle))),
          if (expanded)
            Expanded(
              child: Text(
                t.appName,
                style: context.textTheme.titleMedium?.copyWith(
                  color: colors.onBackground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              t.appName.substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.spec,
    required this.expanded,
    required this.isActive,
    required this.onTap,
  });

  final _NavSpec spec;
  final bool expanded;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final foreground = isActive ? colors.primary : colors.onBackgroundLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Stack(
        children: [
          if (isActive)
            Positioned(
              left: 0,
              top: 10,
              bottom: 10,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Material(
            color: isActive
                ? colors.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Center(
                        child: FaIcon(spec.icon, size: 17, color: foreground),
                      ),
                    ),
                    if (expanded)
                      Expanded(
                        child: Text(
                          spec.label,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: isActive
                                ? colors.onBackground
                                : colors.onBackgroundLight,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.expanded,
    required this.user,
    required this.isActive,
    required this.onTap,
  });

  final bool expanded;
  final AuthUser? user;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: isActive
            ? colors.primary.withValues(alpha: 0.10)
            : colors.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _UserAvatar(user: user),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user?.name.isNotEmpty ?? false
                              ? user!.name
                              : t.nav.profile,
                          style: context.textTheme.labelLarge?.copyWith(
                            color: colors.onBackground,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          t.nav.profile,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.onBackgroundLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  FaIcon(
                    FontAwesomeIcons.chevronRight,
                    size: 11,
                    color: colors.onBackgroundLight,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final photoUrl = user?.photoUrl;
    final initial = _initialOf(user?.name);
    return SizedBox(
      width: 36,
      height: 36,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: photoUrl != null && photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _initialFallback(colors, initial),
              )
            : _initialFallback(colors, initial),
      ),
    );
  }

  Widget _initialFallback(AppColorsData colors, String initial) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.18),
            colors.primaryLight.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  static String _initialOf(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    return name.trim().substring(0, 1).toUpperCase();
  }
}

/// Floating pill bottom bar: the active item expands into a labelled pill,
/// inactive items stay as compact icons. Profile is the trailing user-icon item.
class _PillBottomBar extends StatelessWidget {
  const _PillBottomBar({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;
    final destinations = [
      ..._mainDestinations(),
      _NavSpec(FontAwesomeIcons.user, t.nav.profile),
    ];

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
