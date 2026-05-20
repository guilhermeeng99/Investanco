import 'package:go_router/go_router.dart';
import 'package:investanco/features/assets/presentation/pages/assets_page.dart';
import 'package:investanco/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:investanco/features/institutions/presentation/pages/institutions_page.dart';
import 'package:investanco/features/transactions/presentation/pages/transactions_page.dart';

/// Declarative route table. Wrapped in a class so it can be injected and tested.
class AppRouter {
  /// Creates the router with the default route table.
  AppRouter();

  /// The configured [GoRouter] passed to `MaterialApp.router`.
  late final GoRouter config = GoRouter(
    initialLocation: DashboardPage.routePath,
    routes: [
      GoRoute(
        path: DashboardPage.routePath,
        name: DashboardPage.routeName,
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: InstitutionsPage.routePath,
        name: InstitutionsPage.routeName,
        builder: (context, state) => const InstitutionsPage(),
      ),
      GoRoute(
        path: AssetsPage.routePath,
        name: AssetsPage.routeName,
        builder: (context, state) => const AssetsPage(),
      ),
      GoRoute(
        path: TransactionsPage.routePath,
        name: TransactionsPage.routeName,
        builder: (context, state) => const TransactionsPage(),
      ),
    ],
  );
}
