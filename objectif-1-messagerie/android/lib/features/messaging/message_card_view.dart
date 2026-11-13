import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ngoma/core/platform/messaging/messaging_models.dart';
import 'package:ngoma/core/theme.dart';
import 'package:ngoma/core/widgets/wouanda_image.dart';
import 'package:ngoma/core/widgets/wouanda_loader.dart';
import 'package:wouanda_design/wouanda_design.dart';

/// The icon of a card kind: what the service object is, at a glance.
IconData messageCardKindIcon(String kind) => switch (kind) {
  'product' => LucideIcons.shoppingBag,
  'listing' => LucideIcons.house,
  'event' => LucideIcons.ticket,
  'trip' => LucideIcons.car,
  'booking' => LucideIcons.calendarCheck,
  'invitation' => LucideIcons.mailOpen,
  'offer' => LucideIcons.handCoins,
  'dateProposal' => LucideIcons.heartHandshake,
  'gift' => LucideIcons.gift,
  'payment' => LucideIcons.wallet,
  'location' => LucideIcons.mapPin,
  _ => LucideIcons.share2,
};

/// The words of the card codes (protocol §3.1: the bridge sends codes, the
/// screen words them).
String messageCardKindLabel(String kind) => switch (kind) {
  'product' => 'Article',
  'listing' => 'Logement',
  'event' => 'Événement',
  'trip' => 'Course',
  'booking' => 'Réservation',
  'invitation' => 'Invitation',
  'dateProposal' => 'Proposition de sortie',
  'offer' => 'Offre',
  'gift' => 'Cadeau',
  'payment' => 'Paiement',
  'location' => 'Position',
  _ => 'Partage',
};

/// [mine]: the card was sent by me (« En attente de réponse ») or to me
/// (« À vous de répondre »).
String? messageCardStatusLabel(String? status, {required bool mine}) =>
    switch (status) {
      'pending' => mine ? 'En attente de réponse' : 'À vous de répondre',
      'accepted' => 'Acceptée',
      'declined' => 'Refusée',
      'expired' => 'Expirée',
      'cancelled' => 'Annulée',
      'paid' => 'Payée',
      'confirmed' => 'Confirmée',
      'failed' => 'Échouée',
      _ => null,
    };

String messageCardActionLabel(String action) => switch (action) {
  'accept' => 'Accepter',
  'decline' => 'Refuser',
  'cancel' => 'Annuler',
  'pay' => 'Payer',
  'counter' => 'Contre-proposer',
  _ => 'Ouvrir',
};

/// A service object inside a message (contract messaging v3): its picture,
/// what it is, the figure that matters, its status and the answers the
/// reader may give. Every service is drawn by this one card; the bridge
/// decides the status and the actions.
class MessageCardView extends StatelessWidget {
  const MessageCardView({
    super.key,
    required this.card,
    required this.ink,
    required this.meta,
    this.mine = false,
    this.onOpen,
    this.onAction,
    this.busyAction,
  });

  final MessageCardDto card;

  /// Text colours of the bubble the card sits in.
  final Color ink;
  final Color meta;

  /// Sent by me: the status is worded from my side.
  final bool mine;

  /// Opens the object in its service (null: no known destination).
  final VoidCallback? onOpen;
  final ValueChanged<String>? onAction;

  /// The action being sent, drawn as busy.
  final String? busyAction;

  Color _statusColor(WouandaPalette palette) => switch (card.status) {
    'accepted' || 'paid' || 'confirmed' => palette.positive,
    'declined' || 'cancelled' || 'expired' || 'failed' => palette.negative,
    _ => palette.accent,
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final media = card.media;
    final statusLabel = messageCardStatusLabel(card.status, mine: mine);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (media != null)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: WouandaImage(media.source ?? '', fit: BoxFit.cover),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    messageCardKindIcon(card.kind),
                    size: 16,
                    color: palette.accent,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      messageCardKindLabel(card.kind),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.caption(
                        color: palette.accent,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                card.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.titleMd(
                  color: ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              if (card.subtitle != null && card.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  card.subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySm(color: meta),
                ),
              ],
              if (card.value != null && card.value!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  card.value!,
                  style: AppTheme.bodyMd(
                    color: ink,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ],
              if (statusLabel != null) ...[
                const SizedBox(height: 8),
                Row(
                  key: ValueKey('message-card-status-${card.status}'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _statusColor(palette),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        statusLabel,
                        style: AppTheme.caption(
                          color: _statusColor(palette),
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (card.actions.isNotEmpty && onAction != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Row(
              children: [
                for (final (i, action) in card.actions.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _CardActionButton(
                      action: action,
                      busy: busyAction == action,
                      enabled: busyAction == null,
                      onPressed: () => onAction!(action),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
    return SizedBox(
      width: 260,
      child: Semantics(
        button: onOpen != null,
        label:
            '${messageCardKindLabel(card.kind)}, ${card.title}${statusLabel == null ? '' : ', $statusLabel'}',
        child: InkWell(
          key: const ValueKey('message-card'),
          onTap: onOpen,
          child: body,
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.action,
    required this.busy,
    required this.enabled,
    required this.onPressed,
  });

  /// The action code (`accept`, `decline`…).
  final String action;
  final bool busy;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Saying yes leads; saying no or cancelling is quieter, never first.
    final style = switch (action) {
      'accept' || 'pay' => 'primary',
      'cancel' => 'destructive',
      _ => 'secondary',
    };
    final child = busy
        ? WouandaLoader(
            size: 16,
            strokeWidth: 2,
            color: style == 'primary' ? palette.onAccent : palette.accent,
          )
        : Text(
            messageCardActionLabel(action),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
    final key = ValueKey('message-card-action-$action');
    final buttonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(40)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 8),
      ),
    );
    return switch (style) {
      'primary' => FilledButton(
        key: key,
        style: buttonStyle,
        onPressed: enabled ? onPressed : null,
        child: child,
      ),
      'destructive' => OutlinedButton(
        key: key,
        style: buttonStyle.copyWith(
          foregroundColor: WidgetStatePropertyAll(palette.negative),
        ),
        onPressed: enabled ? onPressed : null,
        child: child,
      ),
      _ => OutlinedButton(
        key: key,
        style: buttonStyle,
        onPressed: enabled ? onPressed : null,
        child: child,
      ),
    };
  }
}
