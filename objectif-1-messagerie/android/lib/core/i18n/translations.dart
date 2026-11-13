import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Complete internationalization system for Wouanda
/// Supports FR (default), EN, and extensible to African languages

class WouandaLocale {
  final String name;
  final String code;
  final String flag;
  final String nativeName;
  final Map<String, String> translations;

  const WouandaLocale({
    required this.name,
    required this.code,
    required this.flag,
    required this.nativeName,
    required this.translations,
  });

  String t(String key) => translations[key] ?? key;
}

/// All supported languages
final supportedLocales = <WouandaLocale>[_frLocale, _enLocale];

const _frLocale = WouandaLocale(
  name: 'Français',
  code: 'fr',
  flag: 'FR',
  nativeName: 'Français',
  translations: {
    // --- Auth ---
    'auth_login': 'Connexion',
    'auth_welcome': 'Bon retour',
    'auth_identifier': 'Identifiant',
    'auth_identifier_hint': 'Email ou téléphone',
    'auth_identifier_required': 'Entrez votre identifiant',
    'auth_password_hint': 'Votre mot de passe',
    'auth_password_required': 'Entrez votre mot de passe',
    'auth_show': 'Afficher',
    'auth_hide': 'Masquer',
    'auth_back': 'Retour',
    'auth_explore': 'Explorer sans compte',
    'auth_or': 'ou',
    'auth_google': 'Continuer avec Google',
    'auth_apple': 'Continuer avec Apple',
    'auth_unavailable': 'Le service de compte est indisponible. Réessayez.',
    'auth_social_unavailable':
        'Google et Apple seront disponibles après activation. Utilisez votre identifiant ou explorez sans compte.',
    'auth_retry': 'Réessayer',
    'auth_register': 'Inscription',
    'auth_access': 'Accédez à votre écosystème',
    'auth_join': 'Rejoignez Wouanda',
    'auth_email': 'Email',
    'auth_password': 'Mot de passe',
    'auth_forgot': 'Mot de passe oublié ?',
    'auth_no_account': 'Pas encore membre ?',
    'auth_has_account': 'Déjà membre ?',
    'auth_create': 'Créer mon compte',
    'auth_enter': 'Se connecter',
    'full_name': 'Nom complet',
    'confirm_password': 'Confirmer le mot de passe',
    'or_continue_with': 'ou continuer avec',
    'discover_without_connect': 'Découvrir sans se connecter',
    'forgot_title': 'Récupération',
    'forgot_desc':
        'Entrez votre email pour recevoir un lien de réinitialisation.',
    'send_reset_link': 'Envoyer le lien',
    'email_sent': 'Lien envoyé !',
    'email_sent_desc':
        'Une invitation à réinitialiser votre mot de passe a été envoyée.',
    'back_to_login': 'Retour à la connexion',
    'remember_me': 'Se souvenir de moi',
    'logout': 'Déconnexion',

    // --- Hub ---
    'hub_services': 'Services Wouanda',
    'hub_subtitle': 'Tout ce dont vous avez besoin, en un clic.',
    'hub_search': 'Rechercher un service, lieu, produit...',
    'hub_offers': 'Offres & Promotions',

    // --- Navigation ---
    'nav_hub': 'Hub',
    'nav_activity': 'Messages',
    'nav_wallet': 'Wallet',
    'nav_profile': 'Profil',
    'nav_notifications': 'Notifications',

    // --- Services ---
    'service_mobility': 'Mobilité',
    'service_shop': 'Shopping',
    'service_events': 'Événements',
    'service_love': 'Rencontres',
    'service_scanner': 'Scanner',

    // --- Wallet ---
    'wallet_balance': 'Solde disponible',
    'wallet_topup': 'Recharger',
    'wallet_transfer': 'Transférer',
    'wallet_history': 'Historique',
    'wallet_cashback': 'Cashback',
    'wallet_points': 'Points fidélité',
    'wallet_pay': 'Payer',

    // --- Profile ---
    'profile_title': 'Mon profil',
    'profile_edit': 'Modifier le profil',
    'profile_kyc': 'Vérification d\'identité',
    'profile_kyc_unverified': 'Non vérifié',
    'profile_kyc_pending': 'En cours',
    'profile_kyc_verified': 'Vérifié',
    'profile_settings': 'Paramètres',
    'profile_security': 'Sécurité',
    'profile_language': 'Langue',
    'profile_dark_mode': 'Thème sombre',
    'profile_help': 'Aide & Support',
    'profile_about': 'À propos',
    'profile_privacy': 'Confidentialité',
    'profile_trips': 'Mes courses',
    'profile_purchases': 'Mes achats',

    // --- Notifications ---
    'notif_today': 'Aujourd\'hui',
    'notif_yesterday': 'Hier',
    'notif_this_week': 'Cette semaine',
    'notif_mark_all_read': 'Tout lire',
    'notif_empty': 'Aucune notification',

    // --- Scanner ---
    'scanner_title': 'Scanner',
    'scanner_universal': 'Scanner',
    'scanner_payment': 'Payer',
    'scanner_ticket': 'Ticket',
    'scanner_profile': 'Profil',
    'scanner_product': 'Produit',
    'scanner_my_qr': 'Mon QR',
    'scanner_history': 'Historique',
    'scanner_gallery': 'Galerie',

    // --- Onboarding ---
    'onboarding_skip': 'Passer',
    'onboarding_next': 'Suivant',
    'onboarding_start': 'Commencer',
    'onboarding_1_title': 'Un Écosystème Unifié',
    'onboarding_1_desc': 'Tous vos services en une seule application.',
    'onboarding_2_title': 'Mobilité Intelligente',
    'onboarding_2_desc': 'Commandez un trajet en quelques secondes.',
    'onboarding_3_title': 'Artisanat d\'Art',
    'onboarding_3_desc': 'Achetez et vendez des créations faites main.',
    'onboarding_4_title': 'Événements Exclusifs',
    'onboarding_4_desc': 'Découvrez les meilleurs événements près de vous.',
    'onboarding_5_title': 'Rencontres Wouanda',
    'onboarding_5_desc': 'Rencontrez des personnes qui partagent vos passions.',

    // --- Profile menu ---
    'profile_history': 'Historique & Activité',
    'profile_payments': 'Moyens de paiement',
    'profile_wallet_payments': 'Wouanda Pay & Paiements',
    'profile_promos': 'Code Promo & Coupons',
    'profile_addresses': 'Adresses',
    'profile_dock': 'Personnaliser le Dock',
    'profile_dock_sub': 'Position, Orientation, Taille',
    'profile_notifications': 'Notifications',
    'profile_logout': 'Déconnexion',
    'profile_logout_success': 'Déconnexion réussie',
    'profile_logout_confirm_title': 'Déconnexion',
    'profile_logout_confirm_msg': 'Êtes-vous sûr de vouloir vous déconnecter ?',
    'profile_logout_action': 'Oui, se déconnecter',
    'profile_account': 'Compte',
    'profile_preferences': 'Préférences',
    'profile_support': 'Support',

    // --- Wallet extended ---
    'wallet_send': 'Envoyer',
    'wallet_scan': 'Scanner',
    'wallet_payment_methods': 'Moyens de paiement',
    'wallet_manage': 'Gérer',
    'wallet_recent': 'Transactions récentes',
    'wallet_total_balance': 'Solde total',
    'wallet_slogan': 'Et si tout se connectait enfin ?',

    // --- Hub extended ---
    'hub_exclusive_offers': 'Offres Exclusives',
    'hub_premium_ride': 'Course Premium',
    'hub_discount': "Jusqu'à -20%",
    'hub_collection': 'Collection 2026',
    'hub_new': 'Nouveauté',

    // --- Scanner extended ---
    'scanner_scan_qr': 'Scannez un QR code ou code-barres',
    'scanner_pay_desc': 'Scannez pour payer via Wouanda Pay',
    'scanner_ticket_desc': "Validez votre ticket d'événement",
    'scanner_profile_desc': 'Scannez pour ajouter un contact',
    'scanner_product_desc': 'Scannez un produit pour voir les détails',
    'scanner_no_history': 'Aucun scan récent',
    'scanner_scan_history': 'Historique des scans',
    'scanner_my_qr_desc':
        'Partagez ce code pour recevoir des paiements\nou ajouter des contacts.',
    'scanner_result': 'Résultat scanné',
    'scanner_demo_payment': 'Paiement détecté',
    'scanner_demo_ticket': 'Ticket événement validé',

    // --- General ---
    'choose_language': 'Choisir la langue',
    'cancel': 'Annuler',
    'confirm': 'Confirmer',
    'save': 'Enregistrer',
    'delete': 'Supprimer',
    'error': 'Erreur',
    'success': 'Succès',
    'loading': 'Chargement...',
    'retry': 'Réessayer',
    'no_results': 'Aucun résultat',
    'see_all': 'Voir tout',
    'close': 'Fermer',
    'back': 'Retour',
    'next': 'Suivant',
    'skip': 'Passer',
    'get_started': 'Commencer',
    'done': 'Terminé',
    'search': 'Rechercher',
    'offline_mode': 'Mode hors connexion',
    'offline_desc': 'Certaines fonctionnalités sont limitées.',
    'auth_required': 'Connexion requise',
    'auth_required_desc': 'Connectez-vous pour accéder à cette fonctionnalité.',
    'guest': 'Invité',

    // --- Card ---
    'card_add': 'Ajouter une carte',
    'card_holder_name': 'Nom du titulaire',
    'card_number': 'Numéro de carte',
    'card_expiry': "Date d'expiration",
    'card_cvv': 'CVV',
    'card_save': 'Enregistrer la carte',
    'card_add_action': 'Ajouter la carte',
    'card_add_success': 'Carte ajoutée avec succès !',
  },
);

