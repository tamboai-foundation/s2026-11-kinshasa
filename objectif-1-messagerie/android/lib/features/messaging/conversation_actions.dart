import 'package:ngoma/core/widgets/wouanda_draggable_sheet.dart';
import 'package:ngoma/core/widgets/wouanda_search_input.dart';
import 'package:flutter/material.dart';
import 'package:ngoma/core/widgets/wouanda_loading_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ngoma/core/platform/messaging/messaging_models.dart';
import 'package:ngoma/core/providers/messaging_provider.dart';
import 'package:ngoma/core/theme.dart';
import 'package:ngoma/core/widgets/wouanda_list.dart';
import 'package:ngoma/core/widgets/wouanda_platform_widgets.dart';
import 'package:ngoma/features/messaging/conversation_parts.dart';
import 'package:wouanda_design/wouanda_design.dart';

/// What the long-press menu offers. Each entry is shown only when the
/// bridge allows it (capabilities ∩ conversation, plus message rights).
enum MessageAction {
  reply,
  copy,
  edit,
  forward,
  report,
  deleteForMe,
  deleteForEveryone,
  retry,
  discard,
}

/// Either an action or a reaction key chosen in [showMessageActions].
class MessageActionChoice {
  const MessageActionChoice.action(MessageAction this.action) : reaction = null;
  const MessageActionChoice.reaction(String this.reaction) : action = null;
  final MessageAction? action;
  final String? reaction;
}

/// Actions allowed on [message], in menu order.
List<MessageAction> messageActionsFor(
  UnifiedMessageDto message,
  bool Function(MessagingFeature) allows,
) {
  if (message.isSystem) return const [];
  if (message.delivery == MessageDelivery.failed ||
      message.delivery == MessageDelivery.queued) {
    return [
      MessageAction.retry,
      if (message.content.isNotEmpty && allows(MessagingFeature.copy))
        MessageAction.copy,
      MessageAction.discard,
    ];
  }
  if (message.delivery == MessageDelivery.sending) return const [];
  return [
    if (!message.isDeleted && allows(MessagingFeature.reply))
      MessageAction.reply,
    if (!message.isDeleted &&
        message.content.isNotEmpty &&
        allows(MessagingFeature.copy))
      MessageAction.copy,
    if (message.canEdit && allows(MessagingFeature.edit)) MessageAction.edit,
    if (!message.isDeleted && allows(MessagingFeature.forward))
      MessageAction.forward,
    if (!message.isMine &&
        !message.isDeleted &&
        allows(MessagingFeature.report))
      MessageAction.report,
    if (allows(MessagingFeature.deleteForMe)) MessageAction.deleteForMe,
    if (message.canDeleteForEveryone &&
        allows(MessagingFeature.deleteForEveryone))
      MessageAction.deleteForEveryone,
  ];
}

