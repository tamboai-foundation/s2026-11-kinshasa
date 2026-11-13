import 'package:ngoma/core/providers/user_provider.dart';
import 'package:ngoma/core/superapp/wouanda_service_registry.dart';

enum WouandaAccessBlocker {
  none,
  authentication,
  inactiveService,
  phoneVerification,
  identityVerification,
  serviceApproval,
  role,

  /// No decision received from the account authority (not restored yet,
  /// unknown action or code): refused, never guessed.
  unavailable;

  static WouandaAccessBlocker fromCode(String code) =>
      WouandaAccessBlocker.values.firstWhere(
        (blocker) => blocker.name == code,
        orElse: () => WouandaAccessBlocker.unavailable,
      );
}

/// Actions whose access the account authority decides. Each name is the
/// contract code of `Access.action` (docs/contracts/account.md v1.2).
enum WouandaAction {
  explore,
  message,
  save,
  pay,
  bookRide,
  bookStay,
  buyTicket,
  publishListing,
  publishEvent,
  manageWallet,
  manageAccount,
  becomeSeller,
  becomeDriver,
  becomeHost,
  becomeOrganizer,
  manageEvents,
  manageStayHost,
  publishStayListing,
  manageService,
}

/// How an action is presented: the service it belongs to and its wording.
/// Who may do it is decided by the account authority, not here.
class WouandaAccessPolicy {
  final WouandaAction action;
  final WouandaServiceId service;
  final String actionLabel;

  const WouandaAccessPolicy({
    required this.action,
    required this.service,
    required this.actionLabel,
  });
}

class WouandaAccessDecision {
  final bool allowed;
  final String title;
  final String message;
  final WouandaAccessBlocker blocker;
  final String? resolutionRoute;

  const WouandaAccessDecision({
    required this.allowed,
    required this.title,
    required this.message,
    this.blocker = WouandaAccessBlocker.none,
    this.resolutionRoute,
  });
}

/// Words the access decisions of the account authority (contract account
/// v1.2 `Access`). Flutter never recomputes who may do what.
class WouandaPermissions {
  const WouandaPermissions._();

  static const Map<WouandaAction, WouandaAccessPolicy> policies = {
    WouandaAction.explore: WouandaAccessPolicy(
      action: WouandaAction.explore,
      service: WouandaServiceId.hub,
      actionLabel: 'explorer Wouanda',
    ),
    WouandaAction.message: WouandaAccessPolicy(
      action: WouandaAction.message,
      service: WouandaServiceId.activity,
      actionLabel: 'envoyer un message',
    ),
    WouandaAction.save: WouandaAccessPolicy(
      action: WouandaAction.save,
      service: WouandaServiceId.hub,
      actionLabel: 'sauvegarder cet element',
    ),
    WouandaAction.pay: WouandaAccessPolicy(
      action: WouandaAction.pay,
      service: WouandaServiceId.wallet,
      actionLabel: 'payer avec Wouanda',
    ),
    WouandaAction.bookRide: WouandaAccessPolicy(
      action: WouandaAction.bookRide,
      service: WouandaServiceId.mobility,
      actionLabel: 'commander une course',
    ),
    WouandaAction.bookStay: WouandaAccessPolicy(
      action: WouandaAction.bookStay,
      service: WouandaServiceId.stay,
      actionLabel: 'réserver un séjour',
    ),
    WouandaAction.buyTicket: WouandaAccessPolicy(
      action: WouandaAction.buyTicket,
      service: WouandaServiceId.events,
      actionLabel: 'acheter un ticket',
    ),
    WouandaAction.publishListing: WouandaAccessPolicy(
      action: WouandaAction.publishListing,
      service: WouandaServiceId.market,
      actionLabel: 'publier une annonce',
    ),
    WouandaAction.publishEvent: WouandaAccessPolicy(
      action: WouandaAction.publishEvent,
      service: WouandaServiceId.events,
      actionLabel: 'publier un événement',
    ),
    WouandaAction.manageWallet: WouandaAccessPolicy(
      action: WouandaAction.manageWallet,
      service: WouandaServiceId.wallet,
      actionLabel: 'gerer votre wallet',
    ),
    WouandaAction.manageAccount: WouandaAccessPolicy(
      action: WouandaAction.manageAccount,
      service: WouandaServiceId.account,
      actionLabel: 'gerer votre compte',
    ),
    WouandaAction.becomeSeller: WouandaAccessPolicy(
      action: WouandaAction.becomeSeller,
      service: WouandaServiceId.market,
      actionLabel: 'devenir vendeur',
    ),
    WouandaAction.becomeDriver: WouandaAccessPolicy(
      action: WouandaAction.becomeDriver,
      service: WouandaServiceId.mobility,
      actionLabel: 'devenir chauffeur',
    ),
    WouandaAction.becomeHost: WouandaAccessPolicy(
      action: WouandaAction.becomeHost,
      service: WouandaServiceId.stay,
      actionLabel: 'devenir host',
    ),
    WouandaAction.becomeOrganizer: WouandaAccessPolicy(
      action: WouandaAction.becomeOrganizer,
      service: WouandaServiceId.events,
      actionLabel: 'créer une organisation',
    ),
    WouandaAction.manageEvents: WouandaAccessPolicy(
      action: WouandaAction.manageEvents,
      service: WouandaServiceId.events,
      actionLabel: 'gérer vos événements',
    ),
    WouandaAction.manageStayHost: WouandaAccessPolicy(
      action: WouandaAction.manageStayHost,
      service: WouandaServiceId.stay,
      actionLabel: 'gerer vos logements',
    ),
    WouandaAction.publishStayListing: WouandaAccessPolicy(
      action: WouandaAction.publishStayListing,
      service: WouandaServiceId.stay,
      actionLabel: 'publier un logement',
    ),
    WouandaAction.manageService: WouandaAccessPolicy(
      action: WouandaAction.manageService,
      service: WouandaServiceId.hub,
      actionLabel: 'gerer ce service',
    ),
  };

