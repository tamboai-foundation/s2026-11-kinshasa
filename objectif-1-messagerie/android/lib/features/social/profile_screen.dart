import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ngoma/core/platform/social/social_bridge.dart';
import 'package:ngoma/core/providers/user_provider.dart';
import 'package:ngoma_design/ngoma_design.dart';

import 'social_widgets.dart';

/// Mon profil (M1 SI, module 1) : modifier mon nom et ma description, voir mes vidéos, me déconnecter, supprimer mon compte.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final me = ref.read(usersBridgeProvider).me;
    _name = TextEditingController(text: me.name);
    _bio = TextEditingController(text: me.bio);
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await ref.read(userProvider.notifier).logout();
    if (mounted) context.go('/auth');
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(usersBridgeProvider).deleteAccount();
    await _logout();
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersBridgeProvider);
    final videos = ref.watch(videoBridgeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListenableBuilder(
        listenable: Listenable.merge([users, videos]),
        builder: (context, _) {
          final me = users.me;
          final mine = videos.userPosts(me.id);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  SocialAvatar(name: me.name, size: 72),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(me.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                        Text('${mine.length} vidéo${mine.length > 1 ? 's' : ''} publiée${mine.length > 1 ? 's' : ''}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nom')),
              const SizedBox(height: 12),
              TextField(
                controller: _bio,
                minLines: 3,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: NgomaColors.brand,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  users.updateMyProfile(name: _name.text, bio: _bio.text);
                  setState(() => _saved = true);
                },
                child: Text(_saved ? 'Enregistré ✓' : 'Enregistrer'),
              ),
              const SizedBox(height: 24),
              const Text('Mes vidéos', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (mine.isEmpty)
                const Text("Vous n'avez rien publié pour l'instant.")
              else
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 9 / 14,
                  children: [for (final p in mine) PostMiniature(post: p)],
                ),
              const SizedBox(height: 24),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: _logout,
                child: const Text('Se déconnecter'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: Colors.red.shade700,
                ),
                onPressed: _delete,
                child: const Text('Supprimer mon compte'),
              ),
            ],
          );
        },
      ),
    );
  }
}
