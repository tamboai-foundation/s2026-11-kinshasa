import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ngoma/core/platform/messaging/messaging_models.dart';
import 'package:ngoma/core/superapp/wouanda_service_registry.dart';

/// The words of what services tell their conversations (contract messaging
/// v4). A bridge sends codes and parameters (protocol §3.1); this is the one
/// place that words them. A code Flutter does not know yet is never shown
/// raw: it reads as a plain update, so a service can start telling something
/// new before the app learns the words.

String? _param(MessageServiceEventDto event, String key) {
  final value = event.params[key];
  if (value == null) return null;
  final text = '$value'.trim();
  return text.isEmpty ? null : text;
}

/// A date the owner gave as ISO 8601 (`at`), said the way people say it.
String? _when(MessageServiceEventDto event) {
  final at = DateTime.tryParse(_param(event, 'at') ?? '');
  if (at == null) return null;
  return DateFormat('EEE d MMM', 'fr_FR').format(at.toLocal());
}

String messageEventText(MessageServiceEventDto event) {
  final who = _param(event, 'name');
  final place = _param(event, 'place');
  final when = _when(event);
  final title = _param(event, 'title');
  return switch (event.code) {
    'trip.assigned' =>
      who == null ? 'Votre chauffeur est en route' : '$who est en route',
    'trip.arrived' =>
      who == null ? 'Votre chauffeur est arrivé' : '$who est arrivé',
    'trip.started' => 'La course a commencé',
    'trip.completed' => 'Course terminée',
    'trip.cancelled' => 'Course annulée',
    'booking.requested' => 'Demande de réservation envoyée',
    'booking.accepted' =>
      when == null ? 'Réservation acceptée' : 'Réservation acceptée · $when',
    'booking.confirmed' => 'Réservation confirmée',
    'booking.checkedIn' => 'Arrivée enregistrée',
    'booking.completed' => 'Séjour terminé',
    'booking.declined' => 'Réservation refusée',
    'booking.cancelled' => 'Réservation annulée',
    'ticket.purchased' =>
      title == null ? 'Billet confirmé' : 'Billet confirmé · $title',
    'ticket.cancelled' => 'Billet annulé',
    'event.cancelled' =>
      title == null ? 'Événement annulé' : '$title est annulé',
    'event.rescheduled' =>
      when == null ? 'Événement reprogrammé' : 'Événement reprogrammé · $when',
    'event.doorsOpen' =>
      place == null ? 'Les portes ouvrent' : 'Les portes ouvrent · $place',
    _ => 'Mise à jour du service',
  };
}

IconData messageEventIcon(String code) {
  final family = code.split('.').first;
  return switch (family) {
    'trip' => LucideIcons.carFront,
    'booking' => LucideIcons.calendarCheck,
    'ticket' || 'event' => LucideIcons.ticket,
    'order' => LucideIcons.package,
    'payment' => LucideIcons.wallet,
    _ => LucideIcons.info,
  };
}

/// How a conversation's state code reads in its header; null hides it.
String? messageContextStatusLabel(String? status) => switch (status) {
  'scheduled' => 'Programmée',
  'pending' => 'En attente',
  'accepted' => 'Acceptée',
  'declined' => 'Refusée',
  'confirmed' => 'Confirmée',
  'inProgress' => 'En cours',
  'arrived' => 'Arrivé',
  'completed' => 'Terminée',
  'cancelled' => 'Annulée',
  'expired' => 'Expirée',
  _ => null,
};

/// The button an owner proposes in the header, by code.
String messageContextActionLabel(String code) => switch (code) {
  'track' => 'Suivre',
  'pay' => 'Payer',
  'contact' => 'Contacter',
  _ => 'Voir',
};

/// Why a conversation is read only, by the owner's code.
String? messageClosedReasonText(String? reason) => switch (reason) {
  'ended' => 'Cette conversation est terminée.',
  'cancelled' => 'Cette conversation est fermée : elle a été annulée.',
  'expired' => 'Cette conversation est fermée.',
  _ => null,
};

/// An owner may point to any page of a service the app knows: the service
/// registry is the list, so a new service needs no change here. Anything
/// else is ignored, never followed.
bool messageRouteAllowed(String? route) {
  if (route == null || !route.startsWith('/') || route.contains('..')) {
    return false;
  }
  for (final service in WouandaServiceRegistry.all) {
    final base = service.route;
    if (base.length > 1 && (route == base || route.startsWith('$base/'))) {
      return true;
    }
  }
  return false;
}
