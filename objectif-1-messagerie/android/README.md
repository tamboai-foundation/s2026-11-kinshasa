# NGoma — Android (Flutter + TModeler)

Projet de départ Foundation. UI = chat Wouanda complet (auth, splash, inbox, conversation, etc.), charte rouge.

## Lancer
```
flutter pub get
flutter run
```
Build vérifié : `flutter build apk --debug`.

## Mocks (niveau ui-bridge-TModeler)
- Compte : `lib/core/platform/account/account_bridge_mock.dart` (tout identifiant/mot de passe connecte ; session dans SharedPreferences).
- Messagerie : `lib/core/platform/messaging/messaging_bridge_mock.dart` (activé dans `messaging_bridge_provider.dart`).

Pour passer à TModeler : implémenter `AccountBridge` / `MessagingBridge` avec TModeler et changer les providers.

## TModeler
- Dépendance Maven Central : `co.tamboai:TModeler:1.0.1` (`android/app/build.gradle.kts`).
- Init : `android/app/src/main/kotlin/ai/tambo/foundation/ngoma/NGomaTm.kt` (`DB_VERSION` : l'incrémenter repart d'une base vide).
- Exemple de modèle : `models/Note.kt`.

## Charte
Rouge principal `#E0262D` : `packages/wouanda_design/lib/src/foundations/wouanda_colors.dart`.
`WouandaMvpMode` doit rester à `false`.
