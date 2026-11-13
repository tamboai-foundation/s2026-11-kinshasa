import 'package:ngoma/core/widgets/wouanda_draggable_sheet.dart';
import 'package:ngoma/core/widgets/wouanda_search_input.dart';
import 'dart:async';
import 'package:ngoma/core/widgets/wouanda_list.dart';
import 'package:ngoma/core/widgets/wouanda_loading_state.dart';

import 'package:flutter/material.dart';
import 'package:ngoma/core/widgets/wouanda_segmented_control.dart';
import 'package:ngoma/core/widgets/wouanda_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ngoma/core/platform/messaging/messaging_models.dart';
import 'package:ngoma/core/providers/messaging_provider.dart';
import 'package:ngoma/core/theme.dart';
import 'package:ngoma/features/messaging/messaging_service_style.dart';
import 'package:wouanda_design/wouanda_design.dart';
import 'package:ngoma/core/widgets/wouanda_chip_rail.dart';
import 'package:ngoma/core/widgets/wouanda_platform_widgets.dart';

class MessagingInboxScreen extends ConsumerStatefulWidget {
  final MessagingService? initialService;

  /// Where a conversation opens. A service that shows its own inbox (Stay's
  /// « Messages ») keeps the traveller inside it, so the back arrow returns
  /// where they were instead of jumping to the Messages tab.
  final String Function(int conversationId)? conversationPath;

  const MessagingInboxScreen({
    super.key,
    this.initialService,
    this.conversationPath,
  });

  @override
  ConsumerState<MessagingInboxScreen> createState() =>
      _MessagingInboxScreenState();
}

