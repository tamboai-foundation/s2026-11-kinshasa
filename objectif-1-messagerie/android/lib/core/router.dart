import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ngoma/core/widgets/feature_setup_gate.dart';
import 'package:ngoma/features/auth/auth_screen.dart';
import 'package:ngoma/features/auth/forgot_password_screen.dart';
import 'package:ngoma/features/messaging/messaging.dart';
import 'package:ngoma/features/social/people_screen.dart';
import 'package:ngoma/features/social/profile_screen.dart';
import 'package:ngoma/features/social/social_shell.dart';
import 'package:ngoma/features/social/videos_screen.dart';
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
    // Onglets du Module 1 SI : Messages, Vidéos, Personnes, Profil (barre du bas).
    ShellRoute(
      builder: (context, state, child) => SocialShell(child: child),
      routes: [
        GoRoute(
          path: '/messages',
          builder: (context, state) => const FeatureSetupGate(
            feature: 'chat',
            title: 'Messagerie',
            child: MessagingInboxScreen(),
          ),
        ),
        GoRoute(path: '/videos', builder: (context, state) => const VideosScreen()),
        GoRoute(path: '/people', builder: (context, state) => const PeopleScreen()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      ],
    ),
    // Écrans plein écran, au-dessus de la barre d'onglets.
    GoRoute(
      path: '/messages/:conversationId',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => FeatureSetupGate(
        feature: 'chat',
        title: 'Messagerie',
        child: UnifiedConversationLoader(
          conversationId: state.pathParameters['conversationId']!,
        ),
      ),
    ),
    GoRoute(
      path: '/people/:userId',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => UserDetailScreen(
        userId: int.parse(state.pathParameters['userId']!),
      ),
    ),
  ],
  errorBuilder: (context, state) => const FeatureSetupGate(
    feature: 'chat',
    title: 'Messagerie',
    child: MessagingInboxScreen(),
  ),
);
