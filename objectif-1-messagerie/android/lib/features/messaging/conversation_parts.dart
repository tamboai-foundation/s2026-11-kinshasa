import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'message_card_view.dart';
import 'poll_post_parts.dart';
import 'messaging_service_style.dart';
import 'service_event_words.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ngoma/core/formatting/day_format.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:wouanda_design/wouanda_design.dart';

import 'package:ngoma/core/platform/messaging/messaging_models.dart';
import 'package:ngoma/core/theme.dart';
import 'package:ngoma/core/widgets/wouanda_conversation.dart';
import 'package:ngoma/core/widgets/wouanda_symbols.dart';
import 'package:ngoma/features/messaging/messaging_document_viewer.dart';
import 'package:ngoma/features/messaging/messaging_media_viewer.dart';

/// Building blocks of a conversation, after WhatsApp and iMessage:
/// day separators, grouped bubbles with delivery ticks, rich attachments,
/// the service context pinned on top, and a composer whose main actions
/// (camera, attach, voice / send) are one tap away.

// ─── Context banner ──────────────────────────────────────────────────

/// The order, ride, booking or ticket this conversation is about.
/// « N messages en attente » : what was written without a connection leaves
/// by itself. Shown under the header while something waits.
class OutboxBanner extends StatelessWidget {
  const OutboxBanner({super.key, required this.waiting});
  final int waiting;

  @override
  Widget build(BuildContext context) {
    if (waiting <= 0) return const SizedBox.shrink();
    final color = context.palette.textSecondary;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('messaging-outbox-banner'),
        width: double.infinity,
        color: context.palette.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(LucideIcons.wifiOff, size: 15, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                waiting == 1
                    ? '1 message en attente · il partira dès le retour du réseau'
                    : '$waiting messages en attente · ils partiront dès le retour du réseau',
                style: AppTheme.caption(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConversationContextBanner extends StatelessWidget {
  final UnifiedConversationDto conversation;
  final VoidCallback? onOpen;

  /// Opens a route the owner proposed (already checked by the screen).
  final ValueChanged<String>? onRoute;

  const ConversationContextBanner({
    super.key,
    required this.conversation,
    this.onOpen,
    this.onRoute,
  });

  static IconData iconFor(MessagingService service) => switch (service) {
    MessagingService.go => LucideIcons.carFront,
    MessagingService.shop => LucideIcons.shoppingBag,
    MessagingService.stay => LucideIcons.house,
    MessagingService.events => LucideIcons.ticket,
    MessagingService.love => LucideIcons.heart,
    _ => LucideIcons.messageCircle,
  };

  @override
  Widget build(BuildContext context) {
    final living = conversation.context;
    // The owner's header (contract v4): its title, where it stands, and the
    // buttons it proposes (only to destinations the app knows).
    final label = living?.title ?? conversation.contextLabel;
    // Without it, a concrete object only (order, ride, booking, ticket),
    // never the service name already shown under the contact.
    if (label == null ||
        (living == null && !RegExp(r'\d').hasMatch(label)) ||
        label.isEmpty) {
      return const SizedBox.shrink();
    }
    final status = messageContextStatusLabel(living?.status);
    final actions = [
      for (final action
          in living?.actions ?? const <ConversationContextActionDto>[])
        if (messageRouteAllowed(action.route)) action,
    ];
    final brightness = Theme.of(context).brightness;
    return Material(
      color: WouandaColors.surface(brightness),
      child: InkWell(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: WouandaColors.border(brightness)),
            ),
          ),
          child: Row(
            children: [
              Icon(
                messagingConversationIcon(conversation),
                size: 18,
                color: context.palette.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: WouandaColors.textPrimary(brightness),
                      ),
                    ),
                    if (status != null)
                      Text(
                        status,
                        key: ValueKey('context-status-${living!.status}'),
                        style: AppTheme.caption(
                          color: WouandaColors.textSecondary(brightness),
                        ),
                      ),
                  ],
                ),
              ),
              if (actions.isNotEmpty && onRoute != null)
                for (final action in actions)
                  TextButton(
                    key: ValueKey('context-action-${action.code}'),
                    onPressed: () => onRoute!(action.route!),
                    child: Text(messageContextActionLabel(action.code)),
                  )
              else if (onOpen != null)
                TextButton(onPressed: onOpen, child: const Text('Voir')),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Day separator ───────────────────────────────────────────────────

class DaySeparator extends StatelessWidget {
  final DateTime day;

  const DaySeparator({super.key, required this.day});

  static String label(DateTime day) => dayLabel(day, withYear: true);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: WouandaColors.surfaceMuted(brightness),
          borderRadius: BorderRadius.circular(WouandaSpacing.radiusPill),
        ),
        child: Text(
          label(day),
          style: AppTheme.caption(
            color: WouandaColors.textSecondary(brightness),
          ),
        ),
      ),
    );
  }
}

