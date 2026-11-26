import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ngoma/core/platform/social/social_bridge.dart';
import 'package:video_player/video_player.dart';
import 'package:ngoma_design/ngoma_design.dart';

import 'social_widgets.dart';

/// Fil de vidéos façon TikTok (M1 SI, module 3) : défilement vertical page par page, publier, aimer, commenter,
/// modifier et supprimer ses vidéos. Une vidéo publiée depuis la galerie est lue ; sans fichier, carte colorée.
class VideosScreen extends ConsumerStatefulWidget {
  const VideosScreen({super.key});

  @override
  ConsumerState<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends ConsumerState<VideosScreen> {
  bool _mineOnly = false;
  int _page = 0;
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const PublishScreen()),
    );
    if (published == true && mounted) {
      setState(() => _mineOnly = false);
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bridge = ref.watch(videoBridgeProvider);
    final users = ref.watch(usersBridgeProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: Listenable.merge([bridge, users]),
        builder: (context, _) {
          final posts = _mineOnly ? bridge.userPosts(users.me.id) : bridge.feed();
          return Stack(
            children: [
              if (posts.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _mineOnly ? "Vous n'avez rien publié pour l'instant." : 'Aucune vidéo pour le moment.',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _publish, child: const Text('Publier une vidéo')),
                    ],
                  ),
                )
              else
                PageView.builder(
                  controller: _controller,
                  scrollDirection: Axis.vertical,
                  itemCount: posts.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => _VideoPage(
                    post: posts[i],
                    active: i == _page,
                    bridge: bridge,
                    users: users,
                  ),
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      const SizedBox(width: 90),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _TopTab(label: 'Pour vous', on: !_mineOnly, onTap: () => setState(() => _mineOnly = false)),
                            const SizedBox(width: 18),
                            _TopTab(label: 'Mes vidéos', on: _mineOnly, onTap: () => setState(() => _mineOnly = true)),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: NgomaColors.brand,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: const Size(0, 34),
                        ),
                        onPressed: _publish,
                        child: const Text('+ Publier', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;

  const _TopTab({required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Text(
      label,
      style: TextStyle(
        color: Colors.white.withValues(alpha: on ? 1 : 0.6),
        fontWeight: FontWeight.w700,
        fontSize: 15,
        decoration: on ? TextDecoration.underline : null,
        decorationColor: Colors.white,
      ),
    ),
  );
}

class _VideoPage extends StatelessWidget {
  final VideoPost post;
  final bool active;
  final VideoBridge bridge;
  final UsersBridge users;

  const _VideoPage({
    required this.post,
    required this.active,
    required this.bridge,
    required this.users,
  });

  Future<void> _edit(BuildContext context) async {
    final controller = TextEditingController(text: post.caption);
    final caption = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la légende'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Enregistrer')),
        ],
      ),
    );
    controller.dispose();
    if (caption != null) bridge.editPost(post.id, caption);
  }

  Future<void> _remove(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette vidéo ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) bridge.removePost(post.id);
  }

  @override
  Widget build(BuildContext context) {
    final me = users.me.id;
    final author = users.user(post.authorId)?.name ?? 'Utilisateur';
    final liked = post.likes.contains(me);
    final count = bridge.comments(post.id).where((c) => !c.deleted).length;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (post.hasMedia && post.isImage)
          ColoredBox(
            color: Colors.black,
            child: Image.file(File(post.mediaPath), fit: BoxFit.contain),
          )
        else if (post.hasMedia)
          _PostVideo(path: post.mediaPath, active: active)
        else
          Container(
            decoration: BoxDecoration(gradient: postGradient(post.id)),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              post.caption,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 30, 80, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x99000000)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SocialAvatar(name: author, size: 32),
                    const SizedBox(width: 8),
                    Text(author, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo(post.time) + (post.edited ? ' · modifié' : ''),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                if (post.hasMedia && post.caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(post.caption, style: const TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 90,
          child: Column(
            children: [
              _Action(
                icon: liked ? '❤️' : '🤍',
                label: '${post.likes.length}',
                onTap: () => bridge.toggleLike(post.id),
              ),
              const SizedBox(height: 18),
              _Action(
                icon: '💬',
                label: '$count',
                onTap: () => showCommentsSheet(context, post.id),
              ),
              if (post.authorId == me) ...[
                const SizedBox(height: 18),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 30),
                  onSelected: (v) => v == 'edit' ? _edit(context) : _remove(context),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Modifier la légende')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer la vidéo')),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _Action({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 30)),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    ),
  );
}

/// Lecture de la vidéo publiée (fichier local) quand la page est visible.
class _PostVideo extends StatefulWidget {
  final String path;
  final bool active;

  const _PostVideo({required this.path, required this.active});

  @override
  State<_PostVideo> createState() => _PostVideoState();
}

class _PostVideoState extends State<_PostVideo> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        if (widget.active) _controller.play();
      });
  }

  @override
  void didUpdateWidget(covariant _PostVideo old) {
    super.didUpdateWidget(old);
    if (!_ready) return;
    widget.active ? _controller.play() : _controller.pause();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: _ready
        ? Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          )
        : const Center(child: CircularProgressIndicator(color: Colors.white)),
  );
}

