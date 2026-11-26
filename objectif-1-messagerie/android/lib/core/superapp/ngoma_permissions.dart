import 'package:ngoma/core/providers/user_provider.dart';
import 'package:ngoma/core/superapp/ngoma_service_registry.dart';

enum NgomaAccessBlocker {
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

  static NgomaAccessBlocker fromCode(String code) =>
      NgomaAccessBlocker.values.firstWhere(
        (blocker) => blocker.name == code,
        orElse: () => NgomaAccessBlocker.unavailable,
      );
}

/// Actions whose access the account authority decides. Each name is the
/// contract code of `Access.action` (docs/contracts/account.md v1.2).
enum NgomaAction {
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
class NgomaAccessPolicy {
  final NgomaAction action;
  final NgomaServiceId service;
  final String actionLabel;

  const NgomaAccessPolicy({
    required this.action,
    required this.service,
    required this.actionLabel,
  });
}

class NgomaAccessDecision {
  final bool allowed;
  final String title;
  final String message;
  final NgomaAccessBlocker blocker;
  final String? resolutionRoute;

  const NgomaAccessDecision({
    required this.allowed,
    required this.title,
    required this.message,
    this.blocker = NgomaAccessBlocker.none,
    this.resolutionRoute,
  });
}

/// Words the access decisions of the account authority (contract account
/// v1.2 `Access`). Flutter never recomputes who may do what.
class NgomaPermissions {
  const NgomaPermissions._();

  static const Map<NgomaAction, NgomaAccessPolicy> policies = {
    NgomaAction.explore: NgomaAccessPolicy(
      action: NgomaAction.explore,
      service: NgomaServiceId.hub,
      actionLabel: 'explorer NGoma',
    ),
    NgomaAction.message: NgomaAccessPolicy(
      action: NgomaAction.message,
      service: NgomaServiceId.activity,
      actionLabel: 'envoyer un message',
    ),
    NgomaAction.save: NgomaAccessPolicy(
      action: NgomaAction.save,
      service: NgomaServiceId.hub,
      actionLabel: 'sauvegarder cet element',
    ),
    NgomaAction.pay: NgomaAccessPolicy(
      action: NgomaAction.pay,
      service: NgomaServiceId.wallet,
      actionLabel: 'payer avec NGoma',
    ),
    NgomaAction.bookRide: NgomaAccessPolicy(
      action: NgomaAction.bookRide,
      service: NgomaServiceId.mobility,
      actionLabel: 'commander une course',
    ),
    NgomaAction.bookStay: NgomaAccessPolicy(
      action: NgomaAction.bookStay,
      service: NgomaServiceId.stay,
      actionLabel: 'réserver un séjour',
    ),
    NgomaAction.buyTicket: NgomaAccessPolicy(
      action: NgomaAction.buyTicket,
      service: NgomaServiceId.events,
      actionLabel: 'acheter un ticket',
    ),
    NgomaAction.publishListing: NgomaAccessPolicy(
      action: NgomaAction.publishListing,
      service: NgomaServiceId.market,
      actionLabel: 'publier une annonce',
    ),
    NgomaAction.publishEvent: NgomaAccessPolicy(
      action: NgomaAction.publishEvent,
      service: NgomaServiceId.events,
      actionLabel: 'publier un événement',
    ),
    NgomaAction.manageWallet: NgomaAccessPolicy(
      action: NgomaAction.manageWallet,
      service: NgomaServiceId.wallet,
      actionLabel: 'gerer votre wallet',
    ),
    NgomaAction.manageAccount: NgomaAccessPolicy(
      action: NgomaAction.manageAccount,
      service: NgomaServiceId.account,
      actionLabel: 'gerer votre compte',
    ),
    NgomaAction.becomeSeller: NgomaAccessPolicy(
      action: NgomaAction.becomeSeller,
      service: NgomaServiceId.market,
      actionLabel: 'devenir vendeur',
    ),
    NgomaAction.becomeDriver: NgomaAccessPolicy(
      action: NgomaAction.becomeDriver,
      service: NgomaServiceId.mobility,
      actionLabel: 'devenir chauffeur',
    ),
    NgomaAction.becomeHost: NgomaAccessPolicy(
      action: NgomaAction.becomeHost,
      service: NgomaServiceId.stay,
      actionLabel: 'devenir host',
    ),
    NgomaAction.becomeOrganizer: NgomaAccessPolicy(
      action: NgomaAction.becomeOrganizer,
      service: NgomaServiceId.events,
      actionLabel: 'créer une organisation',
    ),
    NgomaAction.manageEvents: NgomaAccessPolicy(
      action: NgomaAction.manageEvents,
      service: NgomaServiceId.events,
      actionLabel: 'gérer vos événements',
    ),
    NgomaAction.manageStayHost: NgomaAccessPolicy(
      action: NgomaAction.manageStayHost,
      service: NgomaServiceId.stay,
      actionLabel: 'gerer vos logements',
    ),
    NgomaAction.publishStayListing: NgomaAccessPolicy(
      action: NgomaAction.publishStayListing,
      service: NgomaServiceId.stay,
      actionLabel: 'publier un logement',
    ),
    NgomaAction.manageService: NgomaAccessPolicy(
      action: NgomaAction.manageService,
      service: NgomaServiceId.hub,
      actionLabel: 'gerer ce service',
    ),
  };

