import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ngoma/core/widgets/feature_setup_gate.dart';
import 'package:ngoma/features/auth/auth_screen.dart';
import 'package:ngoma/features/auth/forgot_password_screen.dart';
import 'package:ngoma/features/messaging/messaging.dart';
import 'package:ngoma/features/splash/splash_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'rootNavigator',
);

/// Chat lab: splash/login → chat setup → inbox → conversation.
final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => SplashScreen()),
    GoRoute(path: '/onboarding', redirect: (_, _) => '/auth'),
    GoRoute(path: '/hub', redirect: (_, _) => '/messages'),
    GoRoute(
      path: '/auth',
      builder: (context, state) {
        final rawExtra = state.extra;
        final extra = rawExtra is Map<String, dynamic> ? rawExtra : null;
        return AuthScreen(
          returnTo: extra?['returnTo'] as String?,
          returnToPrevious: extra?['returnToPrevious'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/messages',
      builder: (context, state) => const FeatureSetupGate(
        feature: 'chat',
        title: 'Messagerie',
        child: MessagingInboxScreen(),
      ),
      routes: [
        GoRoute(
          path: ':conversationId',
          builder: (context, state) => FeatureSetupGate(
            feature: 'chat',
            title: 'Messagerie',
            child: UnifiedConversationLoader(
              conversationId: state.pathParameters['conversationId']!,
            ),
          ),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => const FeatureSetupGate(
    feature: 'chat',
    title: 'Messagerie',
    child: MessagingInboxScreen(),
  ),
);
