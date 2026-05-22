import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:investanco/core/error/failure_message.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/features/allocation/presentation/pages/investments_page.dart';
import 'package:investanco/features/auth/presentation/pages/login_page.dart';
import 'package:investanco/features/startup/presentation/cubit/startup_cubit.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Splash + auth gate. Runs [StartupCubit.initialize] on mount and routes to
/// Investimentos (signed in + synced) or the login carousel (signed out). See
/// `docs/specs/startup.md`.
class StartupPage extends StatefulWidget {
  /// Creates the page.
  const StartupPage({super.key});

  /// Route path.
  static const String routePath = '/startup';

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<StartupCubit>().initialize());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocListener<StartupCubit, StartupState>(
      listener: (context, state) {
        if (state is StartupAuthenticated) {
          context.go(InvestmentsPage.routePath);
        } else if (state is StartupUnauthenticated) {
          context.go(LoginPage.routePath);
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: const Stack(
          fit: StackFit.expand,
          children: [
            _GradientBackdrop(),
            SafeArea(
              child: Column(
                children: [
                  Spacer(),
                  _BrandColumn(),
                  Spacer(),
                  _ProgressBlock(),
                  SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft, slowly-breathing gradient backdrop — a hint of brand tint over the
/// scaffold that gently pulses behind the brand mark.
class _GradientBackdrop extends StatelessWidget {
  const _GradientBackdrop();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.4),
          radius: 1.1,
          colors: [
            colors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
            colors.background,
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 600.ms)
        .then()
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.06, 1.06),
          duration: 4.seconds,
          curve: Curves.easeInOut,
        );
  }
}

class _BrandColumn extends StatelessWidget {
  const _BrandColumn();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Brand mark — gradient tile with the app's initial. Entrance: spring
        // scale + fade. Idle: gentle pulse.
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.32),
                blurRadius: 40,
                spreadRadius: -4,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Center(
            child: Text(
              t.appName.substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 44,
                height: 1,
              ),
            ),
          ),
        )
            .animate()
            .scale(
              duration: 700.ms,
              curve: Curves.easeOutBack,
              begin: const Offset(0.6, 0.6),
              end: const Offset(1, 1),
            )
            .fadeIn(duration: 500.ms)
            .then(delay: 200.ms)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(
              begin: 1,
              end: 1.04,
              duration: 1800.ms,
              curve: Curves.easeInOut,
            ),
        const SizedBox(height: 32),
        Text(
          t.appName,
          style: context.textTheme.displaySmall?.copyWith(
            color: colors.onBackground,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        )
            .animate()
            .fadeIn(delay: 350.ms, duration: 500.ms)
            .slideY(begin: 0.2, end: 0, delay: 350.ms, duration: 500.ms),
        const SizedBox(height: 8),
        Text(
          t.startup.tagline,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.onBackgroundLight,
          ),
        )
            .animate()
            .fadeIn(delay: 550.ms, duration: 500.ms)
            .slideY(begin: 0.3, end: 0, delay: 550.ms, duration: 500.ms),
      ],
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StartupCubit, StartupState>(
      builder: (context, state) {
        if (state is StartupError) {
          return _ErrorBlock(message: failureMessage(state.failure))
              .animate()
              .fadeIn(duration: 300.ms);
        }
        final progress = switch (state) {
          StartupLoading() => state.progress,
          StartupInitial() => 0.0,
          _ => 1.0,
        };

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            children: [
              _ProgressBar(progress: progress),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _stepLabelFor(state),
                  key: ValueKey(_stepLabelFor(state)),
                  textAlign: TextAlign.center,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.appColors.onBackgroundLight,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 750.ms, duration: 500.ms);
      },
    );
  }

  String _stepLabelFor(StartupState state) {
    if (state is StartupLoading) {
      return switch (state.step) {
        StartupStep.checkingAuth => t.startup.stepCheckingAuth,
        StartupStep.syncing => t.startup.stepSyncingData,
      };
    }
    if (state is StartupAuthenticated || state is StartupUnauthenticated) {
      return t.startup.stepReady;
    }
    return t.startup.stepCheckingAuth;
  }
}

/// Thin progress bar that eases to the cubit's value, with a sliding shimmer so
/// the user perceives liveliness even while progress pauses at 0.3 during sync.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Stack(
      children: [
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress.clamp(0.05, 1.0)),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, value, _) {
            return FractionallySizedBox(
              widthFactor: value,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    duration: 1600.ms,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
            );
          },
        ),
      ],
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.triangleExclamation,
                color: colors.error,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.startup.errorTitle,
            style: context.textTheme.titleMedium?.copyWith(
              color: colors.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.onBackgroundLight,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () =>
                unawaited(context.read<StartupCubit>().initialize()),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(t.startup.errorRetry),
          ),
        ],
      ),
    );
  }
}
