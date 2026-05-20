import 'package:go_router/go_router.dart';
import 'package:investanco/app/shell/home_shell.dart';
import 'package:investanco/features/assets/presentation/pages/assets_page.dart';
import 'package:investanco/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:investanco/features/institutions/presentation/pages/institutions_page.dart';
import 'package:investanco/features/profile/presentation/pages/settings_page.dart';
import 'package:investanco/features/transactions/presentation/pages/transactions_page.dart';

/// Declarative route table with a stateful bottom-navigation shell, so the main
/// sections are always reachable and keep their own state.
class AppRouter {
  /// Creates the router.
  AppRouter();

  /// The configured [GoRouter] passed to `MaterialApp.router`.
  late final GoRouter config = GoRouter(
    initialLocation: DashboardPage.routePath,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: DashboardPage.routePath,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: InstitutionsPage.routePath,
                builder: (context, state) => const InstitutionsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AssetsPage.routePath,
                builder: (context, state) => const AssetsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: TransactionsPage.routePath,
                builder: (context, state) => const TransactionsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: SettingsPage.routePath,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