class _MessagingInboxScreenState extends ConsumerState<MessagingInboxScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  String _pathOf(int id) =>
      widget.conversationPath?.call(id) ?? '/messages/$id';

  MessagingInboxNotifier get _notifier =>
      ref.read(messagingInboxProvider(widget.initialService).notifier);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        _notifier.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _notifier.search(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagingInboxProvider(widget.initialService));
    final capabilities =
        ref.watch(messagingCapabilitiesProvider).value ??
        MessagingCapabilitiesDto.none;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kinds = [
      ConversationKind.direct,
      ConversationKind.group,
      ConversationKind.channel,
    ];
    final kindIndex = kinds.indexOf(state.kind ?? ConversationKind.direct);
    final archived = state.archived;
    final showArchive = !archived && capabilities.has(MessagingFeature.archive);
    final canCreate =
        !archived &&
        capabilities.has(MessagingFeature.newConversation) &&
        (state.kind == null || state.kind == ConversationKind.direct);
    return PopScope(
      canPop: !archived,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && archived) _notifier.setArchived(false);
      },
      child: Scaffold(
        backgroundColor: AppTheme.getBackground(isDark),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: archived
              ? IconButton(
                  tooltip: 'Retour aux messages',
                  onPressed: () => _notifier.setArchived(false),
                  icon: const Icon(LucideIcons.arrowLeft),
                )
              // Opened over a service: the way back to it.
              : Navigator.of(context).canPop()
              ? const BackButton()
              : null,
          backgroundColor: AppTheme.getBackground(isDark),
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 64,
          titleSpacing: archived || Navigator.of(context).canPop()
              ? 0
              : WouandaSpacing.pageGutter,
          title: Text(
            archived ? 'Archivées' : 'Messages',
            style: archived
                ? AppTheme.h2(color: AppTheme.getTextPrimary(isDark))
                : AppTheme.displayXL(color: AppTheme.getTextPrimary(isDark)),
          ),
          actions: [
            // Kept out of the list: one icon, not a row above the messages.
            if (showArchive)
              IconButton(
                key: const ValueKey('messaging-archived-entry'),
                tooltip: 'Archivées',
                onPressed: _openArchived,
                icon: const Icon(LucideIcons.archive),
              ),
            if (canCreate)
              IconButton(
                key: const ValueKey('messaging-new-conversation'),
                tooltip: 'Nouvelle conversation',
                onPressed: () => _startConversation(context, _notifier),
                icon: Icon(
                  LucideIcons.squarePen,
                  color: context.palette.accent,
                ),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Who the conversation is with: one person, a group, a channel.
            if (!archived)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: WouandaSegmentedControl(
                  key: const ValueKey('messaging-kinds'),
                  segments: const ['Privées', 'Groupes', 'Canaux'],
                  // A segment not shown still says it has news.
                  badges: [
                    for (final kind in kinds) state.unreadByKind[kind] ?? 0,
                  ],
                  selectedIndex: kindIndex < 0 ? 0 : kindIndex,
                  onChanged: (index) => _notifier.setKind(kinds[index]),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: WouandaSearchInput(
                key: const ValueKey('messaging-inbox-search'),
                controller: _search,
                onChanged: _onSearch,
                hintText: 'Rechercher',
                pill: true,
              ),
            ),
            if (!archived)
              // Within the kind: everything, the unread ones, a service.
              WouandaChipRail<String>(
                key: const ValueKey('messaging-filters'),
                chips: [
                  const WouandaChip(value: 'all', label: 'Tout'),
                  const WouandaChip(value: 'unread', label: 'Non lus'),
                  for (final service in MessagingService.values)
                    WouandaChip(
                      value: service.name,
                      label: messagingServiceLabel(service),
                    ),
                ],
                selected: state.unreadOnly
                    ? 'unread'
                    : state.service?.name ?? 'all',
                onSelected: (value) => _notifier.setFilter(
                  unreadOnly: value == 'unread',
                  service: MessagingService.values
                      .where((item) => item.name == value)
                      .firstOrNull,
                ),
              ),
            if (state.error != null && state.conversations.isNotEmpty)
              WouandaListRow(
                leading: const Icon(LucideIcons.cloudOff),
                title: 'Messages incomplets',
                trailing: IconButton(
                  tooltip: 'Réessayer',
                  onPressed: _notifier.load,
                  icon: const Icon(LucideIcons.refreshCw),
                ),
              ),
            Expanded(child: _buildList(state, capabilities)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    MessagingInboxState state,
    MessagingCapabilitiesDto capabilities,
  ) {
    if (state.isLoading && state.conversations.isEmpty) {
      return const WouandaLoadingState();
    }
    if (state.error != null && state.conversations.isEmpty) {
      return WouandaEmptyState(
        icon: LucideIcons.messagesSquare,
        art: WouandaArt.messages,
        title: 'Messages indisponibles',
        message: 'Impossible de charger vos conversations.',
        actionLabel: 'Réessayer',
        onAction: _notifier.load,
      );
    }
    if (state.conversations.isEmpty) {
      final canCreate =
          !state.archived &&
          capabilities.has(MessagingFeature.newConversation) &&
          (state.kind == null || state.kind == ConversationKind.direct);
      return Column(
        children: [
          Expanded(
            child: WouandaEmptyState(
              icon: LucideIcons.messagesSquare,
              art: WouandaArt.messages,
              title: state.archived
                  ? 'Aucune conversation archivée'
                  : state.unreadOnly
                  ? 'Tout est lu'
                  : 'Aucune conversation',
              message: state.search.isNotEmpty
                  ? 'Essayez un autre nom ou un autre mot.'
                  : state.archived
                  ? 'Les conversations archivées apparaîtront ici.'
                  : state.unreadOnly
                  ? 'Vous n’avez aucun message en attente.'
                  : 'Vos échanges entre les services apparaîtront ici.',
              actionLabel: canCreate && state.search.isEmpty
                  ? 'Écrire à quelqu’un'
                  : null,
              onAction: canCreate && state.search.isEmpty
                  ? () => _startConversation(context, _notifier)
                  : null,
            ),
          ),
        ],
      );
    }
    final tail = state.isLoadingMore ? 1 : 0;
    return RefreshIndicator(
      onRefresh: _notifier.load,
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 110),
        itemCount: state.conversations.length + tail,
        separatorBuilder: (_, _) => const Divider(indent: 78, height: 1),
        itemBuilder: (context, index) {
          final i = index;
          if (i >= state.conversations.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: WouandaLoadingState(),
            );
          }
          final item = state.conversations[i];
          bool allows(MessagingFeature feature) =>
              messagingAllows(capabilities, item, feature);
          return _SwipeActions(
            key: ValueKey('messaging-row-${item.id}'),
            conversation: item,
            canToggleRead: item.isUnread || allows(MessagingFeature.markUnread),
            canArchive: allows(MessagingFeature.archive),
            onToggleRead: () => _toggleRead(item),
            onArchive: () => _archive(item),
            child: _ConversationCard(
              item: item,
              showDraft: allows(MessagingFeature.drafts),
              onTap: () => context.push(_pathOf(item.id), extra: item),
              onLongPress: () => _openMenu(item, allows),
            ),
          );
        },
      ),
    );
  }

  void _openArchived() => _notifier.setArchived(true);

  Future<void> _toggleRead(UnifiedConversationDto item) => _guard(
    () => item.isUnread ? _notifier.markRead(item) : _notifier.markUnread(item),
  );

  Future<void> _archive(UnifiedConversationDto item) async {
    final archiving = !item.isArchived;
    final done = await _guard(() => _notifier.setArchivedFor(item, archiving));
    if (!done || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          archiving ? 'Conversation archivée' : 'Conversation désarchivée',
        ),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () => _guard(
            () => _notifier.setArchivedFor(
              item.copyWith(isArchived: archiving),
              !archiving,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMenu(
    UnifiedConversationDto item,
    bool Function(MessagingFeature) allows,
  ) async {
    HapticFeedback.mediumImpact();
    final entries = <(String, IconData, String, Future<void> Function())>[
      if (allows(MessagingFeature.pin))
        item.isPinned
            ? (
                'unpin',
                LucideIcons.pinOff,
                'Désépingler',
                () => _notifier.setPinned(item, false),
              )
            : (
                'pin',
                LucideIcons.pin,
                'Épingler',
                () => _notifier.setPinned(item, true),
              ),
      if (item.isUnread)
        (
          'read',
          LucideIcons.mailOpen,
          'Marquer comme lu',
          () => _notifier.markRead(item),
        )
      else if (allows(MessagingFeature.markUnread))
        (
          'unread',
          LucideIcons.mail,
          'Marquer comme non lu',
          () => _notifier.markUnread(item),
        ),
      if (allows(MessagingFeature.mute))
        item.isMuted
            ? (
                'unmute',
                LucideIcons.bell,
                'Réactiver les notifications',
                () => _notifier.setMuted(item, false),
              )
            : (
                'mute',
                LucideIcons.bellOff,
                'Mettre en sourdine',
                () => _notifier.setMuted(item, true),
              ),
      if (allows(MessagingFeature.archive))
        (
          item.isArchived ? 'unarchive' : 'archive',
          item.isArchived ? LucideIcons.archiveRestore : LucideIcons.archive,
          item.isArchived ? 'Désarchiver' : 'Archiver',
          () => _archive(item),
        ),
    ];
    if (entries.isEmpty) return;
    final chosen = await showWouandaSheet<Future<void> Function()>(
      context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: MessagingAvatar(conversation: item, radius: 20),
              title: Text(item.title, style: AppTheme.h3()),
              subtitle: Text(item.subtitle),
            ),
            const Divider(height: 1),
            for (final (key, icon, label, run) in entries)
              ListTile(
                key: ValueKey('messaging-menu-$key'),
                leading: Icon(icon),
                title: Text(label),
                onTap: () => Navigator.pop(sheetContext, run),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen != null) await _guard(chosen);
  }

  Future<bool> _guard(Future<void> Function() call) async {
    try {
      await call();
      return true;
    } on PlatformException catch (error) {
      if (!mounted) return false;
      if (error.code == 'MESSAGING_FEATURE_DISABLED') {
        ref.invalidate(messagingCapabilitiesProvider);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            error.code == 'MESSAGING_FEATURE_DISABLED'
                ? 'Cette fonction n’est plus disponible.'
                : 'L’action n’a pas abouti. Réessayez.',
          ),
        ),
      );
      return false;
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('L’action n’a pas abouti. Réessayez.')),
        );
      }
      return false;
    }
  }
}

