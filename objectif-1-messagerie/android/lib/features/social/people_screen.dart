import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ngoma/core/platform/social/social_bridge.dart';
import 'package:ngoma/core/platform/messaging/messaging_bridge_provider.dart';
import 'package:ngoma_design/ngoma_design.dart';

import 'social_widgets.dart';

/// Gestion des utilisateurs (M1 SI, module 1) : voir les utilisateurs, rechercher, ouvrir un profil.
class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final bridge = ref.watch(usersBridgeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Personnes')),
      body: ListenableBuilder(
        listenable: bridge,
        builder: (context, _) {
          final users = bridge.users(_query);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un utilisateur',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${users.length} utilisateur${users.length > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              Expanded(
                child: users.isEmpty
                    ? const Center(child: Text('Aucun utilisateur ne correspond.'))
                    : ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final u = users[i];
                          return ListTile(
                            leading: SocialAvatar(name: u.name),
                            title: Text(
                              u.name + (u.id == bridge.me.id ? ' (vous)' : ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              u.bio.isEmpty ? 'Pas de description' : u.bio,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => context.push('/people/${u.id}'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Profil d'une personne : description, vidéos publiées, bouton « Écrire un message ».
class UserDetailScreen extends ConsumerWidget {
  final int userId;

  const UserDetailScreen({super.key, required this.userId});

  Future<void> _write(BuildContext context, WidgetRef ref, SocialUser user) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final conversation = await ref
          .read(messagingBridgeProvider)
          .openDirectConversation(user.id);
      router.push('/messages/${conversation.id}');
    } on PlatformException {
      messenger.showSnackBar(
        const SnackBar(content: Text("Cette personne n'est pas joignable pour l'instant.")),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersBridgeProvider);
    final videos = ref.watch(videoBridgeProvider);
    return ListenableBuilder(
      listenable: Listenable.merge([users, videos]),
      builder: (context, _) {
        final user = users.user(userId);
        if (user == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Utilisateur introuvable.')),
          );
        }
        final posts = videos.userPosts(user.id);
        return Scaffold(
          appBar: AppBar(title: Text(user.name)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Column(
                children: [
                  SocialAvatar(name: user.name, size: 84),
                  const SizedBox(height: 10),
                  Text(
                    user.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.bio.isEmpty ? 'Pas de description' : user.bio,
                    textAlign: TextAlign.center,
                  ),
                  if (user.joinedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Membre depuis le ${DateFormat('dd/MM/yyyy').format(user.joinedAt!)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  if (user.id != users.me.id)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: NgomaColors.brand),
                        onPressed: () => _write(context, ref, user),
                        child: const Text('Écrire un message'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Vidéos (${posts.length})', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (posts.isEmpty)
                const Text('Aucune vidéo publiée.')
              else
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 9 / 14,
                  children: [for (final p in posts) PostMiniature(post: p)],
                ),
            ],
          ),
        );
      },
    );
  }
}
