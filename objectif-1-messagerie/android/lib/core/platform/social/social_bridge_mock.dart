import 'package:flutter/foundation.dart';

import 'social_bridge.dart';

/// Identifiant de l'utilisateur connecté dans les mocks.
const int mockMeId = 1;

class UsersBridgeMock extends ChangeNotifier implements UsersBridge {
  UsersBridgeMock({required this.meName});

  /// Nom de l'utilisateur de la session (le mock le relit à chaque lecture).
  final String Function() meName;
  String? _name;
  String _bio = '';
  final DateTime _joined = DateTime.now();

  static final List<SocialUser> _others = [
    SocialUser(
      id: 101,
      name: 'Aïcha Nguema',
      bio: 'Développeuse mobile, Douala.',
      joinedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    SocialUser(
      id: 102,
      name: 'Moussa Diallo',
      bio: 'Cybersécurité, Yaoundé.',
      joinedAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    SocialUser(
      id: 103,
      name: 'Grace Mballa',
      bio: 'Design et vidéo, Douala.',
      joinedAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    SocialUser(
      id: 104,
      name: 'Kofi Mensah',
      bio: 'Étudiant en informatique, Accra.',
      joinedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    SocialUser(
      id: 105,
      name: 'Fatou Diop',
      bio: 'Passionnée de musique et de code.',
      joinedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  SocialUser get me => SocialUser(
    id: mockMeId,
    name: _name ?? (meName().trim().isEmpty ? 'Moi' : meName()),
    bio: _bio,
    joinedAt: _joined,
  );

  @override
  List<SocialUser> users([String query = '']) {
    final q = query.trim().toLowerCase();
    return [me, ..._others]
        .where(
          (u) =>
              q.isEmpty ||
              u.name.toLowerCase().contains(q) ||
              u.bio.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  SocialUser? user(int id) {
    for (final u in [me, ..._others]) {
      if (u.id == id) return u;
    }
    return null;
  }

  @override
  void updateMyProfile({String? name, String? bio}) {
    if (name != null && name.trim().isNotEmpty) _name = name.trim();
    if (bio != null) _bio = bio.trim();
    notifyListeners();
  }

  @override
  Future<void> deleteAccount() async {
    // Mock : rien à supprimer. À brancher sur la suppression du compte TModeler.
  }
}

class VideoBridgeMock extends ChangeNotifier implements VideoBridge {
  VideoBridgeMock() {
    final now = DateTime.now();
    VideoPost post(int author, String caption, Duration ago, Set<int> likes) =>
        VideoPost(
          id: _next++,
          authorId: author,
          caption: caption,
          time: now.subtract(ago),
          likes: likes,
        );
    _posts.addAll([
      post(101, 'Ma première application de messagerie, étape par étape ✨', const Duration(hours: 1), {102, 103, 104}),
      post(102, 'Un petit tour dans les coulisses de notre équipe 🎬', const Duration(hours: 2), {101}),
      post(103, 'Astuce du jour : tester chaque écran avant de le montrer.', const Duration(hours: 5), {101, 102, 104, 105}),
      post(104, 'Pourquoi on chiffre les messages ? Explication en 30 secondes.', const Duration(days: 1), {}),
      post(105, 'Bienvenue sur NGoma 👋', const Duration(days: 2), {101, 102}),
    ]);
    final first = _posts.first.id;
    final c1 = _next++;
    _notes.addAll([
      PostComment(id: c1, postId: first, authorId: 102, text: 'Bravo, très clair !', time: now.subtract(const Duration(minutes: 50))),
      PostComment(id: _next++, postId: first, authorId: 103, text: 'Merci pour le partage 🙏', time: now.subtract(const Duration(minutes: 47))),
      PostComment(id: _next++, postId: first, authorId: 101, text: 'Merci Moussa !', time: now.subtract(const Duration(minutes: 42)), parentId: c1),
    ]);
  }

  int _next = 1000;
  final List<VideoPost> _posts = [];
  final List<PostComment> _notes = [];

  @override
  List<VideoPost> feed() =>
      [..._posts]..sort((a, b) => b.time.compareTo(a.time));

  @override
  List<VideoPost> userPosts(int userId) =>
      feed().where((p) => p.authorId == userId).toList();

  @override
  VideoPost publish({required String caption, String? mediaPath}) {
    final post = VideoPost(
      id: _next++,
      authorId: mockMeId,
      caption: caption.trim(),
      mediaPath: mediaPath ?? '',
      time: DateTime.now(),
    );
    _posts.add(post);
    notifyListeners();
    return post;
  }

  void _patchPost(int id, VideoPost Function(VideoPost) f) {
    final i = _posts.indexWhere((p) => p.id == id);
    if (i < 0) return;
    _posts[i] = f(_posts[i]);
    notifyListeners();
  }

  @override
  void editPost(int postId, String caption) =>
      _patchPost(postId, (p) => p.copyWith(caption: caption.trim(), edited: true));

  @override
  void removePost(int postId) {
    _posts.removeWhere((p) => p.id == postId);
    _notes.removeWhere((c) => c.postId == postId);
    notifyListeners();
  }

  @override
  void toggleLike(int postId) => _patchPost(postId, (p) {
    final likes = {...p.likes};
    if (!likes.add(mockMeId)) likes.remove(mockMeId);
    return p.copyWith(likes: likes);
  });

  @override
  List<PostComment> comments(int postId) =>
      _notes.where((c) => c.postId == postId).toList()
        ..sort((a, b) => a.time.compareTo(b.time));

  @override
  void addComment(int postId, String text, {int? parentId}) {
    _notes.add(
      PostComment(
        id: _next++,
        postId: postId,
        authorId: mockMeId,
        text: text.trim(),
        time: DateTime.now(),
        parentId: parentId,
      ),
    );
    notifyListeners();
  }

  void _patchNote(int id, PostComment Function(PostComment) f) {
    final i = _notes.indexWhere((c) => c.id == id);
    if (i < 0) return;
    _notes[i] = f(_notes[i]);
    notifyListeners();
  }

  @override
  void editComment(int commentId, String text) => _patchNote(
    commentId,
    (c) => c.copyWith(text: text.trim(), edited: true),
  );

  @override
  void removeComment(int commentId) =>
      _patchNote(commentId, (c) => c.copyWith(text: '', deleted: true));

  @override
  void toggleCommentLike(int commentId) => _patchNote(commentId, (c) {
    final likes = {...c.likes};
    if (!likes.add(mockMeId)) likes.remove(mockMeId);
    return c.copyWith(likes: likes);
  });
}
