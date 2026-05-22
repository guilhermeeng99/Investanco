import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:investanco/app/shell/home_shell.dart';
import 'package:investanco/features/allocation/presentation/pages/asset_class_detail_page.dart';
import 'package:investanco/features/allocation/presentation/pages/investments_page.dart';
import 'package:investanco/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:investanco/features/auth/presentation/pages/login_page.dart';
import 'package:investanco/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:investanco/features/institutions/presentation/pages/institutions_page.dart';
import 'package:investanco/features/portfolio_import/domain/asset_import_models.dart';
import 'package:investanco/features/portfolio_import/domain/transaction_import_models.dart';
import 'package:investanco/features/portfolio_import/presentation/pages/assets_import_preview_page.dart';
import 'package:investanco/features/portfolio_import/presentation/pages/transactions_import_preview_page.dart';
import 'package:investanco/features/profile/presentation/pages/profile_page.dart';
import 'package:investanco/features/records/presentation/pages/records_page.dart';
import 'package:investanco/features/startup/presentation/pages/startup_page.dart';

/// Declarative route table gated behind Google sign-in. A redirect (driven by
/// [AuthBloc]) keeps unauthenticated users on the startup/login screens; once
/// signed in, the stateful bottom-navigation shell hosts the main sections. See
/// `docs/specs/auth.md`.
class AppRouter {
  /// Creates the router over the app-wide [AuthBloc].
  AppRouter(this._authBloc);

  final AuthBloc _authBloc;

  /// The configured [GoRouter] passed to `MaterialApp.router`.
  late final GoRouter config = GoRouter(
    initialLocation: StartupPage.routePath,
    refreshListenable: GoRouterRefreshStream(_authBloc.stream),
    redirect: (_, state) => resolveAuthRedirect(
      authState: _authBloc.state,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: StartupPage.routePath,
        builder: (context, state) => const StartupPage(),
      ),
      GoRoute(
        path: LoginPage.routePath,
        builder: (context, state) => const LoginPage(),
      ),
      // Institutions is a pushed sub-page (reached from Profile → "Your data",
      // and the dashboard empty-state CTA), not a primary tab — it changes too
      // rarely to earn shell real estate. Lives on the root navigator so it
      // covers the shell with a back chip. See `docs/specs/institutions.md`.
      GoRoute(
        path: InstitutionsPage.routePath,
        builder: (context, state) => const InstitutionsPage(),
      ),
      // Bulk-import review screens, pushed (with the parsed preview as `extra`)
      // from the Assets / Transactions import flows. Root-level so they cover
      // the shell during the focused review step. See `docs/specs/csv_import.md`.
      GoRoute(
        path: AssetsImportPreviewPage.routePath,
        builder: (context, state) {
          final preview = state.extra;
          return AssetsImportPreviewPage(
            preview: preview is AssetImportPreview
                ? preview
                : const AssetImportPreview(rows: []),
          );
        },
      ),
      GoRoute(
        path: TransactionsImportPreviewPage.routePath,
        builder: (context, state) {
          final preview = state.extra;
          return TransactionsImportPreviewPage(
            preview: preview is TransactionImportPreview
                ? preview
                : const TransactionImportPreview(rows: []),
          );
        },
      ),
      // Tab order (must match `_mainDestinations()` in `home_shell.dart`):
      // Investimentos is the landing tab (cold start → `/allocation`, see
      // `startup.md`); Carteira is second; the unified Registros tab merges the
      // former Assets + Transactions tabs (see `records.md`).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          // 0 — Investimentos (allocation home + nested class detail).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: InvestmentsPage.routePath,
                builder: (context, state) => const InvestmentsPage(),
                routes: [
                  // Class detail nested under the branch so the nav shell stays
                  // visible; the class id is passed via `extra`.
                  GoRoute(
                    path: AssetClassDetailPage.routePath,
                    builder: (context, state) {
                      final id = state.extra;
                      return AssetClassDetailPage(
                        classId: id is String ? id : '',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // 1 — Carteira (consolidated portfolio).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: DashboardPage.routePath,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          // 2 — Registros (unified Assets + Transactions). The `tab` query param
          // deep-links to a sub-view (dashboard onboarding CTAs use it).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RecordsPage.routePath,
                builder: (context, state) => RecordsPage(
                  initialTab: recordsTabFromQuery(
                    state.uri.queryParameters['tab'],
                  ),
                ),
              ),
            ],
          ),
          // 3 — Profile.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: ProfilePage.routePath,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Pure auth-gate decision, extracted so it can be unit-tested without pumping a
/// router. Returns the path to redirect to, or null to stay. See the table in
/// `docs/specs/auth.md`.
String? resolveAuthRedirect({
  required AuthState authState,
  required String location,
}) {
  final onStartup = location == StartupPage.routePath;
  final onLogin = location == LoginPage.routePath;

  // The splash is always reachable — it drives the gate itself.
  if (onStartup) return null;
  // A sign-in flow is open; hold the user on the login page until it resolves.
  if (authState is AuthInProgress) return null;
  // Auth not resolved yet → wait on the splash.
  if (authState is AuthUnknown) return StartupPage.routePath;
  // Signed out → the login carousel.
  if (authState is AuthUnauthenticated) {
    return onLogin ? null : LoginPage.routePath;
  }
  // Signed in but still on login → go through the splash so the sync runs first.
  if (authState is AuthAuthenticated && onLogin) return StartupPage.routePath;
  return null;
}

/// Bridges a stream to `GoRouter.refreshListenable`: notifies the router to
/// re-evaluate [resolveAuthRedirect] whenever [AuthBloc] emits.
class GoRouterRefreshStream extends ChangeNotifier {
  /// Subscribes to [stream] and notifies listeners on each event.
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