  static NgomaAccessPolicy policyFor(NgomaAction action) {
    return policies[action] ?? policies[NgomaAction.explore]!;
  }

  static String resolutionLabel(NgomaAccessBlocker blocker) {
    return switch (blocker) {
      NgomaAccessBlocker.inactiveService => 'Activer le service',
      NgomaAccessBlocker.phoneVerification => 'Ajouter mon téléphone',
      NgomaAccessBlocker.identityVerification => 'Vérifier mon identité',
      NgomaAccessBlocker.serviceApproval ||
      NgomaAccessBlocker.role => 'Configurer mon activité',
      NgomaAccessBlocker.authentication => 'Se connecter',
      NgomaAccessBlocker.unavailable => 'Réessayer',
      NgomaAccessBlocker.none => 'Continuer',
    };
  }

  /// The decision of the account authority for [action], put into words.
  static NgomaAccessDecision can(UserProfile user, NgomaAction action) {
    final policy = policyFor(action);
    final service = NgomaServiceRegistry.byId(policy.service);
    final access = user.access[action.name];

    if (access != null && access.allowed) {
      return NgomaAccessDecision(
        allowed: true,
        title: 'Acces autorise',
        message: 'Vous pouvez ${policy.actionLabel}.',
      );
    }

    final blocker = access == null
        ? NgomaAccessBlocker.unavailable
        : NgomaAccessBlocker.fromCode(access.blocker);
    final route = access?.resolutionRoute;
    return switch (blocker) {
      NgomaAccessBlocker.authentication => NgomaAccessDecision(
        allowed: false,
        title: 'Compte NGoma requis',
        message:
            'Vous pouvez explorer ${service.productName}. Pour ${policy.actionLabel}, connectez-vous avec votre compte unique.',
        blocker: blocker,
        resolutionRoute: route,
      ),
      NgomaAccessBlocker.inactiveService => NgomaAccessDecision(
        allowed: false,
        title: 'Service non activé',
        message:
            'Activez ${service.productName} dans votre compte NGoma avant de pouvoir ${policy.actionLabel}.',
        blocker: blocker,
        resolutionRoute: route,
      ),
      NgomaAccessBlocker.phoneVerification ||
      NgomaAccessBlocker.identityVerification ||
      NgomaAccessBlocker.serviceApproval => NgomaAccessDecision(
        allowed: false,
        title: 'Vérification requise',
        message:
            'Votre compte doit être vérifié avant de pouvoir ${policy.actionLabel}.',
        blocker: blocker,
        resolutionRoute: route,
      ),
      NgomaAccessBlocker.role => NgomaAccessDecision(
        allowed: false,
        title: policy.service == NgomaServiceId.events
            ? 'Faites vivre votre événement'
            : 'Préparez votre activité',
        message: policy.service == NgomaServiceId.events
            ? 'Créez votre page organisateur, puis préparez votre affiche, vos billets et votre programme.'
            : 'Configurez votre activité pour ${policy.actionLabel}.',
        blocker: blocker,
        resolutionRoute: route,
      ),
      // `none` with `allowed: false` is an inconsistent answer: refused too.
      NgomaAccessBlocker.none ||
      NgomaAccessBlocker.unavailable => NgomaAccessDecision(
        allowed: false,
        title: 'Droits indisponibles',
        message:
            'Vos droits pour ${policy.actionLabel} n’ont pas pu être vérifiés. Réessayez.',
        blocker: NgomaAccessBlocker.unavailable,
      ),
    };
  }
}
