import 'package:flutter/widgets.dart';
import 'package:ngoma/core/i18n/l10n.dart';

import 'wouanda_service_registry.dart';

/// The words of a service in the app language (French or English). Every
/// screen that names a service asks here; the French fields of the registry
/// are only the fallback for a service that has no translation yet.
extension WouandaServiceText on WouandaServiceDefinition {
  String labelOf(BuildContext context) {
    final l10n = context.l10n;
    return switch (key) {
          'hub' => l10n.serviceHubLabel,
          'go' => l10n.serviceGoLabel,
          'shop' => l10n.serviceShopLabel,
          'events' => l10n.serviceEventsLabel,
          'love' => l10n.serviceLoveLabel,
          'stay' => l10n.serviceStayLabel,
          'activity' => l10n.serviceActivityLabel,
          'account' => l10n.serviceAccountLabel,
          'wallet' => l10n.serviceWalletLabel,
          _ => null,
        } ??
        label;
  }

  /// One short line under the name on the home grid.
  String taglineOf(BuildContext context) {
    final l10n = context.l10n;
    return switch (key) {
          'go' => l10n.serviceGoTagline,
          'shop' => l10n.serviceShopTagline,
          'events' => l10n.serviceEventsTagline,
          'love' => l10n.serviceLoveTagline,
          'stay' => l10n.serviceStayTagline,
          'wallet' => l10n.serviceWalletTagline,
          _ => null,
        } ??
        descriptionOf(context);
  }

  String descriptionOf(BuildContext context) {
    final l10n = context.l10n;
    return switch (key) {
          'hub' => l10n.serviceHubDescription,
          'go' => l10n.serviceGoDescription,
          'shop' => l10n.serviceShopDescription,
          'events' => l10n.serviceEventsDescription,
          'love' => l10n.serviceLoveDescription,
          'stay' => l10n.serviceStayDescription,
          'activity' => l10n.serviceActivityDescription,
          'account' => l10n.serviceAccountDescription,
          'wallet' => l10n.serviceWalletDescription,
          _ => null,
        } ??
        shortDescription;
  }

  /// Search in both languages: a guest who types « ride » or « course »
  /// finds Go whatever the app language.
  bool matchesIn(BuildContext context, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return matches(query) ||
        [
          labelOf(context),
          descriptionOf(context),
        ].any((value) => value.toLowerCase().contains(q));
  }
}
