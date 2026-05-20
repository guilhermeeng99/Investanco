import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investanco/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:investanco/features/institutions/presentation/pages/institutions_page.dart';
import 'package:investanco/gen/strings.g.dart';

/// App navigation drawer. Entries are added as features land (see ROADMAP.md).
class AppDrawer extends StatelessWidget {
  /// Creates the drawer.
  const AppDrawer({super.key});

  void _go(BuildContext context, String path) {
    Navigator.pop(context);
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  t.appName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart_outline),
              title: Text(t.nav.dashboard),
              onTap: () => _go(context, DashboardPage.routePath),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: Text(t.nav.institutions),
              onTap: () => _go(context, InstitutionsPage.routePath),
            ),
          ],
        ),
      ),
    );
  }
}