// ─── Markers ─────────────────────────────────────────────────────────

/// « Messages non lus » above the first message unread at opening.
class UnreadDivider extends StatelessWidget {
  const UnreadDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return Padding(
      key: const ValueKey('messaging-unread-divider'),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: accent.withValues(alpha: .35))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Messages non lus',
              style: AppTheme.caption(color: accent),
            ),
          ),
          Expanded(child: Divider(color: accent.withValues(alpha: .35))),
        ],
      ),
    );
  }
}

/// Call ended, member joined…: centred, no actions.
class SystemMessagePill extends StatelessWidget {
  const SystemMessagePill({super.key, required this.message});
  final UnifiedMessageDto message;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final event = message.event;
    final call =
        event == null && message.content.toLowerCase().startsWith('appel');
    final words = event == null ? message.content : messageEventText(event);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: WouandaColors.surfaceMuted(brightness),
          borderRadius: BorderRadius.circular(WouandaSpacing.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              event != null
                  ? messageEventIcon(event.code)
                  : call
                  ? LucideIcons.phone
                  : LucideIcons.info,
              size: 13,
              color: WouandaColors.textSecondary(brightness),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$words · '
                '${DateFormat('HH:mm').format(message.createdAt)}',
                style: AppTheme.caption(
                  color: WouandaColors.textSecondary(brightness),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three dots in a neutral bubble while the other side types.
class TypingIndicatorBubble extends StatefulWidget {
  const TypingIndicatorBubble({super.key, this.label});
  final String? label;

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: WouandaMotion.activity,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WouandaMotion.isReduced(context)
        ? _controller.stop()
        : _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.palette.textSecondary;
    return Semantics(
      liveRegion: true,
      label: widget.label ?? 'En train d’écrire',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WouandaMessageBubbleFrame(
            isMine: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(
                            alpha: _dotAlpha(_controller.value, i),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 4),
              child: Text(widget.label!, style: AppTheme.caption(color: color)),
            ),
        ],
      ),
    );
  }

  static double _dotAlpha(double t, int index) {
    final phase = (t - index * .18) % 1;
    return phase < .5 ? .35 + phase * 1.1 : .9 - (phase - .5) * 1.1;
  }
}

// ─── Swipe to reply ──────────────────────────────────────────────────

/// Drag a bubble to the right to quote it, as in WhatsApp.
class SwipeToReply extends StatefulWidget {
  const SwipeToReply({super.key, required this.child, required this.onReply});
  final Widget child;
  final VoidCallback? onReply;

