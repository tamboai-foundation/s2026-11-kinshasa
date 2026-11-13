import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ngoma/core/widgets/wouanda_loading_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ngoma/core/theme.dart';
import 'package:ngoma/core/providers/user_provider.dart';
import 'package:ngoma/core/superapp/wouanda_permissions.dart';
import 'package:ngoma/core/superapp/wouanda_service_registry.dart';
import 'package:ngoma/core/widgets/auth_required_sheet.dart';
import 'package:ngoma/core/widgets/wouanda_settings_kit.dart';

/// Helper function to execute an action only if the user is authenticated.
/// If the user is an anonymous/guest user, it shows a modern BottomSheet
/// prompting them to log in or create an account, instead of executing the action.
/// This enables the "Lazy Login" pattern.
void executeWithAuth(
  BuildContext context,
  WidgetRef ref,
  VoidCallback action, {
  String actionName = "continuer",
  WouandaAction superAction = WouandaAction.manageService,
}) {
  final sessionStatus = ref.read(userSessionStatusProvider);
  if (sessionStatus == UserSessionStatus.restoring) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Restauration de votre session en cours...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final user = ref.read(userProvider);
  final decision = WouandaPermissions.can(user, superAction);

  if (decision.allowed) {
    action();
    return;
  }

  // No decision from the account authority: read the session again rather
  // than guessing a right.
  if (decision.blocker == WouandaAccessBlocker.unavailable) {
    unawaited(
      ref
          .read(userProvider.notifier)
          .restoreSession(retry: true)
          .then<void>((_) {}, onError: (Object _) {}),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(decision.message),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  if (user.isAnonymous) {
    final returnTo = GoRouterState.of(context).uri.toString();
    AuthRequiredSheet.show(
      context,
      actionName,
      returnTo: returnTo,
      title: decision.title,
      message: decision.message,
    );
  } else {
    AuthRequiredSheet.show(
      context,
      actionName,
      title: decision.title,
      message: decision.message,
      primaryRoute: decision.resolutionRoute,
      primaryLabel: WouandaPermissions.resolutionLabel(decision.blocker),
    );
  }
}

class AuthGate extends ConsumerWidget {
  final Widget child;
  final String actionName;
  final String? returnTo;
  final WouandaAction superAction;

  const AuthGate({
    super.key,
    required this.child,
    this.actionName = 'continuer',
    this.returnTo,
    this.superAction = WouandaAction.manageService,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionStatus = ref.watch(userSessionStatusProvider);
    if (sessionStatus == UserSessionStatus.restoring) {
      return const Scaffold(body: WouandaPageLoading());
    }

    final user = ref.watch(userProvider);
    final decision = WouandaPermissions.can(user, superAction);
    if (decision.allowed) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.getTextPrimary(isDark);
    final mutedColor = AppTheme.getTextSecondary(isDark);
    final service = WouandaServiceRegistry.byId(
      WouandaPermissions.policyFor(superAction).service,
    );

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/hub');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: ServiceArt(service: service, size: 200)),
                    const SizedBox(height: 28),
                    Text(decision.title, style: AppTheme.h1(color: textColor)),
                    const SizedBox(height: 10),
                    Text(
                      decision.message,
                      style: AppTheme.bodyLg(color: mutedColor),
                    ),
                    const SizedBox(height: 28),
                    if (user.isAnonymous)
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 52),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.push(
                              '/auth',
                              extra: {
                                'returnTo':
                                    returnTo ??
                                    GoRouterState.of(context).uri.toString(),
                              },
                            );
                          },
                          icon: const Icon(LucideIcons.logIn, size: 19),
                          label: const Text('Se connecter'),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 52),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (decision.blocker ==
                                WouandaAccessBlocker.unavailable) {
                              unawaited(
                                ref
                                    .read(userProvider.notifier)
                                    .restoreSession(retry: true)
                                    .then<void>((_) {}, onError: (Object _) {}),
                              );
                              return;
                            }
                            context.push(
                              decision.resolutionRoute ?? '/profile',
                            );
                          },
                          icon: const Icon(LucideIcons.badgeCheck, size: 19),
                          label: Text(
                            decision.blocker == WouandaAccessBlocker.role &&
                                    service.id == WouandaServiceId.events
                                ? 'Créer mon organisation'
                                : WouandaPermissions.resolutionLabel(
                                    decision.blocker,
                                  ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/hub'),
                      child: const Text('Continuer a explorer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
