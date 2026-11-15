import 'package:flutter/material.dart';
import 'package:wouanda_design/wouanda_design.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ngoma/core/theme.dart';

/// Every service and platform space of the super-app.
///
/// This catalogue is THE single source of truth (like a mini-app manifest in
/// WeChat or Alipay): home grid, "Tous les services", profile spaces,
/// settings and notification channels are all generated from it. Plugging a
/// new service in = adding one [WouandaServiceDefinition] here.
enum WouandaServiceId {
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
enum WouandaServiceCategory {
  mobility('Se déplacer', LucideIcons.navigation),
  shopping('Acheter', LucideIcons.shoppingBag),
  outings('Sortir', LucideIcons.partyPopper),
  travel('Voyager', LucideIcons.plane),
  social('Rencontrer', LucideIcons.heartHandshake),
  finance('Finances', LucideIcons.wallet),
  platform('Wouanda', LucideIcons.layoutGrid);

  final String label;
  final IconData icon;
  const WouandaServiceCategory(this.label, this.icon);
}

/// Release stage shown as a badge; `comingSoon` services are listed but not
/// openable.
enum WouandaServiceAvailability { available, beta, isNew, comingSoon }

/// A notification stream a service can send. Users toggle channels one by
/// one; `critical` channels (security, payments) cannot be muted.
class WouandaNotificationChannel {
  final String key;
  final String label;
  final String description;
  final bool enabledByDefault;
  final bool critical;

  const WouandaNotificationChannel({
    required this.key,
    required this.label,
    required this.description,
    this.enabledByDefault = true,
    this.critical = false,
  });
}

/// A professional space a user can open inside a service (host, seller…).
class WouandaProSpace {
  /// Role key stored on the account (`UserServiceProfile.roles`).
  final String role;
  final String title;
  final String pitch;
  final IconData icon;

  /// Where an active professional manages the space.
  final String manageRoute;

  /// Where a user starts the onboarding for this space.
  final String becomeRoute;

  const WouandaProSpace({
    required this.role,
    required this.title,
    required this.pitch,
    required this.icon,
    required this.manageRoute,
    required this.becomeRoute,
  });
}

class WouandaServiceDefinition {
  final WouandaServiceId id;
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
  final WouandaServiceCategory category;
  final WouandaServiceAvailability availability;

  /// Extra words matched by the service search ("taxi" finds Go).
  final List<String> keywords;
  final List<WouandaNotificationChannel> notificationChannels;
  final List<WouandaProSpace> proSpaces;

  /// Service-specific settings page, when the service has one.
  final String? settingsRoute;

  /// Pinned on the home grid for a new user.
  final bool pinnedByDefault;

  /// Whether the service may appear in the home grid. False for a service
  /// that already owns a Wouanda space (Pay: the Pay tab and the home wallet
  /// card): one destination, one entry per screen. Enforced by the hub
  /// bridge.
  final bool pinnable;

  /// Short line under the name on the home grid ("Taxi et moto"); at most
  /// 14 characters so it never truncates on the 3-column grid.
  final String? tagline;

  /// Artwork of the home grid; the flat [icon] is used when absent.
  final String? illustrationAsset;
  final double illustrationScale;

