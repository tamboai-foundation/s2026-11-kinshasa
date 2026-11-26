import 'package:flutter/material.dart';
import 'package:ngoma_design/ngoma_design.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ngoma/core/theme.dart';

/// Every service and platform space of the super-app.
///
/// This catalogue is THE single source of truth (like a mini-app manifest in
/// WeChat or Alipay): home grid, "Tous les services", profile spaces,
/// settings and notification channels are all generated from it. Plugging a
/// new service in = adding one [NgomaServiceDefinition] here.
enum NgomaServiceId {
  hub,
  mobility,
  market,
  events,
  love,
  stay,
  activity,
  account,
  wallet,
}

/// How services are grouped in "Tous les services".
enum NgomaServiceCategory {
  mobility('Se déplacer', LucideIcons.navigation),
  shopping('Acheter', LucideIcons.shoppingBag),
  outings('Sortir', LucideIcons.partyPopper),
  travel('Voyager', LucideIcons.plane),
  social('Rencontrer', LucideIcons.heartHandshake),
  finance('Finances', LucideIcons.wallet),
  platform('NGoma', LucideIcons.layoutGrid);

  final String label;
  final IconData icon;
  const NgomaServiceCategory(this.label, this.icon);
}

/// Release stage shown as a badge; `comingSoon` services are listed but not
/// openable.
enum NgomaServiceAvailability { available, beta, isNew, comingSoon }

/// A notification stream a service can send. Users toggle channels one by
/// one; `critical` channels (security, payments) cannot be muted.
class NgomaNotificationChannel {
  final String key;
  final String label;
  final String description;
  final bool enabledByDefault;
  final bool critical;

  const NgomaNotificationChannel({
    required this.key,
    required this.label,
    required this.description,
    this.enabledByDefault = true,
    this.critical = false,
  });
}

/// A professional space a user can open inside a service (host, seller…).
class NgomaProSpace {
  /// Role key stored on the account (`UserServiceProfile.roles`).
  final String role;
  final String title;
  final String pitch;
  final IconData icon;

  /// Where an active professional manages the space.
  final String manageRoute;

  /// Where a user starts the onboarding for this space.
  final String becomeRoute;

  const NgomaProSpace({
    required this.role,
    required this.title,
    required this.pitch,
    required this.icon,
    required this.manageRoute,
    required this.becomeRoute,
  });
}

class NgomaServiceDefinition {
  final NgomaServiceId id;
  final String key;
  final String label;
  final String productName;
  final String shortDescription;
  final String route;
  final IconData icon;
  final Color color;
  final Color lightColor;
  final String logoAsset;
  final bool appearsInHub;
  final int? shellBranchIndex;
  final NgomaServiceCategory category;
  final NgomaServiceAvailability availability;

  /// Extra words matched by the service search ("taxi" finds Go).
  final List<String> keywords;
  final List<NgomaNotificationChannel> notificationChannels;
  final List<NgomaProSpace> proSpaces;

  /// Service-specific settings page, when the service has one.
  final String? settingsRoute;

  /// Pinned on the home grid for a new user.
  final bool pinnedByDefault;

  /// Whether the service may appear in the home grid. False for a service
  /// that already owns a NGoma space (Pay: the Pay tab and the home wallet
  /// card): one destination, one entry per screen. Enforced by the hub
  /// bridge.
  final bool pinnable;

  /// Short line under the name on the home grid ("Taxi et moto"); at most
  /// 14 characters so it never truncates on the 3-column grid.
  final String? tagline;

  /// Artwork of the home grid; the flat [icon] is used when absent.
  final String? illustrationAsset;
  final double illustrationScale;

  const NgomaServiceDefinition({
    required this.id,
    required this.key,
    required this.label,
    required this.productName,
    required this.shortDescription,
    required this.route,
    required this.icon,
    required this.color,
    required this.lightColor,
    required this.logoAsset,
    required this.category,
    this.appearsInHub = true,
    this.shellBranchIndex,
    this.availability = NgomaServiceAvailability.available,
    this.keywords = const [],
    this.notificationChannels = const [],
    this.proSpaces = const [],
    this.settingsRoute,
    this.pinnedByDefault = true,
    this.pinnable = true,
    this.tagline,
    this.illustrationAsset,
    this.illustrationScale = 1.25,
  });

