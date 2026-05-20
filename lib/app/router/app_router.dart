import 'package:go_router/go_router.dart';
import 'package:investanco/features/dashboard/presentation/pages/dashboard_page.dart';

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
    ],
  );
}