/// « Archivées » on top of the list, as in WhatsApp.
class _SwipeActions extends StatelessWidget {
  const _SwipeActions({
    super.key,
    required this.conversation,
    required this.canToggleRead,
    required this.canArchive,
    required this.onToggleRead,
    required this.onArchive,
    required this.child,
  });

  final UnifiedConversationDto conversation;
  final bool canToggleRead;
  final bool canArchive;
  final VoidCallback onToggleRead;
  final VoidCallback onArchive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!canToggleRead && !canArchive) return child;
    final direction = canToggleRead && canArchive
        ? DismissDirection.horizontal
        : canToggleRead
        ? DismissDirection.startToEnd
        : DismissDirection.endToStart;
    Widget background(bool start) {
      final read = start;
      final color = read ? context.palette.accent : WouandaColors.ochre;
      return Container(
        color: color,
        alignment: start ? Alignment.centerLeft : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              read
                  ? (conversation.isUnread
                        ? LucideIcons.mailOpen
                        : LucideIcons.mail)
                  : (conversation.isArchived
                        ? LucideIcons.archiveRestore
                        : LucideIcons.archive),
              color: context.palette.onAccent,
            ),
            const SizedBox(height: 4),
            Text(
              read
                  ? (conversation.isUnread ? 'Lu' : 'Non lu')
                  : (conversation.isArchived ? 'Désarchiver' : 'Archiver'),
              style: AppTheme.caption(color: context.palette.onAccent),
            ),
          ],
        ),
      );
    }

    return Dismissible(
      key: ValueKey('messaging-swipe-${conversation.id}'),
      direction: direction,
      background: background(direction != DismissDirection.endToStart),
      secondaryBackground: direction == DismissDirection.horizontal
          ? background(false)
          : null,
      confirmDismiss: (dir) async {
        HapticFeedback.selectionClick();
        if (dir == DismissDirection.startToEnd) {
          onToggleRead();
        } else {
          onArchive();
        }
        // The bridge answer and its signal update the list.
        return false;
      },
      child: child,
    );
  }
}

