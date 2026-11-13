import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @trip_active.
  ///
  /// In fr, this message translates to:
  /// **'En course'**
  String get trip_active;

  /// No description provided for @trip_searching.
  ///
  /// In fr, this message translates to:
  /// **'Recherche...'**
  String get trip_searching;

  /// No description provided for @trip_driver_found.
  ///
  /// In fr, this message translates to:
  /// **'Chauffeur trouvé'**
  String get trip_driver_found;

  /// No description provided for @auth_login.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get auth_login;

  /// No description provided for @auth_register.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get auth_register;

  /// No description provided for @auth_access.
  ///
  /// In fr, this message translates to:
  /// **'Accédez à votre écosystème'**
  String get auth_access;

  /// No description provided for @auth_join.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez Wouanda'**
  String get auth_join;

  /// No description provided for @auth_email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get auth_email;

  /// No description provided for @auth_password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get auth_password;

  /// No description provided for @auth_forgot.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get auth_forgot;

  /// No description provided for @auth_no_account.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore membre ?'**
  String get auth_no_account;

  /// No description provided for @auth_has_account.
  ///
  /// In fr, this message translates to:
  /// **'Déjà membre ?'**
  String get auth_has_account;

  /// No description provided for @auth_create.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get auth_create;

  /// No description provided for @auth_enter.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get auth_enter;

  /// No description provided for @full_name.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get full_name;

  /// No description provided for @confirm_password.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirm_password;

  /// No description provided for @or_continue_with.
  ///
  /// In fr, this message translates to:
  /// **'ou continuer avec'**
  String get or_continue_with;

  /// No description provided for @discover_without_connect.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir sans se connecter'**
  String get discover_without_connect;

  /// No description provided for @forgot_title.
  ///
  /// In fr, this message translates to:
  /// **'Récupération'**
  String get forgot_title;

  /// No description provided for @forgot_desc.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre email pour recevoir un lien de réinitialisation.'**
  String get forgot_desc;

  /// No description provided for @send_reset_link.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get send_reset_link;

  /// No description provided for @email_sent.
  ///
  /// In fr, this message translates to:
  /// **'Lien envoyé !'**
  String get email_sent;

  /// No description provided for @email_sent_desc.
  ///
  /// In fr, this message translates to:
  /// **'Une invitation à réinitialiser votre mot de passe a été envoyée.'**
  String get email_sent_desc;

  /// No description provided for @back_to_login.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get back_to_login;

  /// No description provided for @remember_me.
  ///
  /// In fr, this message translates to:
  /// **'Se souvenir de moi'**
  String get remember_me;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @hub_services.
  ///
  /// In fr, this message translates to:
  /// **'Services Wouanda'**
  String get hub_services;

  /// No description provided for @hub_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Tout ce dont vous avez besoin, en un clic.'**
  String get hub_subtitle;

  /// No description provided for @hub_search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un service, lieu, produit...'**
  String get hub_search;

  /// No description provided for @hub_offers.
  ///
  /// In fr, this message translates to:
  /// **'Offres & Promotions'**
  String get hub_offers;

  /// No description provided for @nav_hub.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get nav_hub;

  /// No description provided for @nav_activity.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get nav_activity;

  /// No description provided for @nav_wallet.
  ///
  /// In fr, this message translates to:
  /// **'Pay'**
  String get nav_wallet;

  /// No description provided for @nav_profile.
  ///
  /// In fr, this message translates to:
  /// **'Moi'**
  String get nav_profile;

  /// No description provided for @nav_notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get nav_notifications;

  /// No description provided for @service_mobility.
  ///
  /// In fr, this message translates to:
  /// **'Mobilité'**
  String get service_mobility;

  /// No description provided for @service_shop.
  ///
  /// In fr, this message translates to:
  /// **'Shopping'**
  String get service_shop;

  /// No description provided for @service_events.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get service_events;

  /// No description provided for @service_love.
  ///
  /// In fr, this message translates to:
  /// **'Rencontres'**
  String get service_love;

  /// No description provided for @service_scanner.
  ///
  /// In fr, this message translates to:
  /// **'Scanner'**
  String get service_scanner;

  /// No description provided for @wallet_balance.
  ///
  /// In fr, this message translates to:
  /// **'Solde disponible'**
  String get wallet_balance;

  /// No description provided for @wallet_topup.
  ///
  /// In fr, this message translates to:
  /// **'Recharger'**
  String get wallet_topup;

  /// No description provided for @wallet_transfer.
  ///
  /// In fr, this message translates to:
  /// **'Transférer'**
  String get wallet_transfer;

  /// No description provided for @wallet_history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get wallet_history;

  /// No description provided for @wallet_cashback.
  ///
  /// In fr, this message translates to:
  /// **'Cashback'**
  String get wallet_cashback;

  /// No description provided for @wallet_points.
  ///
  /// In fr, this message translates to:
  /// **'Points fidélité'**
  String get wallet_points;

  /// No description provided for @wallet_pay.
  ///
  /// In fr, this message translates to:
  /// **'Payer'**
  String get wallet_pay;

  /// No description provided for @profile_title.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get profile_title;

  /// No description provided for @profile_edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get profile_edit;

  /// No description provided for @profile_kyc.
  ///
  /// In fr, this message translates to:
  /// **'Vérification d\'identité'**
  String get profile_kyc;

  /// No description provided for @profile_kyc_unverified.
  ///
  /// In fr, this message translates to:
  /// **'Non vérifié'**
  String get profile_kyc_unverified;

  /// No description provided for @profile_kyc_pending.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get profile_kyc_pending;

  /// No description provided for @profile_kyc_verified.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié'**
  String get profile_kyc_verified;

  /// No description provided for @profile_settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get profile_settings;

  /// No description provided for @profile_security.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get profile_security;

  /// No description provided for @profile_language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get profile_language;

  /// No description provided for @profile_dark_mode.
  ///
  /// In fr, this message translates to:
  /// **'Thème sombre'**
  String get profile_dark_mode;

  /// No description provided for @profile_help.
  ///
  /// In fr, this message translates to:
  /// **'Aide & Support'**
  String get profile_help;

  /// No description provided for @profile_about.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get profile_about;

  /// No description provided for @profile_privacy.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get profile_privacy;

  /// No description provided for @profile_trips.
  ///
  /// In fr, this message translates to:
  /// **'Mes courses'**
  String get profile_trips;

  /// No description provided for @profile_purchases.
  ///
  /// In fr, this message translates to:
  /// **'Mes achats'**
  String get profile_purchases;

  /// No description provided for @notif_today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get notif_today;

  /// No description provided for @notif_yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get notif_yesterday;

  /// No description provided for @notif_this_week.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get notif_this_week;

  /// No description provided for @notif_mark_all_read.
  ///
  /// In fr, this message translates to:
  /// **'Tout lire'**
  String get notif_mark_all_read;

  /// No description provided for @notif_empty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get notif_empty;

  /// No description provided for @scanner_title.
  ///
  /// In fr, this message translates to:
  /// **'Scanner'**
  String get scanner_title;

  /// No description provided for @scanner_universal.
  ///
  /// In fr, this message translates to:
  /// **'Scanner'**
  String get scanner_universal;

  /// No description provided for @scanner_payment.
  ///
  /// In fr, this message translates to:
  /// **'Payer'**
  String get scanner_payment;

  /// No description provided for @scanner_ticket.
  ///
  /// In fr, this message translates to:
  /// **'Ticket'**
  String get scanner_ticket;

  /// No description provided for @scanner_profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get scanner_profile;

  /// No description provided for @scanner_product.
  ///
  /// In fr, this message translates to:
  /// **'Produit'**
  String get scanner_product;

  /// No description provided for @scanner_my_qr.
  ///
  /// In fr, this message translates to:
  /// **'Mon QR'**
  String get scanner_my_qr;

  /// No description provided for @scanner_history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get scanner_history;

  /// No description provided for @scanner_gallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get scanner_gallery;

  /// No description provided for @onboarding_skip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get onboarding_skip;

  /// No description provided for @onboarding_next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get onboarding_next;

  /// No description provided for @onboarding_start.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboarding_start;

  /// No description provided for @onboarding_1_title.
  ///
  /// In fr, this message translates to:
  /// **'Un Écosystème Unifié'**
  String get onboarding_1_title;

  /// No description provided for @onboarding_1_desc.
  ///
  /// In fr, this message translates to:
  /// **'Tous vos services en une seule application.'**
  String get onboarding_1_desc;

  /// No description provided for @onboarding_2_title.
  ///
  /// In fr, this message translates to:
  /// **'Mobilité Intelligente'**
  String get onboarding_2_title;

  /// No description provided for @onboarding_2_desc.
  ///
  /// In fr, this message translates to:
  /// **'Commandez un trajet en quelques secondes.'**
  String get onboarding_2_desc;

  /// No description provided for @onboarding_3_title.
  ///
  /// In fr, this message translates to:
  /// **'Artisanat d\'Art'**
  String get onboarding_3_title;

  /// No description provided for @onboarding_3_desc.
  ///
  /// In fr, this message translates to:
  /// **'Achetez et vendez des créations faites main.'**
  String get onboarding_3_desc;

  /// No description provided for @onboarding_4_title.
  ///
  /// In fr, this message translates to:
  /// **'Événements Exclusifs'**
  String get onboarding_4_title;

  /// No description provided for @onboarding_4_desc.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez les meilleurs événements près de vous.'**
  String get onboarding_4_desc;

  /// No description provided for @onboarding_5_title.
  ///
  /// In fr, this message translates to:
  /// **'Rencontres Wouanda'**
  String get onboarding_5_title;

  /// No description provided for @onboarding_5_desc.
  ///
  /// In fr, this message translates to:
  /// **'Rencontrez des personnes qui partagent vos passions.'**
  String get onboarding_5_desc;

  /// No description provided for @profile_history.
  ///
  /// In fr, this message translates to:
  /// **'Historique & Activité'**
  String get profile_history;

  /// No description provided for @profile_payments.
  ///
  /// In fr, this message translates to:
  /// **'Moyens de paiement'**
  String get profile_payments;

  /// No description provided for @profile_wallet_payments.
  ///
  /// In fr, this message translates to:
  /// **'Wouanda Pay & Paiements'**
  String get profile_wallet_payments;

  /// No description provided for @profile_promos.
  ///
  /// In fr, this message translates to:
  /// **'Code Promo & Coupons'**
  String get profile_promos;

  /// No description provided for @profile_addresses.
  ///
  /// In fr, this message translates to:
  /// **'Adresses'**
  String get profile_addresses;

  /// No description provided for @profile_dock.
  ///
  /// In fr, this message translates to:
  /// **'Personnaliser le Dock'**
  String get profile_dock;

  /// No description provided for @profile_dock_sub.
  ///
  /// In fr, this message translates to:
  /// **'Position, Orientation, Taille'**
  String get profile_dock_sub;

  /// No description provided for @profile_notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get profile_notifications;

  /// No description provided for @profile_logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get profile_logout;

  /// No description provided for @profile_logout_success.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion réussie'**
  String get profile_logout_success;

  /// No description provided for @profile_logout_confirm_title.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get profile_logout_confirm_title;

  /// No description provided for @profile_logout_confirm_msg.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir vous déconnecter ?'**
  String get profile_logout_confirm_msg;

  /// No description provided for @profile_logout_action.
  ///
  /// In fr, this message translates to:
  /// **'Oui, se déconnecter'**
  String get profile_logout_action;

  /// No description provided for @profile_account.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get profile_account;

  /// No description provided for @profile_preferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get profile_preferences;

  /// No description provided for @profile_support.
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get profile_support;

  /// No description provided for @wallet_send.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get wallet_send;

  /// No description provided for @wallet_scan.
  ///
  /// In fr, this message translates to:
  /// **'Scanner'**
  String get wallet_scan;

  /// No description provided for @wallet_payment_methods.
  ///
  /// In fr, this message translates to:
  /// **'Moyens de paiement'**
  String get wallet_payment_methods;

  /// No description provided for @wallet_manage.
  ///
  /// In fr, this message translates to:
  /// **'Gérer'**
  String get wallet_manage;

  /// No description provided for @wallet_recent.
  ///
  /// In fr, this message translates to:
  /// **'Transactions Récentes'**
  String get wallet_recent;

  /// No description provided for @wallet_total_balance.
  ///
  /// In fr, this message translates to:
  /// **'Solde total'**
  String get wallet_total_balance;

  /// No description provided for @wallet_slogan.
  ///
  /// In fr, this message translates to:
  /// **'Et si tout se connectait enfin ?'**
  String get wallet_slogan;

  /// No description provided for @hub_exclusive_offers.
  ///
  /// In fr, this message translates to:
  /// **'Offres Exclusives'**
  String get hub_exclusive_offers;

  /// No description provided for @hub_premium_ride.
  ///
  /// In fr, this message translates to:
  /// **'Course Premium'**
  String get hub_premium_ride;

  /// No description provided for @hub_discount.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'à -20%'**
  String get hub_discount;

  /// No description provided for @hub_collection.
  ///
  /// In fr, this message translates to:
  /// **'Collection 2026'**
  String get hub_collection;

  /// No description provided for @hub_new.
  ///
  /// In fr, this message translates to:
  /// **'Nouveauté'**
  String get hub_new;

  /// No description provided for @scanner_scan_qr.
  ///
  /// In fr, this message translates to:
  /// **'Scannez un QR code ou code-barres'**
  String get scanner_scan_qr;

  /// No description provided for @scanner_pay_desc.
  ///
  /// In fr, this message translates to:
  /// **'Scannez pour payer via Wouanda Pay'**
  String get scanner_pay_desc;

  /// No description provided for @scanner_ticket_desc.
  ///
  /// In fr, this message translates to:
  /// **'Validez votre ticket d\'événement'**
  String get scanner_ticket_desc;

  /// No description provided for @scanner_profile_desc.
  ///
  /// In fr, this message translates to:
  /// **'Scannez pour ajouter un contact'**
  String get scanner_profile_desc;

  /// No description provided for @scanner_product_desc.
  ///
  /// In fr, this message translates to:
  /// **'Scannez un produit pour voir les détails'**
  String get scanner_product_desc;

  /// No description provided for @scanner_no_history.
  ///
  /// In fr, this message translates to:
  /// **'Aucun scan récent'**
  String get scanner_no_history;

  /// No description provided for @scanner_scan_history.
  ///
  /// In fr, this message translates to:
  /// **'Historique des scans'**
  String get scanner_scan_history;

  /// No description provided for @scanner_my_qr_desc.
  ///
  /// In fr, this message translates to:
  /// **'Partagez ce code pour recevoir des paiements\nou ajouter des contacts.'**
  String get scanner_my_qr_desc;

  /// No description provided for @scanner_result.
  ///
  /// In fr, this message translates to:
  /// **'Résultat scanné'**
  String get scanner_result;

  /// No description provided for @scanner_demo_payment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement détecté'**
  String get scanner_demo_payment;

  /// No description provided for @scanner_demo_ticket.
  ///
  /// In fr, this message translates to:
  /// **'Ticket événement validé'**
  String get scanner_demo_ticket;

  /// No description provided for @choose_language.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la langue'**
  String get choose_language;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @success.
  ///
  /// In fr, this message translates to:
  /// **'Succès'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @no_results.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get no_results;

  /// No description provided for @see_all.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get see_all;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get skip;

  /// No description provided for @get_started.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get get_started;

  /// No description provided for @done.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get done;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @offline_mode.
  ///
  /// In fr, this message translates to:
  /// **'Mode hors connexion'**
  String get offline_mode;

  /// No description provided for @offline_desc.
  ///
  /// In fr, this message translates to:
  /// **'Certaines fonctionnalités sont limitées.'**
  String get offline_desc;

  /// No description provided for @auth_required.
  ///
  /// In fr, this message translates to:
  /// **'Connexion requise'**
  String get auth_required;

  /// No description provided for @auth_required_desc.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour accéder à cette fonctionnalité.'**
  String get auth_required_desc;

  /// No description provided for @guest.
  ///
  /// In fr, this message translates to:
  /// **'Invité'**
  String get guest;

  /// No description provided for @card_add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une carte'**
  String get card_add;

  /// No description provided for @card_holder_name.
  ///
  /// In fr, this message translates to:
  /// **'Nom du titulaire'**
  String get card_holder_name;

  /// No description provided for @card_number.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de carte'**
  String get card_number;

  /// No description provided for @card_expiry.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'expiration'**
  String get card_expiry;

  /// No description provided for @card_cvv.
  ///
  /// In fr, this message translates to:
  /// **'CVV'**
  String get card_cvv;

  /// No description provided for @card_save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la carte'**
  String get card_save;

  /// No description provided for @card_add_action.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter la carte'**
  String get card_add_action;

  /// No description provided for @card_add_success.
  ///
  /// In fr, this message translates to:
  /// **'Carte ajoutée avec succès !'**
  String get card_add_success;

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Wouanda'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get homeTitle;

  /// No description provided for @shopTitle.
  ///
  /// In fr, this message translates to:
  /// **'Boutique'**
  String get shopTitle;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher sur Wouanda...'**
  String get searchHint;

  /// No description provided for @categoryAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get categoryAll;

  /// No description provided for @categoryMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode'**
  String get categoryMode;

  /// No description provided for @categoryTech.
  ///
  /// In fr, this message translates to:
  /// **'Tech'**
  String get categoryTech;

  /// No description provided for @categoryMaison.
  ///
  /// In fr, this message translates to:
  /// **'Maison'**
  String get categoryMaison;

  /// No description provided for @categoryAuto.
  ///
  /// In fr, this message translates to:
  /// **'Auto'**
  String get categoryAuto;

  /// No description provided for @categoryGaming.
  ///
  /// In fr, this message translates to:
  /// **'Gaming'**
  String get categoryGaming;

  /// No description provided for @categoryBeaute.
  ///
  /// In fr, this message translates to:
  /// **'Beauté'**
  String get categoryBeaute;

  /// No description provided for @categorySport.
  ///
  /// In fr, this message translates to:
  /// **'Sport'**
  String get categorySport;

  /// No description provided for @featuredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mises en avant'**
  String get featuredTitle;

  /// No description provided for @viewAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get viewAll;

  /// No description provided for @conditionNew.
  ///
  /// In fr, this message translates to:
  /// **'Neuf'**
  String get conditionNew;

  /// No description provided for @conditionUsed.
  ///
  /// In fr, this message translates to:
  /// **'Occasion'**
  String get conditionUsed;

  /// No description provided for @conditionRefurbished.
  ///
  /// In fr, this message translates to:
  /// **'Réconditionné'**
  String get conditionRefurbished;

  /// No description provided for @postProduct.
  ///
  /// In fr, this message translates to:
  /// **'Vendre un article'**
  String get postProduct;

  /// No description provided for @scanWithIA.
  ///
  /// In fr, this message translates to:
  /// **'AUTO-GÉNÉRER AVEC GEMMA 4'**
  String get scanWithIA;

  /// No description provided for @hubGreetingMorning.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, {name}'**
  String hubGreetingMorning(String name);

  /// No description provided for @hubGreetingEvening.
  ///
  /// In fr, this message translates to:
  /// **'Bonsoir, {name}'**
  String hubGreetingEvening(String name);

  /// No description provided for @hubGreetingGuest.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue'**
  String get hubGreetingGuest;

  /// No description provided for @hubMyServices.
  ///
  /// In fr, this message translates to:
  /// **'Mes services'**
  String get hubMyServices;

  /// No description provided for @hubContinue.
  ///
  /// In fr, this message translates to:
  /// **'À reprendre'**
  String get hubContinue;

  /// No description provided for @hubFeatured.
  ///
  /// In fr, this message translates to:
  /// **'À la une'**
  String get hubFeatured;

  /// No description provided for @hubSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Un service, une course, un billet…'**
  String get hubSearchHint;

  /// No description provided for @hubScan.
  ///
  /// In fr, this message translates to:
  /// **'Scanner'**
  String get hubScan;

  /// No description provided for @hubWalletActivate.
  ///
  /// In fr, this message translates to:
  /// **'Activer mon portefeuille'**
  String get hubWalletActivate;

  /// No description provided for @hubBalanceHide.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le solde'**
  String get hubBalanceHide;

  /// No description provided for @hubBalanceShow.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le solde'**
  String get hubBalanceShow;

  /// No description provided for @hubAllTile.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get hubAllTile;

  /// No description provided for @hubAllTileSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les services'**
  String get hubAllTileSubtitle;

  /// No description provided for @hubAllTileSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous les services'**
  String get hubAllTileSemantics;

  /// No description provided for @hubPromoCta.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get hubPromoCta;

  /// No description provided for @hubServicesUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Services indisponibles'**
  String get hubServicesUnavailable;

  /// No description provided for @catalogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tous les services'**
  String get catalogTitle;

  /// No description provided for @catalogEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Organiser l’accueil'**
  String get catalogEditTitle;

  /// No description provided for @catalogEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get catalogEdit;

  /// No description provided for @catalogDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get catalogDone;

  /// No description provided for @catalogSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Taxi, billet, logement…'**
  String get catalogSearchHint;

  /// No description provided for @catalogOnHome.
  ///
  /// In fr, this message translates to:
  /// **'Sur l’accueil ({count}/{max})'**
  String catalogOnHome(int count, int max);

  /// No description provided for @catalogOnHomeEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des services avec le bouton +.'**
  String get catalogOnHomeEmpty;

  /// No description provided for @catalogOthers.
  ///
  /// In fr, this message translates to:
  /// **'Autres services ({count})'**
  String catalogOthers(int count);

  /// No description provided for @catalogAllOnHome.
  ///
  /// In fr, this message translates to:
  /// **'Tous vos services sont sur l’accueil.'**
  String get catalogAllOnHome;

  /// No description provided for @catalogNoOtherMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucun autre service ne correspond à « {query} ».'**
  String catalogNoOtherMatch(String query);

  /// No description provided for @catalogNoMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucun service ne correspond à « {query} ».'**
  String catalogNoMatch(String query);

  /// No description provided for @catalogManageHidden.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les services masqués'**
  String get catalogManageHidden;

  /// No description provided for @catalogComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'{name} arrive bientôt.'**
  String catalogComingSoon(String name);

  /// No description provided for @catalogHomeFull.
  ///
  /// In fr, this message translates to:
  /// **'Accueil complet ({max} services). Retirez-en un d’abord.'**
  String catalogHomeFull(int max);

  /// No description provided for @catalogCannotPin.
  ///
  /// In fr, this message translates to:
  /// **'{name} ne peut pas être ajouté à l’accueil.'**
  String catalogCannotPin(String name);

  /// No description provided for @catalogNotSaved.
  ///
  /// In fr, this message translates to:
  /// **'Modification non enregistrée. Vérifiez la connexion et réessayez.'**
  String get catalogNotSaved;

  /// No description provided for @catalogOrderNotSaved.
  ///
  /// In fr, this message translates to:
  /// **'Ordre non enregistré. Vérifiez la connexion et réessayez.'**
  String get catalogOrderNotSaved;

  /// No description provided for @catalogRemoveFromHome.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de l’accueil'**
  String get catalogRemoveFromHome;

  /// No description provided for @catalogAddToHome.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à l’accueil'**
  String get catalogAddToHome;

  /// No description provided for @navActivity.
  ///
  /// In fr, this message translates to:
  /// **'Activité'**
  String get navActivity;

  /// No description provided for @navMessages.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @errorStateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Chargement impossible'**
  String get errorStateTitle;

  /// No description provided for @errorStateMessage.
  ///
  /// In fr, this message translates to:
  /// **'Réessayez pour charger les informations.'**
  String get errorStateMessage;

  /// No description provided for @errorStateRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get errorStateRetry;

  /// No description provided for @availabilityBeta.
  ///
  /// In fr, this message translates to:
  /// **'Bêta'**
  String get availabilityBeta;

  /// No description provided for @availabilityNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau'**
  String get availabilityNew;

  /// No description provided for @availabilitySoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt'**
  String get availabilitySoon;

  /// No description provided for @serviceHubLabel.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get serviceHubLabel;

  /// No description provided for @serviceHubDescription.
  ///
  /// In fr, this message translates to:
  /// **'Tous vos services en un seul point.'**
  String get serviceHubDescription;

  /// No description provided for @serviceGoLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mobilité'**
  String get serviceGoLabel;

  /// No description provided for @serviceGoTagline.
  ///
  /// In fr, this message translates to:
  /// **'Taxi et moto'**
  String get serviceGoTagline;

  /// No description provided for @serviceGoDescription.
  ///
  /// In fr, this message translates to:
  /// **'Courses, trajets et chauffeurs.'**
  String get serviceGoDescription;

  /// No description provided for @serviceShopLabel.
  ///
  /// In fr, this message translates to:
  /// **'Shop'**
  String get serviceShopLabel;

  /// No description provided for @serviceShopTagline.
  ///
  /// In fr, this message translates to:
  /// **'Près de vous'**
  String get serviceShopTagline;

  /// No description provided for @serviceShopDescription.
  ///
  /// In fr, this message translates to:
  /// **'Annonces locales et échanges entre particuliers.'**
  String get serviceShopDescription;

  /// No description provided for @serviceEventsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get serviceEventsLabel;

  /// No description provided for @serviceEventsTagline.
  ///
  /// In fr, this message translates to:
  /// **'Vos sorties'**
  String get serviceEventsTagline;

  /// No description provided for @serviceEventsDescription.
  ///
  /// In fr, this message translates to:
  /// **'Sorties, tickets et organisateurs.'**
  String get serviceEventsDescription;

  /// No description provided for @serviceLoveLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rencontres'**
  String get serviceLoveLabel;

  /// No description provided for @serviceLoveTagline.
  ///
  /// In fr, this message translates to:
  /// **'Se rencontrer'**
  String get serviceLoveTagline;

  /// No description provided for @serviceLoveDescription.
  ///
  /// In fr, this message translates to:
  /// **'Profils, matchs et conversations.'**
  String get serviceLoveDescription;

  /// No description provided for @serviceStayLabel.
  ///
  /// In fr, this message translates to:
  /// **'Séjour'**
  String get serviceStayLabel;

  /// No description provided for @serviceStayTagline.
  ///
  /// In fr, this message translates to:
  /// **'Où dormir'**
  String get serviceStayTagline;

  /// No description provided for @serviceStayDescription.
  ///
  /// In fr, this message translates to:
  /// **'Logements, réservations et hôtes.'**
  String get serviceStayDescription;

  /// No description provided for @serviceActivityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Activité'**
  String get serviceActivityLabel;

  /// No description provided for @serviceActivityDescription.
  ///
  /// In fr, this message translates to:
  /// **'Messages, commandes et historique.'**
  String get serviceActivityDescription;

  /// No description provided for @serviceAccountLabel.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get serviceAccountLabel;

  /// No description provided for @serviceAccountDescription.
  ///
  /// In fr, this message translates to:
  /// **'Profil, sécurité et préférences.'**
  String get serviceAccountDescription;

  /// No description provided for @serviceWalletLabel.
  ///
  /// In fr, this message translates to:
  /// **'Pay'**
  String get serviceWalletLabel;

  /// No description provided for @serviceWalletTagline.
  ///
  /// In fr, this message translates to:
  /// **'Payer, envoyer'**
  String get serviceWalletTagline;

  /// No description provided for @serviceWalletDescription.
  ///
  /// In fr, this message translates to:
  /// **'Paiements, solde et cartes.'**
  String get serviceWalletDescription;

  /// No description provided for @commonBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get commonBack;

  /// No description provided for @activityFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get activityFilterAll;

  /// No description provided for @activityEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité'**
  String get activityEmptyTitle;

  /// No description provided for @activityEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vos courses, paiements, billets et réservations apparaîtront ici.'**
  String get activityEmptyMessage;

  /// No description provided for @activityMore.
  ///
  /// In fr, this message translates to:
  /// **'Voir la suite'**
  String get activityMore;

  /// No description provided for @tripOfferSent.
  ///
  /// In fr, this message translates to:
  /// **'Proposition envoyée'**
  String get tripOfferSent;

  /// No description provided for @tripSearching.
  ///
  /// In fr, this message translates to:
  /// **'Recherche en cours'**
  String get tripSearching;

  /// No description provided for @tripInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Course en cours'**
  String get tripInProgress;

  /// No description provided for @tripDriverFound.
  ///
  /// In fr, this message translates to:
  /// **'Chauffeur trouvé'**
  String get tripDriverFound;

  /// No description provided for @tripDriverArriving.
  ///
  /// In fr, this message translates to:
  /// **'Votre chauffeur arrive'**
  String get tripDriverArriving;

  /// No description provided for @tripPickup.
  ///
  /// In fr, this message translates to:
  /// **'Au point de rendez-vous'**
  String get tripPickup;

  /// No description provided for @tripArrived.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes arrivé'**
  String get tripArrived;

  /// No description provided for @tripRating.
  ///
  /// In fr, this message translates to:
  /// **'Votre avis'**
  String get tripRating;

  /// No description provided for @tripFollow.
  ///
  /// In fr, this message translates to:
  /// **'Suivre ma course'**
  String get tripFollow;

  /// No description provided for @cancelReasonChangedPlans.
  ///
  /// In fr, this message translates to:
  /// **'Changement de programme'**
  String get cancelReasonChangedPlans;

  /// No description provided for @cancelReasonWaitTooLong.
  ///
  /// In fr, this message translates to:
  /// **'Attente trop longue'**
  String get cancelReasonWaitTooLong;

  /// No description provided for @cancelReasonPriceTooHigh.
  ///
  /// In fr, this message translates to:
  /// **'Prix trop élevé'**
  String get cancelReasonPriceTooHigh;

  /// No description provided for @cancelReasonWrongAddress.
  ///
  /// In fr, this message translates to:
  /// **'Mauvaise adresse'**
  String get cancelReasonWrongAddress;

  /// No description provided for @cancelReasonOtherTransport.
  ///
  /// In fr, this message translates to:
  /// **'Autre moyen de transport'**
  String get cancelReasonOtherTransport;

  /// No description provided for @cancelReasonOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre motif'**
  String get cancelReasonOther;

  /// No description provided for @cancelReasonDriverTooFar.
  ///
  /// In fr, this message translates to:
  /// **'Chauffeur trop loin'**
  String get cancelReasonDriverTooFar;

  /// No description provided for @cancelReasonDriverNotMoving.
  ///
  /// In fr, this message translates to:
  /// **'Le chauffeur n’avance pas'**
  String get cancelReasonDriverNotMoving;

  /// No description provided for @cancelReasonDriverAskedCancel.
  ///
  /// In fr, this message translates to:
  /// **'Le chauffeur m’a demandé d’annuler'**
  String get cancelReasonDriverAskedCancel;

  /// No description provided for @cancelReasonVehicleMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule ou plaque différents'**
  String get cancelReasonVehicleMismatch;

  /// No description provided for @cancelReasonUnsafeDriving.
  ///
  /// In fr, this message translates to:
  /// **'Conduite dangereuse'**
  String get cancelReasonUnsafeDriving;

  /// No description provided for @cancelReasonRouteNotFollowed.
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire non respecté'**
  String get cancelReasonRouteNotFollowed;

  /// No description provided for @cancelReasonStopHere.
  ///
  /// In fr, this message translates to:
  /// **'Je descends ici'**
  String get cancelReasonStopHere;

  /// No description provided for @cancelReasonVehicleIssue.
  ///
  /// In fr, this message translates to:
  /// **'Problème de véhicule'**
  String get cancelReasonVehicleIssue;

  /// No description provided for @cancelReasonPassengerAsked.
  ///
  /// In fr, this message translates to:
  /// **'Le passager a demandé d’annuler'**
  String get cancelReasonPassengerAsked;

  /// No description provided for @cancelReasonPickupUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Départ inaccessible'**
  String get cancelReasonPickupUnreachable;

  /// No description provided for @cancelReasonTooFar.
  ///
  /// In fr, this message translates to:
  /// **'Départ trop loin'**
  String get cancelReasonTooFar;

  /// No description provided for @cancelReasonTooManyPassengers.
  ///
  /// In fr, this message translates to:
  /// **'Trop de passagers'**
  String get cancelReasonTooManyPassengers;

  /// No description provided for @cancelReasonTooMuchLuggage.
  ///
  /// In fr, this message translates to:
  /// **'Trop de bagages'**
  String get cancelReasonTooMuchLuggage;

  /// No description provided for @cancelReasonChildSeatNeeded.
  ///
  /// In fr, this message translates to:
  /// **'Siège enfant nécessaire'**
  String get cancelReasonChildSeatNeeded;

  /// No description provided for @cancelReasonPassengerBehavior.
  ///
  /// In fr, this message translates to:
  /// **'Comportement du passager'**
  String get cancelReasonPassengerBehavior;

  /// No description provided for @cancelReasonUnsafe.
  ///
  /// In fr, this message translates to:
  /// **'Je ne me sens pas en sécurité'**
  String get cancelReasonUnsafe;

  /// No description provided for @cancelTitleRide.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la course ?'**
  String get cancelTitleRide;

  /// No description provided for @cancelTitleStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter la course ?'**
  String get cancelTitleStop;

  /// No description provided for @cancelTitleBooking.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la réservation ?'**
  String get cancelTitleBooking;

  /// No description provided for @cancelFree.
  ///
  /// In fr, this message translates to:
  /// **'Annulation gratuite'**
  String get cancelFree;

  /// No description provided for @cancelFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais d’annulation : {amount}'**
  String cancelFee(String amount);

  /// No description provided for @cancelOutcomeRematch.
  ///
  /// In fr, this message translates to:
  /// **'Le passager est remis en recherche, au même prix'**
  String get cancelOutcomeRematch;

  /// No description provided for @cancelOutcomeEnd.
  ///
  /// In fr, this message translates to:
  /// **'Le trajet déjà parcouru est facturé'**
  String get cancelOutcomeEnd;

  /// No description provided for @cancelNoteLabel.
  ///
  /// In fr, this message translates to:
  /// **'Précisez en quelques mots'**
  String get cancelNoteLabel;

  /// No description provided for @cancelSafetyHint.
  ///
  /// In fr, this message translates to:
  /// **'En danger ? Prévenez Wouanda et vos proches.'**
  String get cancelSafetyHint;

  /// No description provided for @cancelSafetyAction.
  ///
  /// In fr, this message translates to:
  /// **'Alerte'**
  String get cancelSafetyAction;

  /// No description provided for @cancelConfirmRide.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la course'**
  String get cancelConfirmRide;

  /// No description provided for @cancelConfirmStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter la course'**
  String get cancelConfirmStop;

  /// No description provided for @cancelConfirmBooking.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la réservation'**
  String get cancelConfirmBooking;

  /// No description provided for @cancelKeepRide.
  ///
  /// In fr, this message translates to:
  /// **'Garder la course'**
  String get cancelKeepRide;

  /// No description provided for @cancelKeepGoing.
  ///
  /// In fr, this message translates to:
  /// **'Continuer la course'**
  String get cancelKeepGoing;

  /// No description provided for @cancelKeepBooking.
  ///
  /// In fr, this message translates to:
  /// **'Garder la réservation'**
  String get cancelKeepBooking;

  /// No description provided for @cancelBusy.
  ///
  /// In fr, this message translates to:
  /// **'Annulation…'**
  String get cancelBusy;

  /// No description provided for @cancelLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Motifs indisponibles'**
  String get cancelLoadError;

  /// No description provided for @cancelFailed.
  ///
  /// In fr, this message translates to:
  /// **'Annulation non confirmée. La course continue.'**
  String get cancelFailed;

  /// No description provided for @cancelReasonDriverAskedMoreMoney.
  ///
  /// In fr, this message translates to:
  /// **'Le chauffeur demande plus d’argent'**
  String get cancelReasonDriverAskedMoreMoney;

  /// No description provided for @cancelReasonDriverRefusedDestination.
  ///
  /// In fr, this message translates to:
  /// **'Le chauffeur refuse ma destination'**
  String get cancelReasonDriverRefusedDestination;

  /// No description provided for @cancelReasonPassengerUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Passager injoignable'**
  String get cancelReasonPassengerUnreachable;

  /// No description provided for @cancelReasonPassengerPriceDispute.
  ///
  /// In fr, this message translates to:
  /// **'Désaccord sur le prix'**
  String get cancelReasonPassengerPriceDispute;

  /// No description provided for @cancelSaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Action impossible. Réessayez ou annulez.'**
  String get cancelSaveFailed;

  /// No description provided for @cancelFreeWhy.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit · {why}'**
  String cancelFreeWhy(String why);

  /// No description provided for @cancelWaiverFreeWindow.
  ///
  /// In fr, this message translates to:
  /// **'dans les 2 minutes après l’attribution'**
  String get cancelWaiverFreeWindow;

  /// No description provided for @cancelWaiverDriverLate.
  ///
  /// In fr, this message translates to:
  /// **'le chauffeur a dépassé l’heure prévue'**
  String get cancelWaiverDriverLate;

  /// No description provided for @cancelWaiverDriverFault.
  ///
  /// In fr, this message translates to:
  /// **'vous n’êtes pas en cause'**
  String get cancelWaiverDriverFault;

  /// No description provided for @cancelWaiverBeforeAssignment.
  ///
  /// In fr, this message translates to:
  /// **'aucun chauffeur attribué'**
  String get cancelWaiverBeforeAssignment;

  /// No description provided for @cancelWaiverNoFault.
  ///
  /// In fr, this message translates to:
  /// **'personne n’est en cause'**
  String get cancelWaiverNoFault;

  /// No description provided for @cancelInRideCharged.
  ///
  /// In fr, this message translates to:
  /// **'Seul le trajet parcouru est facturé'**
  String get cancelInRideCharged;

  /// No description provided for @cancelInRideFree.
  ///
  /// In fr, this message translates to:
  /// **'Rien n’est facturé'**
  String get cancelInRideFree;

  /// No description provided for @cancelSaveRematch.
  ///
  /// In fr, this message translates to:
  /// **'Chercher un autre chauffeur · même prix'**
  String get cancelSaveRematch;

  /// No description provided for @cancelSaveChangePickup.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le point de départ'**
  String get cancelSaveChangePickup;

  /// No description provided for @cancelSaveUpdateOffer.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mon offre'**
  String get cancelSaveUpdateOffer;

  /// No description provided for @cancelSaveContactPassenger.
  ///
  /// In fr, this message translates to:
  /// **'Appeler le passager'**
  String get cancelSaveContactPassenger;

  /// No description provided for @changePickupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le départ'**
  String get changePickupTitle;

  /// No description provided for @changePickupSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'À 300 m au plus, le prix ne change pas'**
  String get changePickupSubtitle;

  /// No description provided for @changePickupHint.
  ///
  /// In fr, this message translates to:
  /// **'Adresse proche'**
  String get changePickupHint;

  /// No description provided for @changePickupTooFar.
  ///
  /// In fr, this message translates to:
  /// **'Trop loin ({distance}) : annulez et commandez à nouveau'**
  String changePickupTooFar(String distance);

  /// No description provided for @changePickupDone.
  ///
  /// In fr, this message translates to:
  /// **'Point de départ modifié'**
  String get changePickupDone;

  /// No description provided for @driverCancellationRate.
  ///
  /// In fr, this message translates to:
  /// **'Annulations · 30 jours'**
  String get driverCancellationRate;

  /// No description provided for @driverCancellationRateDetail.
  ///
  /// In fr, this message translates to:
  /// **'{faults} sur {rides} courses'**
  String driverCancellationRateDetail(int faults, int rides);

  /// No description provided for @pickupImprecise.
  ///
  /// In fr, this message translates to:
  /// **'Position imprécise (± {meters} m) : vérifiez le point.'**
  String pickupImprecise(int meters);

  /// No description provided for @pickupAdjustOnMap.
  ///
  /// In fr, this message translates to:
  /// **'Ajuster sur la carte'**
  String get pickupAdjustOnMap;

  /// No description provided for @pickupSuggestedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Points de départ conseillés'**
  String get pickupSuggestedTitle;

  /// No description provided for @pickupSuggestionPlace.
  ///
  /// In fr, this message translates to:
  /// **'Lieu public · {distance}'**
  String pickupSuggestionPlace(String distance);

  /// No description provided for @pickupSuggestionUsual.
  ///
  /// In fr, this message translates to:
  /// **'Départ habituel · {distance}'**
  String pickupSuggestionUsual(String distance);

  /// No description provided for @pickupYourLandmarks.
  ///
  /// In fr, this message translates to:
  /// **'Vos repères ici'**
  String get pickupYourLandmarks;

  /// No description provided for @pickupConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le départ'**
  String get pickupConfirm;

  /// No description provided for @pickupMoved.
  ///
  /// In fr, this message translates to:
  /// **'Départ déplacé : le prix est mis à jour.'**
  String get pickupMoved;

  /// No description provided for @pickupSharingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le chauffeur voit où vous êtes'**
  String get pickupSharingTitle;

  /// No description provided for @pickupSharingWaiting.
  ///
  /// In fr, this message translates to:
  /// **'À l’approche du chauffeur'**
  String get pickupSharingWaiting;

  /// No description provided for @pickupSharingLive.
  ///
  /// In fr, this message translates to:
  /// **'Partagé maintenant'**
  String get pickupSharingLive;

  /// No description provided for @pickupSharingOff.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get pickupSharingOff;

  /// No description provided for @driverPassengerHere.
  ///
  /// In fr, this message translates to:
  /// **'Le passager est ici'**
  String get driverPassengerHere;

  /// No description provided for @driverPassengerAccuracy.
  ///
  /// In fr, this message translates to:
  /// **'Position du passager · ± {meters} m'**
  String driverPassengerAccuracy(int meters);

  /// No description provided for @quickReplyComing.
  ///
  /// In fr, this message translates to:
  /// **'J’arrive dans quelques minutes'**
  String get quickReplyComing;

  /// No description provided for @quickReplyTraffic.
  ///
  /// In fr, this message translates to:
  /// **'Je suis pris dans les embouteillages'**
  String get quickReplyTraffic;

  /// No description provided for @quickReplyWhereExactly.
  ///
  /// In fr, this message translates to:
  /// **'Pouvez-vous préciser le point de rendez-vous ?'**
  String get quickReplyWhereExactly;

  /// No description provided for @quickReplyArrived.
  ///
  /// In fr, this message translates to:
  /// **'Je suis arrivé au point de rendez-vous'**
  String get quickReplyArrived;

  /// No description provided for @quickReplyWaitingFront.
  ///
  /// In fr, this message translates to:
  /// **'Je vous attends devant'**
  String get quickReplyWaitingFront;

  /// No description provided for @quickReplyCallMe.
  ///
  /// In fr, this message translates to:
  /// **'Je ne vous trouve pas, pouvez-vous m’appeler ?'**
  String get quickReplyCallMe;

  /// No description provided for @quickReplyComingDown.
  ///
  /// In fr, this message translates to:
  /// **'J’arrive'**
  String get quickReplyComingDown;

  /// No description provided for @quickReplyWait2min.
  ///
  /// In fr, this message translates to:
  /// **'J’arrive dans 2 minutes'**
  String get quickReplyWait2min;

  /// No description provided for @quickReplyAtLandmark.
  ///
  /// In fr, this message translates to:
  /// **'Je suis au repère'**
  String get quickReplyAtLandmark;

  /// No description provided for @quickReplyAtLandmarkWith.
  ///
  /// In fr, this message translates to:
  /// **'Je suis au repère : {landmark}'**
  String quickReplyAtLandmarkWith(String landmark);

  /// No description provided for @homeEta.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String homeEta(int minutes);

  /// No description provided for @homeNoDriver.
  ///
  /// In fr, this message translates to:
  /// **'Aucun chauffeur'**
  String get homeNoDriver;

  /// No description provided for @homePickupSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Départ : {address}. Modifier'**
  String homePickupSemantics(String address);

  /// No description provided for @homeLocationOff.
  ///
  /// In fr, this message translates to:
  /// **'Position inconnue'**
  String get homeLocationOff;

  /// No description provided for @homeLocationAction.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get homeLocationAction;

  /// No description provided for @homeAddPlace.
  ///
  /// In fr, this message translates to:
  /// **'Maison ou Bureau'**
  String get homeAddPlace;

  /// No description provided for @homeAllPlaces.
  ///
  /// In fr, this message translates to:
  /// **'Lieux'**
  String get homeAllPlaces;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
