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

part 'home_bottom_bar.dart';
part 'home_sidebar.dart';

/// App shell with a persistent navigation across the main sections. Each tab
/// keeps its own navigation state (`StatefulShellRoute`).
///
/// Responsive, mirroring financo: a collapsible side rail on wide layouts
/// (brand + nav items + a profile tile pinned at the bottom — see
/// `home_sidebar.dart`) and a floating pill bottom bar on phones (see
/// `home_bottom_bar.dart`).
class HomeShell extends StatelessWidget {
  /// Creates the shell around [navigationShell].
  const HomeShell({required this.navigationShell, super.key});

  /// The branch navigator provided by `StatefulShellRoute`.
  final StatefulNavigationShell navigationShell;

  static const double _wideBreakpoint = 900;

  /// Index of the profile branch (last shell branch).
  static const int profileIndex = 3;

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

/// The three primary sections (indices 0–2). Profile (index 3) is rendered
/// separately — as a user tile in the rail, a user-icon pill in the bottom bar.
/// Institutions is reached from Profile, not a primary tab (see `app_router.dart`).
List<_NavSpec> _mainDestinations() => [
      _NavSpec(FontAwesomeIcons.chartPie, t.nav.dashboard),
      _NavSpec(FontAwesomeIcons.coins, t.nav.assets),
      _NavSpec(FontAwesomeIcons.rightLeft, t.nav.transactions),
    ];
