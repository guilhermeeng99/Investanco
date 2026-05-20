import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// "Continue with Google" button for the login carousel. Renders as a soft
/// surface pill matching the app, and shows a spinner while [AuthInProgress].
class GoogleSignInButton extends StatelessWidget {
  /// Creates the button.
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthInProgress;
        return SizedBox(
          height: 52,
          child: Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colors.surfaceVariant),
            ),
            child: InkWell(
              onTap: isLoading
                  ? null
                  : () => context
                      .read<AuthBloc>()
                      .add(const AuthSignInRequested()),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      )
                    else
                      const FaIcon(FontAwesomeIcons.google, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      t.auth.continueWithGoogle,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: colors.onBackground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