  bool get isOpenable => availability != NgomaServiceAvailability.comingSoon;

  /// Case-insensitive match on names, description and keywords.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      label,
      productName,
      shortDescription,
      category.label,
      ...keywords,
    ].any((value) => value.toLowerCase().contains(q));
  }
}

class NgomaServiceRegistry {
  NgomaServiceRegistry._();

  static List<NgomaServiceDefinition> all = [
    NgomaServiceDefinition(
      id: NgomaServiceId.hub,
      key: 'hub',
      label: 'Accueil',
      productName: 'NGoma',
      shortDescription: 'Tous vos services en un seul point.',
      route: '/hub',
      icon: LucideIcons.layoutGrid,
      color: NgomaColors.brand,
      lightColor: NgomaColors.surfaceLight,
      logoAsset: 'assets/images/ngoma.png',
      category: NgomaServiceCategory.platform,
      appearsInHub: false,
      shellBranchIndex: 0,
      notificationChannels: [
        NgomaNotificationChannel(
          key: 'offers',
          label: 'Offres et nouveautés',
          description: 'Promotions et nouveaux services NGoma.',
          enabledByDefault: false,
        ),
        NgomaNotificationChannel(
          key: 'weeklyReport',
          label: 'Résumé hebdomadaire',
          description: 'Vos dépenses et activités de la semaine.',
          enabledByDefault: false,
        ),
      ],
    ),
    NgomaServiceDefinition(
      id: NgomaServiceId.mobility,
      key: 'go',
      tagline: 'Taxi et moto',
      illustrationScale: 1.55,
      label: 'Mobilité',
      productName: 'NGoma Go',
      shortDescription: 'Courses, trajets et chauffeurs.',
      route: '/mobility',
      icon: LucideIcons.car,
      color: AppTheme.ngomaGo,
      lightColor: AppTheme.ngomaGoLight,
      logoAsset: 'assets/images/ngoma.png',
      category: NgomaServiceCategory.mobility,
      shellBranchIndex: 1,
      keywords: ['taxi', 'course', 'vtc', 'moto', 'trajet', 'chauffeur'],
      settingsRoute: '/mobility/settings',
      notificationChannels: [
        NgomaNotificationChannel(
          key: 'trips',
          label: 'Suivi des courses',
          description: 'Chauffeur trouvé, arrivée, fin de course.',
          critical: true,
        ),
        // The driver's two streams. Both are critical: a request that is not
        // heard is a lost ride, and a document or a rest limit that is not
        // read is a driver put off the road without warning.
        NgomaNotificationChannel(
          key: 'driverRequests',
          label: 'Demandes de course',
          description: 'Nouvelle demande, annulation, réservation.',
          critical: true,
        ),
        NgomaNotificationChannel(
          key: 'driverAccount',
          label: 'Compte chauffeur',
          description: 'Documents à renouveler, pause, versements.',
          critical: true,
        ),
        NgomaNotificationChannel(
          key: 'promos',
          label: 'Promotions Go',
          description: 'Réductions sur vos prochains trajets.',
        ),
      ],
      proSpaces: [
        NgomaProSpace(
          role: 'driver',
          title: 'Chauffeur Go',
          pitch: 'Conduisez et encaissez vos courses.',
          icon: LucideIcons.car,
          manageRoute: '/driver',
          becomeRoute: '/mobility/become-driver',
        ),
      ],
    ),
    NgomaServiceDefinition(
      id: NgomaServiceId.market,
      key: 'shop',
      tagline: 'Près de vous',
      illustrationScale: 1.28,
      label: 'Shop',
      productName: 'NGoma Shop',
      shortDescription: 'Annonces locales et échanges entre particuliers.',
      route: '/commerce',
      icon: LucideIcons.shoppingBag,
      color: AppTheme.ngomaShop,
      lightColor: AppTheme.ngomaShopLight,
      logoAsset: 'assets/images/ngoma.png',
      category: NgomaServiceCategory.shopping,
      shellBranchIndex: 2,
      keywords: ['boutique', 'acheter', 'vendre', 'artisan', 'marché'],
      notificationChannels: [
        NgomaNotificationChannel(
          key: 'messages',
          label: 'Messages acheteurs et vendeurs',
          description: 'Questions, propositions et conversations.',
        ),
      ],
      proSpaces: [
        NgomaProSpace(
          role: 'seller',
          title: 'Vendeur Shop',
          pitch: 'Publiez vos annonces et rencontrez vos acheteurs.',
          icon: LucideIcons.store,
          manageRoute: '/commerce?selling=true',
          becomeRoute: '/commerce?selling=true',
        ),
      ],
    ),
    NgomaServiceDefinition(
      id: NgomaServiceId.events,
      key: 'events',
      tagline: 'Vos sorties',
      illustrationScale: 1.18,
      label: 'Événements',
      productName: 'NGoma Events',
      shortDescription: 'Sorties, tickets et organisateurs.',
      route: '/events',
      icon: LucideIcons.calendar,
      color: AppTheme.ngomaEvents,
      lightColor: AppTheme.ngomaEventsLight,
      logoAsset: 'assets/images/ngoma.png',
      category: NgomaServiceCategory.outings,
      shellBranchIndex: 7,
      keywords: ['concert', 'billet', 'ticket', 'soirée', 'festival'],
      notificationChannels: [
        NgomaNotificationChannel(
          key: 'reminders',
          label: 'Rappels de billets',
          description: 'Veille et jour de vos événements.',
        ),
        NgomaNotificationChannel(
          key: 'sales',
          label: 'Ventes organisateur',
          description: 'Billets vendus et entrées validées.',
        ),
      ],
      proSpaces: [
        NgomaProSpace(
          role: 'organizer',
          title: 'Organisateur Events',
          pitch: 'Publiez vos événements et vendez des billets.',
          icon: LucideIcons.ticket,
          manageRoute: '/events/dashboard',
          becomeRoute: '/events/create-org',
        ),
      ],
    ),
    NgomaServiceDefinition(
      id: NgomaServiceId.love,
      key: 'love',
      tagline: 'Se rencontrer',
      illustrationScale: 1.28,
      label: 'Rencontres',
      productName: 'NGoma Love',
      shortDescription: 'Profils, matchs et conversations.',
      route: '/dating',
      icon: LucideIcons.heart,
      color: AppTheme.ngomaLove,
      lightColor: AppTheme.ngomaLoveLight,
      logoAsset: 'assets/images/ngoma.png',
      category: NgomaServiceCategory.social,
      shellBranchIndex: 6,
      keywords: ['rencontre', 'match', 'amour', 'date'],
      pinnedByDefault: false,
      notificationChannels: [
        NgomaNotificationChannel(
          key: 'matches',
          label: 'Nouveaux matchs',
          description: 'Quand un profil vous plaît aussi.',
        ),
        NgomaNotificationChannel(
          key: 'messages',
          label: 'Messages',
          description: 'Conversations et propositions de sortie.',
        ),
      ],
    ),
    NgomaServiceDefinition(
      id: NgomaServiceId.stay,
      key: 'stay',
      tagline: 'Où dormir',
      illustrationScale: 1.34,
      label: 'Séjour',
      productName: 'NGoma Stay',
      shortDescription: 'Logements, réservations et hôtes.',
      route: '/stay',
      icon: LucideIcons.building2,
      color: AppTheme.ngomaStay,
      lightColor: AppTheme.ngomaStayLight,
      logoAsset: 'assets/images/ngoma.png',
      category: NgomaServiceCategory.travel,
      shellBranchIndex: 8,
      keywords: ['hôtel', 'logement', 'appartement', 'location', 'nuit'],
      notificationChannels: [
        NgomaNotificationChannel(
          key: 'reservations',
          label: 'Réservations',
          description: 'Demandes, confirmations et arrivées.',
          critical: true,
        ),
        NgomaNotificationChannel(
          key: 'promos',
          label: 'Offres de séjour',
          description: 'Promotions sur vos destinations.',
          enabledByDefault: false,
        ),
      ],
      proSpaces: [
        NgomaProSpace(
          role: 'host',
          title: 'Hôte Stay',
          pitch: 'Louez votre logement et suivez vos revenus.',
          icon: LucideIcons.house,
          manageRoute: '/stay?tab=manage',
          becomeRoute: '/stay?tab=manage',
        ),
      ],
    ),
    NgomaServiceDefinition(
      id: NgomaServiceId.activity,
      key: 'activity',
      label: 'Activité',
      productName: 'Activité NGoma',
      shortDescription: 'Messages, commandes et historique.',
      route: '/activity',
      icon: LucideIcons.history,
      color: AppTheme.secondary,
      lightColor: NgomaColors.surfaceLight,
      logoAsset: 'assets/images/ngoma.png',
      category: NgomaServiceCategory.platform,
      appearsInHub: false,
      shellBranchIndex: 4,
    ),
    NgomaServiceDefinition(
      id: NgomaServiceId.account,
      key: 'account',
      label: 'Compte',
      productName: 'Compte NGoma',
      shortDescription: 'Profil, sécurité et préférences.',
      route: '/profile',
      icon: LucideIcons.user,
      color: NgomaColors.brand,
      lightColor: NgomaColors.surfaceLight,
      logoAsset: 'assets/images/ngoma.png',
      category: NgomaServiceCategory.platform,
      appearsInHub: false,
      shellBranchIndex: 5,
      notificationChannels: [
        NgomaNotificationChannel(
          key: 'security',
          label: 'Sécurité du compte',
          description: 'Nouvelle connexion, changement de mot de passe.',
          critical: true,
        ),
      ],
    ),
    NgomaServiceDefinition(
      id: NgomaServiceId.wallet,
      key: 'wallet',
      pinnable: false,
      pinnedByDefault: false,
      tagline: 'Payer, envoyer',
      label: 'Pay',
      productName: 'NGoma Pay',
      shortDescription: 'Paiements, solde et cartes.',
      route: '/profile/wallet',
      icon: LucideIcons.wallet,
      color: AppTheme.success,
      lightColor: AppTheme.successLight,
      logoAsset: 'assets/images/ngoma.png',
      category: NgomaServiceCategory.finance,
      keywords: ['payer', 'portefeuille', 'solde', 'recharger', 'transfert'],
      notificationChannels: [
        NgomaNotificationChannel(
          key: 'transactions',
          label: 'Transactions',
          description: 'Paiements, recharges et transferts.',
          critical: true,
        ),
      ],
    ),
  ];