/// One conversation, WhatsApp-style: avatar with a small service mark, the
/// name in full, « context · last message » on one line, time and unread.
class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.item,
    required this.onTap,
    required this.onLongPress,
    required this.showDraft,
  });

  final UnifiedConversationDto item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool showDraft;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final unread = item.isUnread;
    final secondary = WouandaColors.textSecondary(brightness);
    final context_ = item.contextLabel;
    final hasContext = context_ != null && RegExp(r'\d').hasMatch(context_);
    final preview = item.lastMessage ?? item.subtitle;
    final draft = showDraft && item.hasDraft;
    final badgeColor = item.isMuted ? secondary : context.palette.accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              MessagingAvatar(conversation: item),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AppTheme.bodyMd(
                                  color: WouandaColors.textPrimary(brightness),
                                ).copyWith(
                                  fontWeight: unread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (item.lastMessageAt != null)
                          Text(
                            messagingInboxTime(item.lastMessageAt!),
                            style: AppTheme.caption(
                              color: unread && !item.isMuted
                                  ? context.palette.accent
                                  : secondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (!draft &&
                            item.lastMessageIsMine &&
                            item.lastMessageDelivery != null) ...[
                          _InboxTick(delivery: item.lastMessageDelivery!),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                if (draft)
                                  TextSpan(
                                    text: 'Brouillon : ',
                                    style: AppTheme.bodySm(
                                      color: WouandaColors.negative,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  )
                                else if (hasContext)
                                  TextSpan(
                                    text: '$context_ · ',
                                    style: AppTheme.bodySm(
                                      color: WouandaColors.textPrimary(
                                        brightness,
                                      ),
                                    ),
                                  ),
                                TextSpan(text: draft ? item.draft : preview),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodySm(
                              color: unread
                                  ? WouandaColors.textPrimary(brightness)
                                  : secondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (item.isMuted)
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Icon(
                              LucideIcons.bellOff,
                              size: 15,
                              color: secondary,
                              semanticLabel: 'En sourdine',
                            ),
                          ),
                        if (item.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              LucideIcons.pin,
                              size: 15,
                              color: secondary,
                              semanticLabel: 'Épinglée',
                            ),
                          ),
                        if (item.unreadCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Badge(
                              backgroundColor: badgeColor,
                              label: Text('${item.unreadCount}'),
                            ),
                          )
                        else if (item.isMarkedUnread)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Container(
                              key: const ValueKey('messaging-marked-unread'),
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: badgeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxTick extends StatelessWidget {
  const _InboxTick({required this.delivery});
  final MessageDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final color = WouandaColors.textSecondary(Theme.of(context).brightness);
    return switch (delivery) {
      MessageDelivery.sending => Icon(
        LucideIcons.clock3,
        size: 14,
        color: color,
      ),
      MessageDelivery.queued => Icon(
        LucideIcons.clock3,
        size: 14,
        color: color,
      ),
      MessageDelivery.sent => Icon(LucideIcons.check, size: 15, color: color),
      MessageDelivery.delivered => Icon(
        LucideIcons.checkCheck,
        size: 15,
        color: color,
      ),
      MessageDelivery.read => Icon(
        LucideIcons.checkCheck,
        size: 15,
        color: context.palette.accent,
      ),
      MessageDelivery.failed => const Icon(
        LucideIcons.circleAlert,
        size: 15,
        color: WouandaColors.negative,
      ),
    };
  }
}

/// « 14:05 » today, « Hier », weekday this week, then « 12/09/26 ».
String messagingInboxTime(DateTime value, {DateTime? now}) {
  final local = value.toLocal();
  final today = now ?? DateTime.now();
  final days = DateTime(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime(local.year, local.month, local.day)).inDays;
  if (days <= 0) return DateFormat('HH:mm').format(local);
  if (days == 1) return 'Hier';
  if (days < 7) {
    final name = DateFormat('EEEE', 'fr_FR').format(local);
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }
  return DateFormat('dd/MM/yy').format(local);
}

Future<void> _startConversation(
  BuildContext context,
  MessagingInboxNotifier inboxNotifier,
) async {
  final conversation = await showWouandaSheet<UnifiedConversationDto>(
    context,
    showDragHandle: true,
    builder: (_) => const _RecipientsSheet(),
  );
  if (conversation != null && context.mounted) {
    inboxNotifier.setService(null);
    context.push('/messages/${conversation.id}', extra: conversation);
  }
}

class _RecipientsSheet extends ConsumerWidget {
  const _RecipientsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messagingRecipientsProvider);
    final notifier = ref.read(messagingRecipientsProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .68,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nouvelle conversation', style: AppTheme.h2()),
              const SizedBox(height: 14),
              WouandaSearchInput(
                autofocus: true,
                onChanged: notifier.search,
                hintText: 'Rechercher une personne',
              ),
              const SizedBox(height: 8),
              if (state.isLoading) const LinearProgressIndicator(),
              if (state.error != null)
                ListTile(
                  title: const Text('Recherche indisponible'),
                  trailing: IconButton(
                    tooltip: 'Réessayer',
                    onPressed: () => notifier.search(''),
                    icon: const Icon(LucideIcons.refreshCw),
                  ),
                ),
              Expanded(
                child: state.isLoading && state.recipients.isEmpty
                    ? const WouandaLoadingState()
                    : state.recipients.isEmpty && state.error == null
                    ? const WouandaEmptyState(
                        icon: LucideIcons.search,
                        art: WouandaArt.search,
                        title: 'Personne trouvée',
                        message: 'Essayez avec un autre nom.',
                      )
                    : ListView.builder(
                        itemCount: state.recipients.length,
                        itemBuilder: (context, index) {
                          final recipient = state.recipients[index];
                          return ListTile(
                            leading: WouandaPersonAvatar(
                              name: recipient.displayName,
                              photoUrl: recipient.avatarUrl,
                            ),
                            title: Text(recipient.displayName),
                            subtitle: recipient.subtitle == null
                                ? null
                                : Text(recipient.subtitle!),
                            trailing: state.isOpening
                                ? const WouandaBusyBar(size: 18)
                                : const Icon(LucideIcons.chevronRight),
                            onTap: state.isOpening
                                ? null
                                : () async {
                                    try {
                                      final conversation = await notifier
                                          .openConversation(recipient.id);
                                      if (context.mounted) {
                                        Navigator.of(context).pop(conversation);
                                      }
                                    } on Object {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Impossible d’ouvrir cette conversation.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
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
