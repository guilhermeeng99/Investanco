import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/app/router/app_router.dart';
import 'package:investanco/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:investanco/features/auth/presentation/pages/login_page.dart';
import 'package:investanco/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:investanco/features/startup/presentation/pages/startup_page.dart';

import '../../harness/factories/auth_user_factory.dart';

void main() {
  final user = authUserFactory();

  group('resolveAuthRedirect (auth gate)', () {
    test('always allows the startup splash', () {
      for (final state in <AuthState>[
        const AuthUnknown(),
        const AuthInProgress(),
        const AuthUnauthenticated(),
        AuthAuthenticated(user),
      ]) {
        expect(
          resolveAuthRedirect(
            authState: state,
            location: StartupPage.routePath,
          ),
          isNull,
        );
      }
    });

    test('sends an unresolved user to the splash to wait', () {
      expect(
        resolveAuthRedirect(
          authState: const AuthUnknown(),
          location: DashboardPage.routePath,
        ),
        StartupPage.routePath,
      );
    });

    test('holds the user in place while a sign-in is in flight', () {
      expect(
        resolveAuthRedirect(
          authState: const AuthInProgress(),
          location: LoginPage.routePath,
        ),
        isNull,
      );
    });

    test('gates a signed-out user to the login carousel', () {
      expect(
        resolveAuthRedirect(
          authState: const AuthUnauthenticated(),
          location: DashboardPage.routePath,
        ),
        LoginPage.routePath,
      );
    });

    test('keeps a signed-out user on the login carousel', () {
      expect(
        resolveAuthRedirect(
          authState: const AuthUnauthenticated(),
          location: LoginPage.routePath,
        ),
        isNull,
      );
    });

    test('routes a freshly signed-in user through the splash to sync', () {
      expect(
        resolveAuthRedirect(
          authState: AuthAuthenticated(user),
          location: LoginPage.routePath,
        ),
        StartupPage.routePath,
      );
    });

    test('lets an authenticated user reach a protected route', () {
      expect(
        resolveAuthRedirect(
          authState: AuthAuthenticated(user),
          location: DashboardPage.routePath,
        ),
        isNull,
      );
    });
  });
}