  /// Services a user opens (as opposed to platform spaces such as Activité).
  static List<NgomaServiceDefinition> get hubServices =>
      all.where((service) => service.appearsInHub).toList(growable: false);

  /// Everything listed in "Tous les services", Pay included (its tile opens
  /// the wallet). Only the home grid leaves Pay out: see [pinnable].
  static List<NgomaServiceDefinition> get catalog =>
      all.where((service) => service.appearsInHub).toList(growable: false);

  /// Services that expose at least one notification channel.
  static List<NgomaServiceDefinition> get withNotifications => all
      .where((service) => service.notificationChannels.isNotEmpty)
      .toList(growable: false);

  static List<String> get userServiceKeys =>
      hubServices.map((service) => service.key).toList(growable: false);

  static List<String> get platformServiceKeys => const [
    'activity',
    'account',
    'wallet',
  ];

  static List<String> get defaultActiveServiceKeys => [
    ...userServiceKeys,
    ...platformServiceKeys,
  ];

  static List<String> get allServiceKeys =>
      all.map((service) => service.key).toList(growable: false);

  static NgomaServiceDefinition byId(NgomaServiceId id) {
    return all.firstWhere((service) => service.id == id);
  }

  static NgomaServiceDefinition byKey(String key) {
    return all.firstWhere(
      (service) => service.key == key,
      orElse: () => byId(NgomaServiceId.hub),
    );
  }

  static NgomaServiceDefinition? tryByKey(String key) {
    for (final service in all) {
      if (service.key == key) return service;
    }
    return null;
  }

  static NgomaServiceDefinition byRoute(String route) {
    return all.firstWhere(
      (service) =>
          route == service.route || route.startsWith('${service.route}/'),
      orElse: () => byId(NgomaServiceId.hub),
    );
  }

  static NgomaServiceDefinition? byShellBranchIndex(int branchIndex) {
    for (final service in all) {
      if (service.shellBranchIndex == branchIndex) return service;
    }
    return null;
  }
}