Future<MessageActionChoice?> showMessageActions(
  BuildContext context, {
  required UnifiedMessageDto message,
  required List<MessageAction> actions,
  required bool canReact,
}) {
  if (actions.isEmpty && !canReact) return Future.value();
  return showWouandaSheet<MessageActionChoice>(
    context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          12 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MessageExcerpt(message: message),
            if (canReact) ...[
              const SizedBox(height: 14),
              _ReactionPicker(
                selected: message.reactions
                    .where((item) => item.isMine)
                    .firstOrNull
                    ?.key,
                onSelected: (key) => Navigator.pop(
                  sheetContext,
                  MessageActionChoice.reaction(key),
                ),
              ),
            ],
            if (actions.isNotEmpty) const SizedBox(height: 8),
            for (final action in actions)
              _ActionRow(
                action: action,
                onTap: () => Navigator.pop(
                  sheetContext,
                  MessageActionChoice.action(action),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// The first emoji of [typed], or null when it holds none. The emoji comes
/// from the phone's own keyboard: the app ships no emoji of its own.
String? firstEmoji(String typed) {
  for (final grapheme in typed.characters) {
    if (grapheme.runes.any((rune) => rune >= 0x2190)) return grapheme;
  }
  return null;
}

class _MessageExcerpt extends StatelessWidget {
  const _MessageExcerpt({required this.message});
  final UnifiedMessageDto message;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WouandaColors.surfaceMuted(brightness),
        borderRadius: BorderRadius.circular(WouandaSpacing.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${message.isMine ? 'Vous' : message.senderLabel} · '
            '${DateFormat('d MMM, HH:mm', 'fr_FR').format(message.createdAt)}',
            style: AppTheme.caption(
              color: WouandaColors.textSecondary(brightness),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            messagePreview(message),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyMd(
              color: WouandaColors.textPrimary(brightness),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reacting uses the phone's emoji keyboard, as in any native messenger:
/// one tap opens the field, the first emoji typed is the reaction.
class _ReactionPicker extends StatefulWidget {
  const _ReactionPicker({required this.selected, required this.onSelected});
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  State<_ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<_ReactionPicker> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _typing = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _open() {
    setState(() => _typing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _typed(String value) {
    final emoji = firstEmoji(value);
    if (emoji != null) {
      widget.onSelected(emoji);
    } else if (value.isNotEmpty) {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final muted = WouandaColors.textSecondary(brightness);
    final selected = widget.selected;
    return Container(
      key: const ValueKey('messaging-reaction-picker'),
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: WouandaColors.surface(brightness),
        borderRadius: BorderRadius.circular(WouandaSpacing.radiusPill),
        border: Border.all(color: WouandaColors.border(brightness)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.smilePlus, size: 20, color: context.palette.accent),
          const SizedBox(width: 10),
          Expanded(
            child: _typing
                ? TextField(
                    key: const ValueKey('messaging-react-field'),
                    controller: _controller,
                    focusNode: _focus,
                    onChanged: _typed,
                    style: AppTheme.bodyMd(
                      color: WouandaColors.textPrimary(brightness),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Choisissez un emoji sur votre clavier',
                      hintStyle: AppTheme.bodyMd(color: muted),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                    ),
                  )
                : InkWell(
                    key: const ValueKey('messaging-react-open'),
                    onTap: _open,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'Réagir avec un emoji',
                        style: AppTheme.bodyMd(color: muted),
                      ),
                    ),
                  ),
          ),
          if (selected != null)
            Semantics(
              button: true,
              label: 'Retirer votre réaction',
              child: InkWell(
                key: const ValueKey('messaging-react-current'),
                borderRadius: BorderRadius.circular(WouandaSpacing.radiusPill),
                onTap: () => widget.onSelected(selected),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.palette.accent.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(
                      WouandaSpacing.radiusPill,
                    ),
                  ),
                  child: ReactionGlyph(selected, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action, required this.onTap});
  final MessageAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final destructive =
        action == MessageAction.deleteForMe ||
        action == MessageAction.deleteForEveryone ||
        action == MessageAction.discard ||
        action == MessageAction.report;
    final color = destructive
        ? WouandaColors.negative
        : context.palette.textPrimary;
    return ListTile(
      key: ValueKey('messaging-action-${action.name}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(_actionIcon(action), color: color, size: 22),
      title: Text(_actionLabel(action), style: AppTheme.bodyMd(color: color)),
      onTap: onTap,
    );
  }
}

IconData _actionIcon(MessageAction action) => switch (action) {
  MessageAction.reply => LucideIcons.reply,
  MessageAction.copy => LucideIcons.copy,
  MessageAction.edit => LucideIcons.pencil,
  MessageAction.forward => LucideIcons.forward,
  MessageAction.report => LucideIcons.flag,
  MessageAction.deleteForMe => LucideIcons.trash2,
  MessageAction.deleteForEveryone => LucideIcons.trash2,
  MessageAction.retry => LucideIcons.rotateCw,
  MessageAction.discard => LucideIcons.x,
};

String _actionLabel(MessageAction action) => switch (action) {
  MessageAction.reply => 'Répondre',
  MessageAction.copy => 'Copier',
  MessageAction.edit => 'Modifier',
  MessageAction.forward => 'Transférer',
  MessageAction.report => 'Signaler',
  MessageAction.deleteForMe => 'Supprimer pour moi',
  MessageAction.deleteForEveryone => 'Supprimer pour tous',
  MessageAction.retry => 'Renvoyer',
  MessageAction.discard => 'Ne pas envoyer',
};

// ─── Composer context ────────────────────────────────────────────────

/// Above the composer: the message being answered or edited.
class ComposerContextBanner extends StatelessWidget {
  const ComposerContextBanner({
    super.key,
    required this.message,
    required this.editing,
    required this.onClose,
  });
  final UnifiedMessageDto message;
  final bool editing;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final accent = context.palette.accent;
    return Container(
      key: ValueKey(editing ? 'messaging-editing' : 'messaging-replying'),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: WouandaColors.surface(brightness),
        borderRadius: BorderRadius.circular(WouandaSpacing.radiusMedium),
        border: Border.all(color: WouandaColors.border(brightness)),
      ),
      child: Row(
        children: [
          Icon(
            editing ? LucideIcons.pencil : LucideIcons.reply,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 10),
          Container(width: 3, height: 34, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  editing
                      ? 'Modifier le message'
                      : 'Répondre à ${message.isMine ? 'vous-même' : message.senderLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.caption(
                    color: accent,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  messagePreview(message),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySm(
                    color: WouandaColors.textSecondary(brightness),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: editing ? 'Annuler la modification' : 'Annuler la réponse',
            onPressed: onClose,
            icon: const Icon(LucideIcons.x, size: 18),
          ),
        ],
      ),
    );
  }
}

// ─── Forward ─────────────────────────────────────────────────────────

/// Pick one or several conversations; returns their ids.
Future<List<int>?> showForwardSheet(
  BuildContext context, {
  required int excludeId,
}) => showWouandaSheet<List<int>>(
  context,
  showDragHandle: true,
  builder: (_) => _ForwardSheet(excludeId: excludeId),
);

class _ForwardSheet extends ConsumerStatefulWidget {
  const _ForwardSheet({required this.excludeId});
  final int excludeId;

  @override
  ConsumerState<_ForwardSheet> createState() => _ForwardSheetState();
}

class _ForwardSheetState extends ConsumerState<_ForwardSheet> {
  final _selected = <int>{};

  @override
  Widget build(BuildContext context) {
    final targets = ref.watch(messagingForwardTargetsProvider);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Transférer à', style: AppTheme.h2()),
            ),
            Expanded(
              child: targets.when(
                loading: () => const WouandaLoadingState(),
                error: (_, _) => WouandaEmptyState(
                  icon: LucideIcons.messagesSquare,
                  art: WouandaArt.messages,
                  title: 'Conversations indisponibles',
                  message: 'Réessayez dans un instant.',
                  actionLabel: 'Réessayer',
                  onAction: () =>
                      ref.invalidate(messagingForwardTargetsProvider),
                ),
                data: (items) {
                  final list = [
                    for (final item in items)
                      if (item.id != widget.excludeId) item,
                  ];
                  if (list.isEmpty) {
                    return const WouandaEmptyState(
                      icon: LucideIcons.messagesSquare,
                      art: WouandaArt.messages,
                      title: 'Aucune conversation',
                      message:
                          'Aucune conversation ne peut recevoir ce message.',
                    );
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return CheckboxListTile(
                        key: ValueKey('messaging-forward-${item.id}'),
                        value: _selected.contains(item.id),
                        onChanged: (value) => setState(
                          () => value == true
                              ? _selected.add(item.id)
                              : _selected.remove(item.id),
                        ),
                        secondary: CircleAvatar(
                          backgroundColor: context.palette.surfaceMuted,
                          child: Text(
                            item.title.isEmpty ? '?' : item.title[0],
                            style: AppTheme.bodyMd(
                              color: context.palette.textPrimary,
                            ),
                          ),
                        ),
                        title: Text(item.title),
                        subtitle: Text(item.subtitle),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: FilledButton.icon(
                key: const ValueKey('messaging-forward-send'),
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.pop(context, _selected.toList()),
                icon: const Icon(LucideIcons.send, size: 18),
                label: Text(
                  _selected.length <= 1
                      ? 'Envoyer'
                      : 'Envoyer à ${_selected.length} conversations',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Report ──────────────────────────────────────────────────────────

const messagingReportReasons = <String, String>{
  'spam': 'Indésirable',
  'harassment': 'Harcèlement',
  'fraud': 'Arnaque ou fraude',
  'inappropriate': 'Contenu inapproprié',
  'other': 'Autre raison',
};

Future<String?> showReportSheet(BuildContext context, {bool message = false}) =>
    showWouandaSheet<String>(
      context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                message ? 'Signaler ce message' : 'Signaler la conversation',
                style: AppTheme.h2(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'L’équipe Wouanda examine chaque signalement. '
                'L’autre personne n’est pas prévenue.',
                style: AppTheme.bodySm(
                  color: WouandaColors.textSecondary(
                    Theme.of(sheetContext).brightness,
                  ),
                ),
              ),
            ),
            for (final entry in messagingReportReasons.entries)
              ListTile(
                key: ValueKey('messaging-report-${entry.key}'),
                title: Text(entry.value),
                trailing: const Icon(LucideIcons.chevronRight, size: 18),
                onTap: () => Navigator.pop(sheetContext, entry.key),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

// ─── Search ──────────────────────────────────────────────────────────

/// Search inside one conversation; returns the chosen message.
Future<UnifiedMessageDto?> showConversationSearch(
  BuildContext context, {
  required Future<List<UnifiedMessageDto>> Function(String) search,
}) => showWouandaSheet<UnifiedMessageDto>(
  context,
  showDragHandle: true,
  builder: (_) => _ConversationSearchSheet(search: search),
);

class _ConversationSearchSheet extends StatefulWidget {
  const _ConversationSearchSheet({required this.search});
  final Future<List<UnifiedMessageDto>> Function(String) search;

  @override
  State<_ConversationSearchSheet> createState() =>
      _ConversationSearchSheetState();
}

class _ConversationSearchSheetState extends State<_ConversationSearchSheet> {
  List<UnifiedMessageDto> _results = const [];
  String _query = '';
  bool _loading = false;
  bool _failed = false;
  int _revision = 0;

  Future<void> _run(String query) async {
    final revision = ++_revision;
    setState(() {
      _query = query;
      _loading = query.trim().isNotEmpty;
      _failed = false;
    });
    if (query.trim().isEmpty) {
      setState(() => _results = const []);
      return;
    }
    try {
      final results = await widget.search(query);
      if (!mounted || revision != _revision) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } on Object {
      if (!mounted || revision != _revision) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: WouandaSearchInput(
                  key: const ValueKey('messaging-search-field'),
                  autofocus: true,
                  onChanged: _run,
                  hintText: 'Rechercher dans la conversation',
                ),
              ),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: _failed
                    ? WouandaEmptyState(
                        icon: LucideIcons.search,
                        art: WouandaArt.search,
                        title: 'Recherche indisponible',
                        message: 'Vérifiez la connexion puis réessayez.',
                        actionLabel: 'Réessayer',
                        onAction: () => _run(_query),
                      )
                    : _query.trim().isNotEmpty && _results.isEmpty && !_loading
                    ? const WouandaEmptyState(
                        icon: LucideIcons.search,
                        art: WouandaArt.search,
                        title: 'Aucun message trouvé',
                        message: 'Essayez avec un autre mot.',
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final message = _results[index];
                          return WouandaListRow(
                            title: message.isMine
                                ? 'Vous'
                                : message.senderLabel,
                            subtitle: messagePreview(message),
                            trailing: Text(
                              DateFormat(
                                'd MMM',
                                'fr_FR',
                              ).format(message.createdAt),
                              style: AppTheme.caption(
                                color: WouandaColors.textSecondary(brightness),
                              ),
                            ),
                            onTap: () => Navigator.pop(context, message),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Details ─────────────────────────────────────────────────────────

/// Choices made in the conversation details sheet.
enum ConversationDetailAction {
  search,
  mute,
  unmute,
  pin,
  unpin,
  archive,
  unarchive,
  block,
  unblock,
  report,
  openContext,
}

Future<ConversationDetailAction?> showConversationDetails(
  BuildContext context, {
  required UnifiedConversationDto conversation,
  required bool Function(MessagingFeature) allows,
  required MessagingPeerStatusDto status,
  required Color serviceColor,
  required IconData serviceIcon,
  required bool canOpenContext,
}) => showWouandaSheet<ConversationDetailAction>(
  context,
  showDragHandle: true,
  builder: (sheetContext) {
    final brightness = Theme.of(sheetContext).brightness;
    void pick(ConversationDetailAction action) =>
        Navigator.pop(sheetContext, action);
    final presence = describePresence(status);
    Widget row(
      ConversationDetailAction action,
      IconData icon,
      String label, {
      bool destructive = false,
    }) => ListTile(
      key: ValueKey('messaging-detail-${action.name}'),
      leading: Icon(
        icon,
        color: destructive
            ? WouandaColors.negative
            : WouandaColors.textPrimary(brightness),
      ),
      title: Text(
        label,
        style: AppTheme.bodyMd(
          color: destructive
              ? WouandaColors.negative
              : WouandaColors.textPrimary(brightness),
        ),
      ),
      onTap: () => pick(action),
    );
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: serviceColor.withValues(alpha: .12),
              child: Text(
                conversation.title.isEmpty
                    ? '?'
                    : conversation.title[0].toUpperCase(),
                style: AppTheme.h1(color: serviceColor),
              ),
            ),
            const SizedBox(height: 10),
            Text(conversation.title, style: AppTheme.h2()),
            const SizedBox(height: 2),
            Text(
              presence ?? conversation.subtitle,
              style: AppTheme.bodySm(
                color: WouandaColors.textSecondary(brightness),
              ),
            ),
            if (conversation.contextLabel != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: WouandaColors.surfaceMuted(brightness),
                  borderRadius: BorderRadius.circular(
                    WouandaSpacing.radiusMedium,
                  ),
                  child: ListTile(
                    leading: Icon(serviceIcon, color: serviceColor),
                    title: Text(conversation.contextLabel!),
                    trailing: canOpenContext
                        ? const Icon(LucideIcons.chevronRight, size: 18)
                        : null,
                    onTap: canOpenContext
                        ? () => pick(ConversationDetailAction.openContext)
                        : null,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (allows(MessagingFeature.search))
              row(
                ConversationDetailAction.search,
                LucideIcons.search,
                'Rechercher dans la conversation',
              ),
            if (allows(MessagingFeature.mute))
              conversation.isMuted
                  ? row(
                      ConversationDetailAction.unmute,
                      LucideIcons.bell,
                      'Réactiver les notifications',
                    )
                  : row(
                      ConversationDetailAction.mute,
                      LucideIcons.bellOff,
                      'Mettre en sourdine',
                    ),
            if (allows(MessagingFeature.pin))
              conversation.isPinned
                  ? row(
                      ConversationDetailAction.unpin,
                      LucideIcons.pinOff,
                      'Désépingler',
                    )
                  : row(
                      ConversationDetailAction.pin,
                      LucideIcons.pin,
                      'Épingler',
                    ),
            if (allows(MessagingFeature.archive))
              conversation.isArchived
                  ? row(
                      ConversationDetailAction.unarchive,
                      LucideIcons.archiveRestore,
                      'Désarchiver',
                    )
                  : row(
                      ConversationDetailAction.archive,
                      LucideIcons.archive,
                      'Archiver',
                    ),
            if (allows(MessagingFeature.block))
              conversation.isBlocked
                  ? row(
                      ConversationDetailAction.unblock,
                      LucideIcons.circleCheck,
                      'Débloquer',
                    )
                  : row(
                      ConversationDetailAction.block,
                      LucideIcons.ban,
                      'Bloquer',
                      destructive: true,
                    ),
            if (allows(MessagingFeature.report))
              row(
                ConversationDetailAction.report,
                LucideIcons.flag,
                'Signaler',
                destructive: true,
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  },
);

/// « en ligne », « vu aujourd’hui à 14:05 »…; null when unknown.
String? describePresence(MessagingPeerStatusDto status, {DateTime? now}) {
  if (status.isOnline) return 'en ligne';
  final seen = status.lastSeenAt?.toLocal();
  if (seen == null) return null;
  final today = now ?? DateTime.now();
  final days = DateTime(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime(seen.year, seen.month, seen.day)).inDays;
  final time = DateFormat('HH:mm').format(seen);
  return switch (days) {
    0 => 'vu aujourd’hui à $time',
    1 => 'vu hier à $time',
    _ => 'vu le ${DateFormat('d MMM', 'fr_FR').format(seen)}',
  };
}