const _enLocale = WouandaLocale(
  name: 'English',
  code: 'en',
  flag: 'US',
  nativeName: 'English',
  translations: {
    // --- Auth ---
    'auth_login': 'Login',
    'auth_welcome': 'Welcome back',
    'auth_identifier': 'Username',
    'auth_identifier_hint': 'Email or phone',
    'auth_identifier_required': 'Enter your username',
    'auth_password_hint': 'Your password',
    'auth_password_required': 'Enter your password',
    'auth_show': 'Show',
    'auth_hide': 'Hide',
    'auth_back': 'Back',
    'auth_explore': 'Explore without an account',
    'auth_or': 'or',
    'auth_google': 'Continue with Google',
    'auth_apple': 'Continue with Apple',
    'auth_unavailable': 'Account service unavailable. Please try again.',
    'auth_social_unavailable':
        'Google and Apple sign-in are awaiting activation. Use your username or explore without an account.',
    'auth_retry': 'Try again',
    'auth_register': 'Sign Up',
    'auth_access': 'Access your ecosystem',
    'auth_join': 'Join Wouanda',
    'auth_email': 'Email',
    'auth_password': 'Password',
    'auth_forgot': 'Forgot password?',
    'auth_no_account': 'Not a member yet?',
    'auth_has_account': 'Already a member?',
    'auth_create': 'Create my account',
    'auth_enter': 'Login now',
    'full_name': 'Full name',
    'confirm_password': 'Confirm password',
    'or_continue_with': 'or continue with',
    'discover_without_connect': 'Discover without login',
    'forgot_title': 'Password Recovery',
    'forgot_desc': 'Enter your email to receive a reset link.',
    'send_reset_link': 'Send reset link',
    'email_sent': 'Link sent!',
    'email_sent_desc': 'A password reset invitation has been sent.',
    'back_to_login': 'Back to login',
    'remember_me': 'Remember me',
    'logout': 'Logout',

    // --- Hub ---
    'hub_services': 'Wouanda Services',
    'hub_subtitle': 'Everything you need, in one tap.',
    'hub_search': 'Search for a service, place, product...',
    'hub_offers': 'Offers & Promotions',

    // --- Navigation ---
    'nav_hub': 'Hub',
    'nav_activity': 'Messages',
    'nav_wallet': 'Wallet',
    'nav_profile': 'Profile',
    'nav_notifications': 'Notifications',

    // --- Services ---
    'service_mobility': 'Mobility',
    'service_shop': 'Shopping',
    'service_events': 'Events',
    'service_love': 'Dating',
    'service_scanner': 'Scanner',

    // --- Wallet ---
    'wallet_balance': 'Available balance',
    'wallet_topup': 'Top Up',
    'wallet_transfer': 'Transfer',
    'wallet_history': 'History',
    'wallet_cashback': 'Cashback',
    'wallet_points': 'Loyalty points',
    'wallet_pay': 'Pay',

    // --- Profile ---
    'profile_title': 'My profile',
    'profile_edit': 'Edit profile',
    'profile_kyc': 'Identity verification',
    'profile_kyc_unverified': 'Unverified',
    'profile_kyc_pending': 'Pending',
    'profile_kyc_verified': 'Verified',
    'profile_settings': 'Settings',
    'profile_security': 'Security',
    'profile_language': 'Language',
    'profile_dark_mode': 'Dark mode',
    'profile_help': 'Help & Support',
    'profile_about': 'About',
    'profile_privacy': 'Privacy',

    // --- Notifications ---
    'notif_today': 'Today',
    'notif_yesterday': 'Yesterday',
    'notif_this_week': 'This week',
    'notif_mark_all_read': 'Mark all read',
    'notif_empty': 'No notifications',

    // --- Scanner ---
    'scanner_title': 'Scanner',
    'scanner_universal': 'Scan',
    'scanner_payment': 'Pay',
    'scanner_ticket': 'Ticket',
    'scanner_profile': 'Profile',
    'scanner_product': 'Product',
    'scanner_my_qr': 'My QR',
    'scanner_history': 'History',
    'scanner_gallery': 'Gallery',

    // --- Onboarding ---
    'onboarding_skip': 'Skip',
    'onboarding_next': 'Next',
    'onboarding_start': 'Get Started',
    'onboarding_1_title': 'A Unified Ecosystem',
    'onboarding_1_desc': 'All your services in a single app.',
    'onboarding_2_title': 'Smart Mobility',
    'onboarding_2_desc': 'Book a ride in seconds.',
    'onboarding_3_title': 'Handcrafted Arts',
    'onboarding_3_desc': 'Buy and sell authentic handcrafted items.',
    'onboarding_4_title': 'Exclusive Events',
    'onboarding_4_desc': 'Discover the best events near you.',
    'onboarding_5_title': 'Wouanda Dating',
    'onboarding_5_desc': 'Meet people who share your passions.',

    // --- Profile menu ---
    'profile_history': 'History & Activity',
    'profile_payments': 'Payment Methods',
    'profile_wallet_payments': 'Wouanda Pay & Payments',
    'profile_promos': 'Promo Code & Coupons',
    'profile_addresses': 'Addresses',
    'profile_dock': 'Customize Dock',
    'profile_dock_sub': 'Position, Orientation, Size',
    'profile_notifications': 'Notifications',
    'profile_logout': 'Logout',
    'profile_logout_success': 'Logged out successfully',
    'profile_logout_confirm_title': 'Logout',
    'profile_logout_confirm_msg': 'Are you sure you want to log out?',
    'profile_logout_action': 'Yes, logout',
    'profile_account': 'Account',
    'profile_preferences': 'Preferences',
    'profile_support': 'Support',
    'profile_trips': 'Trips',
    'profile_purchases': 'Purchases',

    // --- Wallet extended ---
    'wallet_send': 'Send',
    'wallet_scan': 'Scan',
    'wallet_payment_methods': 'Payment Methods',
    'wallet_manage': 'Manage',
    'wallet_recent': 'Recent Transactions',
    'wallet_total_balance': 'Total balance',
    'wallet_slogan': 'What if everything finally connected?',

    // --- Hub extended ---
    'hub_exclusive_offers': 'Exclusive Offers',
    'hub_premium_ride': 'Premium Ride',
    'hub_discount': 'Up to -20%',
    'hub_collection': '2026 Collection',
    'hub_new': 'New',

    // --- Scanner extended ---
    'scanner_scan_qr': 'Scan a QR code or barcode',
    'scanner_pay_desc': 'Scan to pay via Wouanda Pay',
    'scanner_ticket_desc': 'Validate your event ticket',
    'scanner_profile_desc': 'Scan to add a contact',
    'scanner_product_desc': 'Scan a product for details',
    'scanner_no_history': 'No recent scans',
    'scanner_scan_history': 'Scan History',
    'scanner_my_qr_desc':
        'Share this code to receive payments\nor add contacts.',
    'scanner_result': 'Scan result',
    'scanner_demo_payment': 'Payment detected',
    'scanner_demo_ticket': 'Event ticket validated',

    // --- General ---
    'choose_language': 'Choose language',
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'save': 'Save',
    'delete': 'Delete',
    'error': 'Error',
    'success': 'Success',
    'loading': 'Loading...',
    'retry': 'Retry',
    'no_results': 'No results',
    'see_all': 'See all',
    'close': 'Close',
    'back': 'Back',
    'next': 'Next',
    'skip': 'Skip',
    'get_started': 'Get Started',
    'done': 'Done',
    'search': 'Search',
    'offline_mode': 'Offline mode',
    'offline_desc': 'Some features are limited.',
    'auth_required': 'Login required',
    'auth_required_desc': 'Sign in to access this feature.',
    'guest': 'Guest',

    // --- Card ---
    'card_add': 'Add a card',
    'card_holder_name': 'Card holder name',
    'card_number': 'Card number',
    'card_expiry': 'Expiry date',
    'card_cvv': 'CVV',
    'card_save': 'Save this card',
    'card_add_action': 'Add card',
    'card_add_success': 'Card added successfully!',
  },
);

/// Language notifier with persistence
class LanguageNotifier extends Notifier<WouandaLocale> {
  static const String _langKey = 'wouanda_language';

  @override
  WouandaLocale build() {
    _loadSavedLanguage();
    // Most mounted screens are French-first until their translations land.
    // A language explicitly chosen in Settings still takes precedence.
    return supportedLocales[0];
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_langKey);
    if (code != null) {
      final locale = supportedLocales.firstWhere(
        (l) => l.code == code,
        orElse: () => supportedLocales[0],
      );
      state = locale;
    }
  }

  Future<void> setLanguage(WouandaLocale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, locale.code);
  }

  Future<void> setLanguageByCode(String code) async {
    final locale = supportedLocales.firstWhere(
      (l) => l.code == code,
      orElse: () => supportedLocales[0],
    );
    await setLanguage(locale);
  }

  /// Quick translate helper
  String t(String key) => state.t(key);
}

final languageProvider = NotifierProvider<LanguageNotifier, WouandaLocale>(() {
  return LanguageNotifier();
});
