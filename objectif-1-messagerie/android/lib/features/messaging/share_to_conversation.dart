import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ngoma/core/platform/messaging/messaging_bridge.dart';
import 'package:ngoma/core/platform/messaging/messaging_bridge_provider.dart';
import 'package:ngoma/core/platform/messaging/messaging_models.dart';
import 'package:ngoma/core/theme.dart';
import 'package:ngoma/core/widgets/wouanda_draggable_sheet.dart';
import 'package:ngoma/core/widgets/wouanda_list.dart';
import 'package:ngoma/core/widgets/wouanda_loader.dart';
import 'package:ngoma/core/widgets/wouanda_search_input.dart';
import 'package:wouanda_design/wouanda_design.dart';

import 'message_card_view.dart';
import 'messaging_service_style.dart';

/// « Envoyer dans une conversation »: the one way every service shares an
/// object (an event, an article, a stay, a ride) with someone, as a card in
/// the common messaging. The conversations offered are the bridge's: only
/// those that accept cards and where the user may write.
///
/// [onOtherApps] adds the phone's share sheet as the last choice. Returns
/// true once the card is sent.
Future<bool> shareToConversation(
  BuildContext context, {
  required MessageCardDraft draft,
  VoidCallback? onOtherApps,
}) async {
  final sent = await showWouandaSheet<bool>(
    context,
    builder: (_) => _ShareSheet(draft: draft, onOtherApps: onOtherApps),
  );
  return sent == true;
}

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet({required this.draft, this.onOtherApps});
  final MessageCardDraft draft;
  final VoidCallback? onOtherApps;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  List<UnifiedConversationDto>? _conversations;
  String _query = '';
  int? _sending;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bridge = ref.read(messagingBridgeProvider);
    try {
      final capabilities = await bridge.getCapabilities();
      final all = <UnifiedConversationDto>[];
      for (final kind in ConversationKind.values) {
        all.addAll(
          await bridge.loadConversations(ConversationQuery(kind: kind)),
        );
      }
      if (!mounted) return;
      setState(() {
        _conversations =
            [
              for (final c in all)
                if (bridge is MessagingCardBridge &&
                    c.canSend &&
                    !c.isBlocked &&
                    capabilities.has(MessagingFeature.cards) &&
                    c.features.contains(MessagingFeature.cards))
                  c,
            ]..sort(
              (a, b) => (b.lastMessageAt ?? DateTime(0)).compareTo(
                a.lastMessageAt ?? DateTime(0),
              ),
            );
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _send(UnifiedConversationDto conversation) async {
    if (_sending != null) return;
    HapticFeedback.selectionClick();
    setState(() => _sending = conversation.id);
    final bridge = ref.read(messagingBridgeProvider);
    try {
      await (bridge as MessagingCardBridge).sendCard(
        conversationId: conversation.id,
        draft: widget.draft,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.pop(context, true);
      messenger?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Envoyé à ${conversation.title}'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = null);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Envoi impossible. Réessayez.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final c in _conversations ?? const <UnifiedConversationDto>[])
        if (q.isEmpty ||
            c.title.toLowerCase().contains(q) ||
            c.subtitle.toLowerCase().contains(q))
          c,
    ];
    return WouandaSheetSurface(
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const WouandaSheetHeader(title: 'Envoyer dans une conversation'),
            // What is being shared, as it will look.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WouandaSpacing.pageGutter,
                0,
                WouandaSpacing.pageGutter,
                WouandaSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    messageCardKindIcon(widget.draft.kind),
                    size: 18,
                    color: palette.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.draft.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyMd(
                        color: palette.textPrimary,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: WouandaSpacing.pageGutter,
              ),
              child: WouandaSearchInput(
                key: const ValueKey('share-search'),
                hintText: 'Rechercher une conversation',
                pill: true,
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            const SizedBox(height: WouandaSpacing.xs),
            Flexible(
              child: _conversations == null && !_failed
                  ? const Padding(
                      padding: EdgeInsets.all(WouandaSpacing.pageGutter),
                      child: WouandaSkeletonRows(
                        rows: 4,
                        label: 'Chargement des conversations',
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        if (_failed)
                          WouandaListRow(
                            icon: LucideIcons.cloudOff,
                            title: 'Conversations indisponibles',
                            trailing: IconButton(
                              tooltip: 'Réessayer',
                              onPressed: () {
                                setState(() => _failed = false);
                                _load();
                              },
                              icon: const Icon(LucideIcons.refreshCw),
                            ),
                          )
                        else if (shown.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(
                              WouandaSpacing.pageGutter,
                            ),
                            child: Text(
                              q.isEmpty
                                  ? 'Aucune conversation pour l’instant.'
                                  : 'Aucune conversation ne correspond.',
                              style: AppTheme.bodySm(
                                color: palette.textSecondary,
                              ),
                            ),
                          ),
                        for (final c in shown)
                          ListTile(
                            key: ValueKey('share-to-${c.id}'),
                            leading: MessagingAvatar(
                              conversation: c,
                              radius: 22,
                            ),
                            title: Text(
                              c.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: c.subtitle.isEmpty
                                ? null
                                : Text(
                                    c.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            trailing: _sending == c.id
                                ? const WouandaLoader(size: 20, strokeWidth: 2)
                                : Icon(
                                    LucideIcons.send,
                                    size: 20,
                                    color: palette.accent,
                                  ),
                            onTap: _sending == null ? () => _send(c) : null,
                          ),
                        if (widget.onOtherApps != null)
                          WouandaListRow(
                            key: const ValueKey('share-other-apps'),
                            icon: LucideIcons.share2,
                            title: 'Autres applications',
                            onTap: () {
                              Navigator.pop(context, false);
                              widget.onOtherApps!();
                            },
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
