/// Modèles d'interface du Module 1 SI (utilisateurs, publications vidéo, commentaires).
/// Ce sont les objets que les écrans affichent : à alimenter depuis VOS modèles TModeler.
library;

class SocialUser {
  final int id;
  final String name;
  final String bio;
  final DateTime? joinedAt;

  const SocialUser({
    required this.id,
    required this.name,
    this.bio = '',
    this.joinedAt,
  });

  SocialUser copyWith({String? name, String? bio}) => SocialUser(
    id: id,
    name: name ?? this.name,
    bio: bio ?? this.bio,
    joinedAt: joinedAt,
  );
}

/// Publication : un média facultatif (photo ou vidéo) et une légende. `mediaPath` vide : légende seule, affichée sur une carte colorée.
class VideoPost {
  final int id;
  final int authorId;
  final String caption;
  final String mediaPath;
  final DateTime time;
  final bool edited;

  bool get hasMedia => mediaPath.isNotEmpty;
  bool get isImage => RegExp(r'\.(jpe?g|png|gif|webp|bmp|heic)$', caseSensitive: false).hasMatch(mediaPath);

  /// Identifiants des utilisateurs qui ont aimé la publication.
  final Set<int> likes;

  const VideoPost({
    required this.id,
    required this.authorId,
    required this.caption,
    this.mediaPath = '',
    required this.time,
    this.edited = false,
    this.likes = const {},
  });

  VideoPost copyWith({String? caption, bool? edited, Set<int>? likes}) =>
      VideoPost(
        id: id,
        authorId: authorId,
        caption: caption ?? this.caption,
        mediaPath: mediaPath,
        time: time,
        edited: edited ?? this.edited,
        likes: likes ?? this.likes,
      );
}

class PostComment {
  final int id;
  final int postId;
  final int authorId;
  final String text;
  final DateTime time;

  /// Réponse à un commentaire : identifiant du commentaire parent (un seul niveau dans l'interface).
  final int? parentId;
  final bool edited;
  final bool deleted;
  final Set<int> likes;

  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.text,
    required this.time,
    this.parentId,
    this.edited = false,
    this.deleted = false,
    this.likes = const {},
  });

  PostComment copyWith({
    String? text,
    bool? edited,
    bool? deleted,
    Set<int>? likes,
  }) => PostComment(
    id: id,
    postId: postId,
    authorId: authorId,
    text: text ?? this.text,
    time: time,
    parentId: parentId,
    edited: edited ?? this.edited,
    deleted: deleted ?? this.deleted,
    likes: likes ?? this.likes,
  );
}
