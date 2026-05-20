import 'package:flutter/material.dart';
import 'package:investanco/app/widgets/app_drawer.dart';
import 'package:investanco/gen/strings.g.dart';

/// Portfolio home. Placeholder shell until Phase 1–3 wire real data.
///
/// See `docs/specs/dashboard.md` for the target behavior.
class DashboardPage extends StatelessWidget {
  /// Creates the dashboard page.
  const DashboardPage({super.key});

  /// Route path used by the router.
  static const String routePath = '/dashboard';

  /// Named route identifier.
  static const String routeName = 'dashboard';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.dashboard.title)),
      drawer: const AppDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                t.dashboard.empty,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