  const WouandaServiceDefinition({
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
    this.availability = WouandaServiceAvailability.available,
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

  bool get isOpenable => availability != WouandaServiceAvailability.comingSoon;

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

class WouandaServiceRegistry {
  WouandaServiceRegistry._();

  static List<WouandaServiceDefinition> all = [
    WouandaServiceDefinition(
      id: WouandaServiceId.hub,
      key: 'hub',
      label: 'Accueil',
      productName: 'Wouanda',
      shortDescription: 'Tous vos services en un seul point.',
      route: '/hub',
      icon: LucideIcons.layoutGrid,
      color: WouandaColors.brand,
      lightColor: WouandaColors.surfaceLight,
      logoAsset: 'assets/images/wouanda.png',
      category: WouandaServiceCategory.platform,
      appearsInHub: false,
      shellBranchIndex: 0,
      notificationChannels: [
        WouandaNotificationChannel(
          key: 'offers',
          label: 'Offres et nouveautés',
          description: 'Promotions et nouveaux services Wouanda.',
          enabledByDefault: false,
        ),
        WouandaNotificationChannel(
          key: 'weeklyReport',
          label: 'Résumé hebdomadaire',
          description: 'Vos dépenses et activités de la semaine.',
          enabledByDefault: false,
        ),
      ],
    ),
    WouandaServiceDefinition(
      id: WouandaServiceId.mobility,
      key: 'go',
      tagline: 'Taxi et moto',
      illustrationAsset: 'assets/images/hub/icon_go.png',
      illustrationScale: 1.55,
      label: 'Mobilité',
      productName: 'Wouanda Go',
      shortDescription: 'Courses, trajets et chauffeurs.',
      route: '/mobility',
      icon: LucideIcons.car,
      color: AppTheme.wouandaGo,
      lightColor: AppTheme.wouandaGoLight,
      logoAsset: 'assets/images/wouanda-go-logo.png',
      category: WouandaServiceCategory.mobility,
      shellBranchIndex: 1,
      keywords: ['taxi', 'course', 'vtc', 'moto', 'trajet', 'chauffeur'],
      settingsRoute: '/mobility/settings',
      notificationChannels: [
        WouandaNotificationChannel(
          key: 'trips',
          label: 'Suivi des courses',
          description: 'Chauffeur trouvé, arrivée, fin de course.',
          critical: true,
        ),
        // The driver's two streams. Both are critical: a request that is not
        // heard is a lost ride, and a document or a rest limit that is not
        // read is a driver put off the road without warning.
        WouandaNotificationChannel(
          key: 'driverRequests',
          label: 'Demandes de course',
          description: 'Nouvelle demande, annulation, réservation.',
          critical: true,
        ),
        WouandaNotificationChannel(
          key: 'driverAccount',
          label: 'Compte chauffeur',
          description: 'Documents à renouveler, pause, versements.',
          critical: true,
        ),
        WouandaNotificationChannel(
          key: 'promos',
          label: 'Promotions Go',
          description: 'Réductions sur vos prochains trajets.',
        ),
      ],
      proSpaces: [
        WouandaProSpace(
          role: 'driver',
          title: 'Chauffeur Go',
          pitch: 'Conduisez et encaissez vos courses.',
          icon: LucideIcons.car,
          manageRoute: '/driver',
          becomeRoute: '/mobility/become-driver',
        ),
      ],
    ),
    WouandaServiceDefinition(
      id: WouandaServiceId.market,
      key: 'shop',
      tagline: 'Près de vous',
      illustrationAsset: 'assets/images/hub/icon_shop.png',
      illustrationScale: 1.28,
      label: 'Shop',
      productName: 'Wouanda Shop',
      shortDescription: 'Annonces locales et échanges entre particuliers.',
      route: '/commerce',
      icon: LucideIcons.shoppingBag,
      color: AppTheme.wouandaShop,
      lightColor: AppTheme.wouandaShopLight,
      logoAsset: 'assets/images/wouanda-shop-logo.png',
      category: WouandaServiceCategory.shopping,
      shellBranchIndex: 2,
      keywords: ['boutique', 'acheter', 'vendre', 'artisan', 'marché'],
      notificationChannels: [
        WouandaNotificationChannel(
          key: 'messages',
          label: 'Messages acheteurs et vendeurs',
          description: 'Questions, propositions et conversations.',
        ),
      ],
      proSpaces: [
        WouandaProSpace(
          role: 'seller',
          title: 'Vendeur Shop',
          pitch: 'Publiez vos annonces et rencontrez vos acheteurs.',
          icon: LucideIcons.store,
          manageRoute: '/commerce?selling=true',
          becomeRoute: '/commerce?selling=true',
        ),
      ],
    ),
    WouandaServiceDefinition(
      id: WouandaServiceId.events,
      key: 'events',
      tagline: 'Vos sorties',
      illustrationAsset: 'assets/images/hub/icon_events.png',
      illustrationScale: 1.18,
      label: 'Événements',
      productName: 'Wouanda Events',
      shortDescription: 'Sorties, tickets et organisateurs.',
      route: '/events',
      icon: LucideIcons.calendar,
      color: AppTheme.wouandaEvents,
      lightColor: AppTheme.wouandaEventsLight,
      logoAsset: 'assets/images/wouanda-events-logo.png',
      category: WouandaServiceCategory.outings,
      shellBranchIndex: 7,
      keywords: ['concert', 'billet', 'ticket', 'soirée', 'festival'],
      notificationChannels: [
        WouandaNotificationChannel(
          key: 'reminders',
          label: 'Rappels de billets',
          description: 'Veille et jour de vos événements.',
        ),
        WouandaNotificationChannel(
          key: 'sales',
          label: 'Ventes organisateur',
          description: 'Billets vendus et entrées validées.',
        ),
      ],
      proSpaces: [
        WouandaProSpace(
          role: 'organizer',
          title: 'Organisateur Events',
          pitch: 'Publiez vos événements et vendez des billets.',
          icon: LucideIcons.ticket,
          manageRoute: '/events/dashboard',
          becomeRoute: '/events/create-org',
        ),
      ],
    ),
    WouandaServiceDefinition(
      id: WouandaServiceId.love,
      key: 'love',
      tagline: 'Se rencontrer',
      illustrationAsset: 'assets/images/hub/icon_love.png',
      illustrationScale: 1.28,
      label: 'Rencontres',
      productName: 'Wouanda Love',
      shortDescription: 'Profils, matchs et conversations.',
      route: '/dating',
      icon: LucideIcons.heart,
      color: AppTheme.wouandaLove,
      lightColor: AppTheme.wouandaLoveLight,
      logoAsset: 'assets/images/wouanda-love-logo.png',
      category: WouandaServiceCategory.social,
      shellBranchIndex: 6,
      keywords: ['rencontre', 'match', 'amour', 'date'],
      pinnedByDefault: false,
      notificationChannels: [
        WouandaNotificationChannel(
          key: 'matches',
          label: 'Nouveaux matchs',
          description: 'Quand un profil vous plaît aussi.',
        ),
        WouandaNotificationChannel(
          key: 'messages',
          label: 'Messages',
          description: 'Conversations et propositions de sortie.',
        ),
      ],
    ),
    WouandaServiceDefinition(
      id: WouandaServiceId.stay,
      key: 'stay',
      tagline: 'Où dormir',
      illustrationAsset: 'assets/images/hub/icon_stay.png',
      illustrationScale: 1.34,
      label: 'Séjour',
      productName: 'Wouanda Stay',
      shortDescription: 'Logements, réservations et hôtes.',
      route: '/stay',
      icon: LucideIcons.building2,
      color: AppTheme.wouandaStay,
      lightColor: AppTheme.wouandaStayLight,
      logoAsset: 'assets/images/wouanda.png',
      category: WouandaServiceCategory.travel,
      shellBranchIndex: 8,
      keywords: ['hôtel', 'logement', 'appartement', 'location', 'nuit'],
      notificationChannels: [
        WouandaNotificationChannel(
          key: 'reservations',
          label: 'Réservations',
          description: 'Demandes, confirmations et arrivées.',
          critical: true,
        ),
        WouandaNotificationChannel(
          key: 'promos',
          label: 'Offres de séjour',
          description: 'Promotions sur vos destinations.',
          enabledByDefault: false,
        ),
      ],
      proSpaces: [
        WouandaProSpace(
          role: 'host',
          title: 'Hôte Stay',
          pitch: 'Louez votre logement et suivez vos revenus.',
          icon: LucideIcons.house,
          manageRoute: '/stay?tab=manage',
          becomeRoute: '/stay?tab=manage',
        ),
      ],
    ),
    WouandaServiceDefinition(
      id: WouandaServiceId.activity,
      key: 'activity',
      label: 'Activité',
      productName: 'Activité Wouanda',
      shortDescription: 'Messages, commandes et historique.',
      route: '/activity',
      icon: LucideIcons.history,
      color: AppTheme.secondary,
      lightColor: WouandaColors.surfaceLight,
      logoAsset: 'assets/images/wouanda.png',
      category: WouandaServiceCategory.platform,
      appearsInHub: false,
      shellBranchIndex: 4,
    ),
    WouandaServiceDefinition(
      id: WouandaServiceId.account,
      key: 'account',
      label: 'Compte',
      productName: 'Compte Wouanda',
      shortDescription: 'Profil, sécurité et préférences.',
      route: '/profile',
      icon: LucideIcons.user,
      color: WouandaColors.brand,
      lightColor: WouandaColors.surfaceLight,
      logoAsset: 'assets/images/wouanda.png',
      category: WouandaServiceCategory.platform,
      appearsInHub: false,
      shellBranchIndex: 5,
      notificationChannels: [
        WouandaNotificationChannel(
          key: 'security',
          label: 'Sécurité du compte',
          description: 'Nouvelle connexion, changement de mot de passe.',
          critical: true,
        ),
      ],
    ),
    WouandaServiceDefinition(
      id: WouandaServiceId.wallet,
      key: 'wallet',
      pinnable: false,
      pinnedByDefault: false,
      tagline: 'Payer, envoyer',
      illustrationAsset: 'assets/images/hub/icon_pay.png',
      label: 'Pay',
      productName: 'Wouanda Pay',
      shortDescription: 'Paiements, solde et cartes.',
      route: '/profile/wallet',
      icon: LucideIcons.wallet,
      color: AppTheme.success,
      lightColor: AppTheme.successLight,
      logoAsset: 'assets/images/wouanda.png',
      category: WouandaServiceCategory.finance,
      keywords: ['payer', 'portefeuille', 'solde', 'recharger', 'transfert'],
      notificationChannels: [
        WouandaNotificationChannel(
          key: 'transactions',
          label: 'Transactions',
          description: 'Paiements, recharges et transferts.',
          critical: true,
        ),
      ],
    ),
  ];

  /// Services a user opens (as opposed to platform spaces such as Activité).
  static List<WouandaServiceDefinition> get hubServices =>
      all.where((service) => service.appearsInHub).toList(growable: false);

  /// Everything listed in "Tous les services", Pay included (its tile opens
  /// the wallet). Only the home grid leaves Pay out: see [pinnable].
  static List<WouandaServiceDefinition> get catalog =>
      all.where((service) => service.appearsInHub).toList(growable: false);

  /// Services that expose at least one notification channel.
  static List<WouandaServiceDefinition> get withNotifications => all
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

  static WouandaServiceDefinition byId(WouandaServiceId id) {
    return all.firstWhere((service) => service.id == id);
  }

  static WouandaServiceDefinition byKey(String key) {
    return all.firstWhere(
      (service) => service.key == key,
      orElse: () => byId(WouandaServiceId.hub),
    );
  }

  static WouandaServiceDefinition? tryByKey(String key) {
    for (final service in all) {
      if (service.key == key) return service;
    }
    return null;
  }

  static WouandaServiceDefinition byRoute(String route) {
    return all.firstWhere(
      (service) =>
          route == service.route || route.startsWith('${service.route}/'),
      orElse: () => byId(WouandaServiceId.hub),
    );
  }

  static WouandaServiceDefinition? byShellBranchIndex(int branchIndex) {
    for (final service in all) {
      if (service.shellBranchIndex == branchIndex) return service;
    }
    return null;
  }
}
