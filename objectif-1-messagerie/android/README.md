# NGoma — Android (Flutter + TModeler)

Projet de départ Foundation. UI = chat NGoma complet (auth, splash, inbox, conversation, etc.), charte rouge.

## Lancer
```
flutter pub get
flutter run
```
Build vérifié : `flutter build apk --debug`.

## Écrans (de quoi réaliser le Module 1 SI)
Barre d'onglets en bas : **Messages**, **Vidéos**, **Personnes**, **Profil**.
1. **Gestion des utilisateurs** : inscription / connexion, **Personnes** (liste, recherche, profil d'une personne, écrire un message), **Profil** (modifier son nom et sa description, voir ses vidéos, se déconnecter, supprimer son compte).
2. **Conversations et messages** : la messagerie complète déjà présente (inbox, conversation, envoi, réponse, modification, suppression, réactions).
3. **Publications vidéo et interactions**, façon TikTok : **Vidéos** (fil à défilement vertical, affichage de la photo ou lecture de la vidéo publiée), publier (photo ou vidéo de la galerie, facultatives, + légende ; une légende seule est acceptée), modifier la légende, supprimer, j'aime, commentaires et réponses (aimer, modifier, supprimer les siens), publications des autres, onglet « Mes vidéos ».

Code des nouveaux écrans : `lib/features/social/` ; modèles et ponts : `lib/core/platform/social/` (`UsersBridge`, `VideoBridge` et leurs mocks).

## Mocks (niveau ui-bridge-TModeler)
- Compte : `lib/core/platform/account/account_bridge_mock.dart` (tout identifiant/mot de passe connecte ; session dans SharedPreferences).
- Messagerie : `lib/core/platform/messaging/messaging_bridge_mock.dart` (activé dans `messaging_bridge_provider.dart`).

Pour passer à TModeler : implémenter `AccountBridge` / `MessagingBridge` avec TModeler et changer les providers.
- Utilisateurs et vidéos : `lib/core/platform/social/social_bridge.dart` (`UsersBridge`, `VideoBridge`, providers `usersBridgeProvider` / `videoBridgeProvider`), mocks dans `social_bridge_mock.dart`.

Les écrans ne changent pas : votre travail est de **concevoir vos modèles TModeler** (utilisateur, conversation, message, publication, commentaire, j'aime) puis d'écrire les implémentations des interfaces à partir de ces modèles. Les photos et vidéos choisies dans l'interface sont des fichiers : à enregistrer comme médias TModeler.

## TModeler
- Dépendance Maven Central : `co.tamboai:TModeler:1.0.1` (`android/app/build.gradle.kts`).
- Init : `android/app/src/main/kotlin/ai/tambo/foundation/ngoma/NGomaTm.kt` (`DB_VERSION` : l'incrémenter repart d'une base vide).
- Exemple de modèle : `models/Note.kt`.

## Charte
Rouge principal `#E0262D` : `packages/ngoma_design/lib/src/foundations/ngoma_colors.dart`.
`NgomaMvpMode` doit rester à `false`.
