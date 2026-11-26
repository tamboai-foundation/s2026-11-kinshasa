import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ngoma/core/providers/user_provider.dart';

import 'social_bridge_mock.dart';
import 'social_models.dart';

export 'social_models.dart';

/// Interface UI <-> TModeler : gestion des utilisateurs (M1 SI, module 1).
/// Lectures synchrones + `Listenable` : l'écran se reconstruit quand les données changent.
/// Remplacer le mock par une implémentation qui s'appuie sur vos modèles TModeler.
abstract class UsersBridge implements Listenable {
  /// Utilisateur connecté.
  SocialUser get me;

  /// Tous les utilisateurs (moi en premier), filtrés par la recherche (nom ou description).
  List<SocialUser> users([String query = '']);
  SocialUser? user(int id);
  void updateMyProfile({String? name, String? bio});
  Future<void> deleteAccount();
}

/// Interface UI <-> TModeler : publications vidéo, likes, commentaires et réponses (M1 SI, module 3).
abstract class VideoBridge implements Listenable {
  /// Fil d'actualité : toutes les publications, la plus récente en premier.
  List<VideoPost> feed();
  List<VideoPost> userPosts(int userId);
  VideoPost publish({required String caption, String? mediaPath});
  void editPost(int postId, String caption);
  void removePost(int postId);

  /// Aime ou n'aime plus (bascule) pour l'utilisateur connecté.
  void toggleLike(int postId);
  List<PostComment> comments(int postId);
  void addComment(int postId, String text, {int? parentId});
  void editComment(int commentId, String text);
  void removeComment(int commentId);
  void toggleCommentLike(int commentId);
}

// Point de bascule mock -> TModeler : remplacer ces deux providers par des implémentations TModeler.
final usersBridgeProvider = Provider<UsersBridge>(
  (ref) => UsersBridgeMock(meName: () => ref.read(userProvider).fullName),
);

final videoBridgeProvider = Provider<VideoBridge>(
  (ref) => VideoBridgeMock(),
);