  static const threshold = 64.0;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> {
  double _dx = 0;
  bool _armed = false;

  void _update(DragUpdateDetails details) {
    final next = (_dx + details.delta.dx).clamp(
      0.0,
      SwipeToReply.threshold * 1.4,
    );
    final armed = next >= SwipeToReply.threshold;
    if (armed && !_armed) HapticFeedback.selectionClick();
    setState(() {
      _dx = next;
      _armed = armed;
    });
  }

  void _end([DragEndDetails? _]) {
    if (_armed) widget.onReply?.call();
    setState(() {
      _dx = 0;
      _armed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onReply == null) return widget.child;
    final progress = (_dx / SwipeToReply.threshold).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _update,
      onHorizontalDragEnd: _end,
      onHorizontalDragCancel: _end,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Opacity(
            opacity: progress,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: context.palette.surfaceMuted,
                child: Icon(
                  LucideIcons.reply,
                  size: 16,
                  color: context.palette.accent,
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: _dx == 0
                ? WouandaMotion.duration(context, WouandaMotion.fast)
                : Duration.zero,
            transform: Matrix4.translationValues(_dx, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

// ─── Bubble ──────────────────────────────────────────────────────────

class MessageBubble extends StatelessWidget {
  final UnifiedMessageDto message;
  final ValueChanged<MessageAttachmentDto>? onAttachmentTap;
  final VoidCallback? onQuoteTap;
  final ValueChanged<String>? onReactionTap;
  final VoidCallback? onRetry;

  /// First / last bubble of a run from the same sender: corners and spacing
  /// follow, as in iMessage.
  final bool firstOfGroup;
  final bool lastOfGroup;

  /// Groups name the sender on the first bubble of a run.
  final bool showSender;

  /// Briefly outlined after jumping to it from a quote or a search.
  final bool highlighted;

  /// v3 service card: opening its object, answering it, the answer in flight.
  final VoidCallback? onCardOpen;
  final ValueChanged<String>? onCardAction;
  final String? busyCardAction;

  /// v5: voting in a poll (null: results only), opening a Buzz's space.
  final ValueChanged<int>? onPollVote;
  final VoidCallback? onPostOpen;

  const MessageBubble({
    super.key,
    required this.message,
    required this.firstOfGroup,
    required this.lastOfGroup,
    this.onAttachmentTap,
    this.onQuoteTap,
    this.onReactionTap,
    this.onRetry,
    this.showSender = false,
    this.highlighted = false,
    this.onCardOpen,
    this.onCardAction,
    this.busyCardAction,
    this.onPollVote,
    this.onPostOpen,
  });

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    final post = message.isPost && !message.isDeleted;
    final poll = message.isPoll && !message.isDeleted;
    final fg = WouandaMessageBubbleFrame.inkOf(context);
    final meta = WouandaMessageBubbleFrame.metaOf(context);
    final media = message.attachments.where(isVisualAttachment).toList();
    final others = message.attachments.where((a) => !media.contains(a));
    final failed = message.delivery == MessageDelivery.failed;
    final queued = message.delivery == MessageDelivery.queued;

    final bubble = WouandaMessageBubbleFrame(
      isMine: mine,
      firstOfGroup: firstOfGroup,
      lastOfGroup: lastOfGroup,
      child: AnimatedContainer(
        duration: WouandaMotion.duration(context, WouandaMotion.standard),
        foregroundDecoration: BoxDecoration(
          color: highlighted
              ? context.palette.accent.withValues(alpha: .18)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSender && !mine && firstOfGroup)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 7, 12, 0),
                child: Text(
                  message.senderLabel,
                  style: AppTheme.caption(
                    color: context.palette.accent,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            if (message.isForwarded && !message.isDeleted)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 7, 12, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.forward, size: 12, color: meta),
                    const SizedBox(width: 4),
                    Text('Transféré', style: AppTheme.caption(color: meta)),
                  ],
                ),
              ),
            if (message.replyTo != null && !message.isDeleted)
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                child: _ReplyQuote(
                  quote: message.replyTo!,
                  mine: mine,
                  onTap: onQuoteTap,
                ),
              ),
            if (post) const MessagePostChip(),
            if (poll)
              MessagePollView(
                question: message.content,
                poll: message.poll!,
                ink: fg,
                meta: meta,
                onVote: onPollVote,
              ),
            if (message.card case final card? when !message.isDeleted)
              MessageCardView(
                card: card,
                ink: fg,
                meta: meta,
                mine: mine,
                onOpen: onCardOpen,
                onAction: onCardAction,
                busyAction: busyCardAction,
              ),
            if (post && media.isNotEmpty)
              MessagePostMedia(
                media: media,
                onTap: onPostOpen == null ? null : (_) => onPostOpen!(),
              ),
            for (final attachment in post ? const <MessageAttachmentDto>[] : media)
              SizedBox(
                width: 260,
                height: 210,
                child: MessagingAttachmentPreview(
                  attachment: attachment,
                  cacheWidth: 640,
                  onTap: onAttachmentTap == null
                      ? null
                      : () => onAttachmentTap!(attachment),
                ),
              ),
            for (final attachment in others)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: attachment.type == 'voice' || attachment.type == 'audio'
                    ? MessagingAudioAttachmentPlayer(
                        attachment: attachment,
                        color: fg,
                      )
                    : _AttachmentRow(
                        attachment: attachment,
                        color: fg,
                        onTap: onAttachmentTap == null
                            ? null
                            : () => onAttachmentTap!(attachment),
                      ),
              ),
            if (post)
              MessagePostFooter(
                message: message,
                ink: fg,
                meta: meta,
                onOpen: onPostOpen,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 7, 10, 6),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 8,
                children: [
                  if (message.isDeleted)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.ban, size: 14, color: meta),
                        const SizedBox(width: 6),
                        Text(
                          mine
                              ? 'Vous avez supprimé ce message'
                              : 'Ce message a été supprimé',
                          style: AppTheme.bodySm(
                            color: meta,
                          ).copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                    )
                  else if (message.content.isNotEmpty && !poll)
                    LinkifiedText(
                      message.content,
                      style: AppTheme.bodyMd(color: fg),
                      linkColor: context.palette.accent,
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.editedAt != null && !message.isDeleted) ...[
                        Text('modifié', style: AppTheme.caption(color: meta)),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        DateFormat('HH:mm').format(message.createdAt),
                        style: AppTheme.caption(color: meta),
                      ),
                      if (mine && !message.isDeleted) ...[
                        const SizedBox(width: 3),
                        _DeliveryTick(delivery: message.delivery, color: meta),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        bubble,
        if (message.reactions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: _ReactionsRow(
              reactions: message.reactions,
              onTap: onReactionTap,
            ),
          ),
        if (queued)
          Padding(
            key: ValueKey('messaging-queued-${message.clientMessageId}'),
            padding: const EdgeInsets.only(top: 4, right: 4),
            child: Text(
              'En attente de connexion · partira seul',
              style: AppTheme.caption(color: meta),
            ),
          ),
        if (failed)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: InkWell(
              key: ValueKey('messaging-retry-${message.clientMessageId}'),
              onTap: onRetry,
              borderRadius: BorderRadius.circular(WouandaSpacing.radiusSmall),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.circleAlert,
                      size: 14,
                      color: WouandaColors.negative,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Non envoyé · Réessayer',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.caption(color: WouandaColors.negative),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The quoted message inside a reply bubble.
class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({required this.quote, required this.mine, this.onTap});
  final MessageQuoteDto quote;
  final bool mine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bar = context.palette.accent;
    final text = WouandaColors.textSecondary(brightness);
    return Material(
      color: mine
          ? context.palette.surface.withValues(alpha: .6)
          : WouandaColors.surfaceMuted(brightness),
      borderRadius: BorderRadius.circular(WouandaSpacing.radiusSmall),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 3, color: bar),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        quote.senderLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.caption(
                          color: bar,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        quote.preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodySm(color: text),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reaction pills under a bubble; mine is tinted, a tap toggles it.
class _ReactionsRow extends StatelessWidget {
  const _ReactionsRow({required this.reactions, this.onTap});
  final List<MessageReactionDto> reactions;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final reaction in reactions)
          Semantics(
            button: onTap != null,
            label:
                '${_reactionLabel(reaction.key)}, ${reaction.count}'
                '${reaction.isMine ? ', votre réaction' : ''}',
            child: Material(
              color: reaction.isMine
                  ? context.palette.accent.withValues(alpha: .12)
                  : WouandaColors.surface(brightness),
              shape: StadiumBorder(
                side: BorderSide(
                  color: reaction.isMine
                      ? context.palette.accent.withValues(alpha: .5)
                      : WouandaColors.border(brightness),
                ),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onTap == null ? null : () => onTap!(reaction.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ReactionGlyph(
                        reaction.key,
                        size: 15,
                        color: reaction.isMine
                            ? context.palette.accent
                            : WouandaColors.textSecondary(brightness),
                      ),
                      if (reaction.count > 1) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${reaction.count}',
                          style: AppTheme.caption(
                            color: WouandaColors.textSecondary(brightness),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A reaction: the emoji typed on the phone's keyboard, or, for reactions
/// recorded before emoji were free, the icon of the old key.
class ReactionGlyph extends StatelessWidget {
  const ReactionGlyph(this.reaction, {super.key, this.size = 16, this.color});
  final String reaction;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => WouandaSymbols.has(reaction)
      ? WouandaSymbol(reaction, size: size, color: color)
      : Text(reaction, style: AppTheme.font(fontSize: size, height: 1.1));
}

String _reactionLabel(String key) => switch (key) {
  'like' => 'J’aime',
  'heart' => 'Cœur',
  'laugh' => 'Rire',
  'wow' => 'Surprise',
  'sad' => 'Triste',
  'fire' => 'Génial',
  _ => key,
};

/// Accessible name of a reaction key, for menus and pills.
String messagingReactionLabel(String key) => _reactionLabel(key);

/// Text whose web addresses open in the browser.
class LinkifiedText extends StatefulWidget {
  const LinkifiedText(
    this.text, {
    super.key,
    required this.style,
    required this.linkColor,
  });
  final String text;
  final TextStyle style;
  final Color linkColor;

  static final pattern = RegExp(
    r'(https?:\/\/[^\s]+|www\.[^\s]+\.[^\s]+)',
    caseSensitive: false,
  );

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  final _recognizers = <TapGestureRecognizer>[];

  void _clear() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = LinkifiedText.pattern.allMatches(widget.text).toList();
    if (matches.isEmpty) return Text(widget.text, style: widget.style);
    _clear();
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: widget.text.substring(cursor, match.start)));
      }
      final raw = match.group(0)!.replaceAll(RegExp(r'[.,;:!?)]+$'), '');
      final uri = Uri.tryParse(raw.startsWith('http') ? raw : 'https://$raw');
      final recognizer = TapGestureRecognizer()
        ..onTap = uri == null
            ? null
            : () => launchUrl(uri, mode: LaunchMode.externalApplication);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: raw,
          recognizer: recognizer,
          style: widget.style.copyWith(
            color: widget.linkColor,
            decoration: TextDecoration.underline,
            decorationColor: widget.linkColor,
          ),
        ),
      );
      cursor = match.start + raw.length;
    }
    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }
    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}

class _DeliveryTick extends StatelessWidget {
  final MessageDelivery delivery;
  final Color color;

  const _DeliveryTick({required this.delivery, required this.color});

  @override
  Widget build(BuildContext context) => Semantics(
    label: switch (delivery) {
      MessageDelivery.sending => 'Envoi en cours',
      MessageDelivery.queued => 'En attente de connexion',
      MessageDelivery.sent => 'Envoyé',
      MessageDelivery.delivered => 'Distribué',
      MessageDelivery.read => 'Lu',
      MessageDelivery.failed => 'Non envoyé',
    },
    child: switch (delivery) {
      MessageDelivery.sending => Icon(
        LucideIcons.clock3,
        size: 13,
        color: color,
      ),
      MessageDelivery.queued => Icon(
        LucideIcons.clock3,
        size: 13,
        color: color,
      ),
      MessageDelivery.sent => Icon(LucideIcons.check, size: 14, color: color),
      MessageDelivery.delivered => Icon(
        LucideIcons.checkCheck,
        size: 14,
        color: color,
      ),
      MessageDelivery.read => Icon(
        LucideIcons.checkCheck,
        size: 14,
        color: context.palette.accent,
      ),
      MessageDelivery.failed => const Icon(
        LucideIcons.circleAlert,
        size: 14,
        color: WouandaColors.negative,
      ),
    },
  );
}

/// A document or a position inside a bubble: one tap opens it, no menu.
class _AttachmentRow extends StatelessWidget {
  final MessageAttachmentDto attachment;
  final Color color;
  final VoidCallback? onTap;

  const _AttachmentRow({
    required this.attachment,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final location = attachment.type == 'location';
    final kind = documentKind(attachment);
    final subtitle = location
        ? 'Ouvrir dans les cartes'
        : [
            kind.kind,
            attachmentSizeLabel(attachment.sizeBytes),
          ].where((part) => part.isNotEmpty).join(' · ');
    return Semantics(
      button: onTap != null,
      label: location
          ? 'Voir la position'
          : 'Ouvrir le document ${attachment.label}',
      child: Material(
        color: context.palette.surface.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(WouandaSpacing.radiusSmall),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.palette.accent.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(
                      WouandaSpacing.radiusSmall,
                    ),
                  ),
                  child: Icon(
                    location ? LucideIcons.mapPin : kind.icon,
                    size: 20,
                    color: context.palette.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        attachment.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodySm(color: color),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.caption(
                            color: WouandaColors.textSecondary(
                              Theme.of(context).brightness,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (onTap != null && !location) ...[
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: WouandaColors.textSecondary(
                      Theme.of(context).brightness,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