/// Commentaires et réponses d'une publication : ajouter, répondre, aimer, modifier et supprimer les siens.
Future<void> showCommentsSheet(BuildContext context, int postId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CommentsSheet(postId: postId),
    );

class _CommentsSheet extends ConsumerStatefulWidget {
  final int postId;

  const _CommentsSheet({required this.postId});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final TextEditingController _text = TextEditingController();
  PostComment? _replyTo;
  PostComment? _editing;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit(VideoBridge bridge) {
    final value = _text.text.trim();
    if (value.isEmpty) return;
    final editing = _editing;
    final reply = _replyTo;
    if (editing != null) {
      bridge.editComment(editing.id, value);
    } else {
      bridge.addComment(widget.postId, value, parentId: reply == null ? null : (reply.parentId ?? reply.id));
    }
    setState(() {
      _text.clear();
      _replyTo = null;
      _editing = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bridge = ref.watch(videoBridgeProvider);
    final users = ref.watch(usersBridgeProvider);
    final me = users.me.id;
    String name(int id) => users.user(id)?.name ?? 'Utilisateur';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: ListenableBuilder(
          listenable: bridge,
          builder: (context, _) {
            final all = bridge.comments(widget.postId);
            final visible = all
                .where((c) => !c.deleted || all.any((r) => r.parentId == c.id && !r.deleted))
                .toList();
            final roots = visible.where((c) => c.parentId == null).toList();

            Widget line(PostComment c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SocialAvatar(name: name(c.authorId), size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${name(c.authorId)}  ·  ${timeAgo(c.time)}${c.edited ? ' · modifié' : ''}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        if (c.deleted)
                          const Text('Commentaire supprimé', style: TextStyle(fontStyle: FontStyle.italic))
                        else ...[
                          Text(c.text),
                          Wrap(
                            spacing: 14,
                            children: [
                              GestureDetector(
                                onTap: () => bridge.toggleCommentLike(c.id),
                                child: Text('${c.likes.contains(me) ? '❤️' : '🤍'} ${c.likes.length}', style: const TextStyle(fontSize: 12)),
                              ),
                              GestureDetector(
                                onTap: () => setState(() {
                                  _replyTo = c;
                                  _editing = null;
                                }),
                                child: const Text('Répondre', style: TextStyle(fontSize: 12)),
                              ),
                              if (c.authorId == me)
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _editing = c;
                                    _replyTo = null;
                                    _text.text = c.text;
                                  }),
                                  child: const Text('Modifier', style: TextStyle(fontSize: 12)),
                                ),
                              if (c.authorId == me)
                                GestureDetector(
                                  onTap: () => bridge.removeComment(c.id),
                                  child: Text('Supprimer', style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Commentaires (${all.where((c) => !c.deleted).length})',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: roots.isEmpty
                      ? const Center(child: Text('Aucun commentaire. Soyez le premier !'))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            for (final c in roots) ...[
                              line(c),
                              for (final r in visible.where((x) => x.parentId == c.id))
                                Padding(padding: const EdgeInsets.only(left: 42), child: line(r)),
                            ],
                          ],
                        ),
                ),
                if (_replyTo != null || _editing != null)
                  Container(
                    color: NgomaColors.brand50,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _editing != null ? 'Modification du commentaire' : 'Réponse à ${name(_replyTo!.authorId)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _replyTo = null;
                            _editing = null;
                            _text.clear();
                          }),
                          child: const Text('Annuler'),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _text,
                          onSubmitted: (_) => _submit(bridge),
                          decoration: InputDecoration(
                            hintText: 'Ajouter un commentaire…',
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: NgomaColors.brand),
                        onPressed: () => _submit(bridge),
                        icon: Icon(_editing != null ? Icons.check : Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Publier : photo ou vidéo de la galerie (facultatif) et/ou une légende ; une légende seule est acceptée.
class PublishScreen extends ConsumerStatefulWidget {
  const PublishScreen({super.key});

  @override
  ConsumerState<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends ConsumerState<PublishScreen> {
  final TextEditingController _caption = TextEditingController();
  String? _path;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickMedia();
    if (file != null) setState(() => _path = file.path);
  }

  @override
  Widget build(BuildContext context) {
    final canPublish = _path != null || _caption.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Publier')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.perm_media_outlined),
            label: Text(_path == null ? 'Ajouter une photo ou une vidéo (facultatif)' : _path!.split(RegExp(r'[\\/]')).last),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _caption,
            minLines: 2,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Légende'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: NgomaColors.brand,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: canPublish
                ? () {
                    ref.read(videoBridgeProvider).publish(caption: _caption.text, mediaPath: _path);
                    Navigator.of(context).pop(true);
                  }
                : null,
            child: const Text('Publier'),
          ),
        ],
      ),
    );
  }
}