  static WouandaAccessPolicy policyFor(WouandaAction action) {
    return policies[action] ?? policies[WouandaAction.explore]!;
  }

  static String resolutionLabel(WouandaAccessBlocker blocker) {
    return switch (blocker) {
      WouandaAccessBlocker.inactiveService => 'Activer le service',
      WouandaAccessBlocker.phoneVerification => 'Ajouter mon téléphone',
      WouandaAccessBlocker.identityVerification => 'Vérifier mon identité',
      WouandaAccessBlocker.serviceApproval ||
      WouandaAccessBlocker.role => 'Configurer mon activité',
      WouandaAccessBlocker.authentication => 'Se connecter',
      WouandaAccessBlocker.unavailable => 'Réessayer',
      WouandaAccessBlocker.none => 'Continuer',
    };
  }

  /// The decision of the account authority for [action], put into words.
  static WouandaAccessDecision can(UserProfile user, WouandaAction action) {
    final policy = policyFor(action);
    final service = WouandaServiceRegistry.byId(policy.service);
    final access = user.access[action.name];

    if (access != null && access.allowed) {
      return WouandaAccessDecision(
        allowed: true,
        title: 'Acces autorise',
        message: 'Vous pouvez ${policy.actionLabel}.',
      );
    }

    final blocker = access == null
        ? WouandaAccessBlocker.unavailable
        : WouandaAccessBlocker.fromCode(access.blocker);
    final route = access?.resolutionRoute;
    return switch (blocker) {
      WouandaAccessBlocker.authentication => WouandaAccessDecision(
        allowed: false,
        title: 'Compte Wouanda requis',
        message:
            'Vous pouvez explorer ${service.productName}. Pour ${policy.actionLabel}, connectez-vous avec votre compte unique.',
        blocker: blocker,
        resolutionRoute: route,
      ),
      WouandaAccessBlocker.inactiveService => WouandaAccessDecision(
        allowed: false,
        title: 'Service non activé',
        message:
            'Activez ${service.productName} dans votre compte Wouanda avant de pouvoir ${policy.actionLabel}.',
        blocker: blocker,
        resolutionRoute: route,
      ),
      WouandaAccessBlocker.phoneVerification ||
      WouandaAccessBlocker.identityVerification ||
      WouandaAccessBlocker.serviceApproval => WouandaAccessDecision(
        allowed: false,
        title: 'Vérification requise',
        message:
            'Votre compte doit être vérifié avant de pouvoir ${policy.actionLabel}.',
        blocker: blocker,
        resolutionRoute: route,
      ),
      WouandaAccessBlocker.role => WouandaAccessDecision(
        allowed: false,
        title: policy.service == WouandaServiceId.events
            ? 'Faites vivre votre événement'
            : 'Préparez votre activité',
        message: policy.service == WouandaServiceId.events
            ? 'Créez votre page organisateur, puis préparez votre affiche, vos billets et votre programme.'
            : 'Configurez votre activité pour ${policy.actionLabel}.',
        blocker: blocker,
        resolutionRoute: route,
      ),
      // `none` with `allowed: false` is an inconsistent answer: refused too.
      WouandaAccessBlocker.none ||
      WouandaAccessBlocker.unavailable => WouandaAccessDecision(
        allowed: false,
        title: 'Droits indisponibles',
        message:
            'Vos droits pour ${policy.actionLabel} n’ont pas pu être vérifiés. Réessayez.',
        blocker: WouandaAccessBlocker.unavailable,
      ),
    };
  }
}
