import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ngoma_design/ngoma_design.dart';

/// Cadre de l'application : barre d'onglets en bas (Messages, Vidéos, Personnes, Profil) et l'écran actif.
class SocialShell extends StatelessWidget {
  final Widget child;

  const SocialShell({super.key, required this.child});

  static const _tabs = <(String, String, IconData)>[
    ('/messages', 'Messages', Icons.chat_bubble_outline),
    ('/videos', 'Vidéos', Icons.play_circle_outline),
    ('/people', 'Personnes', Icons.people_outline),
    ('/profile', 'Profil', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final index = _tabs.indexWhere((t) => path.startsWith(t.$1));
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        indicatorColor: NgomaColors.brand50,
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(icon: Icon(t.$3), label: t.$2),
        ],
      ),
    );
  }
}
