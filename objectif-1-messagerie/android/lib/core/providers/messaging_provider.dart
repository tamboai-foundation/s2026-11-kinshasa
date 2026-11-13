import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ngoma/core/platform/messaging/messaging_bridge.dart';
import 'package:ngoma/core/platform/messaging/messaging_bridge_provider.dart';
import 'package:ngoma/core/platform/messaging/messaging_bridge_native.dart';
import 'package:ngoma/core/platform/messaging/messaging_models.dart';
import 'package:ngoma/core/platform/messaging/messaging_outbox.dart';
import 'package:ngoma/core/providers/user_provider.dart';

// ─── Capabilities ────────────────────────────────────────────────────────

/// Global switches from the bridge, reloaded on the `capabilities` signal.
/// Until the bridge answers (or if it fails) nothing optional is shown.
final messagingCapabilitiesProvider = StreamProvider<MessagingCapabilitiesDto>((
  ref,
) async* {
  final bridge = ref.watch(messagingBridgeProvider);
  Future<MessagingCapabilitiesDto> read() async {
    try {
      return await bridge.getCapabilities();
    } on Object {
      return MessagingCapabilitiesDto.none;
    }
  }

  yield await read();
  await for (final signal in bridge.eventsStream) {
    if (signal == 'capabilities') yield await read();
  }
});

/// A command shows only if the feature is on globally and in [conversation].
bool messagingAllows(
  MessagingCapabilitiesDto capabilities,
  UnifiedConversationDto conversation,
  MessagingFeature feature,
) => capabilities.has(feature) && conversation.features.contains(feature);

// ─── Inbox ───────────────────────────────────────────────────────────────

class MessagingInboxState {
  final List<UnifiedConversationDto> conversations;
  final MessagingService? service;
  final ConversationKind? kind;
  final String search;
  final bool archived;
  final bool unreadOnly;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final int unreadCount;

  /// Unread per kind (Privées, Groupes, Canaux), when the bridge says it.
  final Map<ConversationKind, int> unreadByKind;

  const MessagingInboxState({
    this.conversations = const [],
    this.service,
    this.kind = ConversationKind.direct,
    this.search = '',
    this.archived = false,
    this.unreadOnly = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.unreadCount = 0,
    this.unreadByKind = const {},
  });

  MessagingInboxState copyWith({
    List<UnifiedConversationDto>? conversations,
    MessagingService? service,
    ConversationKind? kind,
    bool clearService = false,
    bool clearKind = false,
    String? search,
    bool? archived,
    bool? unreadOnly,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    int? unreadCount,
    Map<ConversationKind, int>? unreadByKind,
    bool clearError = false,
  }) => MessagingInboxState(
    conversations: conversations ?? this.conversations,
    service: clearService ? null : (service ?? this.service),
    kind: clearKind ? null : (kind ?? this.kind),
    search: search ?? this.search,
    archived: archived ?? this.archived,
    unreadOnly: unreadOnly ?? this.unreadOnly,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    error: clearError ? null : (error ?? this.error),
    unreadCount: unreadCount ?? this.unreadCount,
    unreadByKind: unreadByKind ?? this.unreadByKind,
  );
}

class MessagingInboxNotifier extends StateNotifier<MessagingInboxState> {
  MessagingInboxNotifier(
    MessagingBridge bridge,
    MessagingService? initialService,
  ) : _bridge = bridge is MessagingBridgeNative
          ? MessagingBridgeNative(
              scope: 'inbox:${initialService?.name ?? 'all'}',
            )
          : bridge,
      super(MessagingInboxState(service: initialService)) {
    _signals = _bridge.eventsStream.listen((signal) {
      if (signal == 'conversations' ||
          signal == 'unread' ||
          signal == 'capabilities') {
        load();
      }
    });
    load();
  }

  final MessagingBridge _bridge;
  late final StreamSubscription<String> _signals;
  int _loadRevision = 0;

  ConversationQuery get _query => ConversationQuery(
    service: state.service,
    kind: state.kind,
    search: state.search,
    archived: state.archived,
    unreadOnly: state.unreadOnly,
  );

  Future<void> load() async {
    final revision = ++_loadRevision;
    final query = _query;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      List<UnifiedConversationDto> items;
      Object? syncError;
      try {
        items = await _bridge.loadConversations(query);
      } on MessagingPartialFailure catch (e) {
        items = e.conversations ?? const [];
        syncError = e;
      }
      int unreadCount;
      try {
        unreadCount = await _bridge.getUnreadCount();
      } on MessagingPartialFailure catch (e) {
        unreadCount = e.unreadCount ?? state.unreadCount;
        syncError ??= e;
      }

      Map<ConversationKind, int>? byKind;
      final bridge = _bridge;
      if (bridge is MessagingUnreadByKindBridge) {
        try {
          byKind = await (bridge as MessagingUnreadByKindBridge)
              .getUnreadCountsByKind();
        } catch (_) {
          // Without it the segments simply show no count.
        }
      }

      if (!mounted || revision != _loadRevision) return;
      state = state.copyWith(
        conversations: items,
        unreadCount: unreadCount,
        unreadByKind: byKind,
        error: syncError,
        clearError: syncError == null,
        isLoading: false,
        hasMore: _bridge is MessagingPaginationBridge
            ? (_bridge as MessagingPaginationBridge).hasMoreConversations
            : items.length >= 20,
      );
    } catch (error) {
      if (!mounted || revision != _loadRevision) return;
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final items = await _bridge.loadMoreConversations();
      if (!mounted) return;
      state = state.copyWith(
        conversations: [...state.conversations, ...items],
        isLoadingMore: false,
        hasMore: _bridge is MessagingPaginationBridge
            ? (_bridge as MessagingPaginationBridge).hasMoreConversations
            : items.isNotEmpty,
      );
    } on Object {
      if (mounted) state = state.copyWith(isLoadingMore: false);
    }
  }

  void setService(MessagingService? service) {
    state = state.copyWith(service: service, clearService: service == null);
    load();
  }

  /// The one filter of the inbox (a chip): a service, a kind, or the unread
  /// ones — set together, loaded once.
  void setFilter({MessagingService? service, bool unreadOnly = false}) {
    state = state.copyWith(
      service: service,
      clearService: service == null,
      unreadOnly: unreadOnly,
    );
    load();
  }

  void setKind(ConversationKind? kind) {
    state = state.copyWith(kind: kind, clearKind: kind == null);
    load();
  }

  void search(String value) {
    if (value.trim() == state.search.trim()) return;
    state = state.copyWith(search: value);
    load();
  }

  void setArchived(bool archived) {
    state = state.copyWith(archived: archived);
    load();
  }

  void setUnreadOnly(bool unreadOnly) {
    state = state.copyWith(unreadOnly: unreadOnly);
    load();
  }

  /// Applies the bridge's answer at once; the signal reload keeps order.
  Future<void> _apply(Future<UnifiedConversationDto> change) async {
    final updated = await change;
    if (!mounted) return;
    state = state.copyWith(
      conversations: [
        for (final item in state.conversations)
          item.id == updated.id ? updated : item,
      ],
    );
  }

  Future<void> setPinned(UnifiedConversationDto item, bool value) =>
      _apply(_bridge.setPinned(item.id, value));

  Future<void> setMuted(UnifiedConversationDto item, bool value) =>
      _apply(_bridge.setMuted(item.id, value));

  Future<void> setArchivedFor(UnifiedConversationDto item, bool value) async {
    await _bridge.setArchived(item.id, value);
    if (!mounted) return;
    state = state.copyWith(
      conversations: [
        for (final other in state.conversations)
          if (other.id != item.id) other,
      ],
    );
  }

  Future<void> markUnread(UnifiedConversationDto item) =>
      _apply(_bridge.markConversationUnread(item.id));

  Future<void> markRead(UnifiedConversationDto item) async {
    await _bridge.markConversationRead(item.id);
    if (!mounted) return;
    state = state.copyWith(
      conversations: [
        for (final other in state.conversations)
          other.id == item.id
              ? other.copyWith(unreadCount: 0, isMarkedUnread: false)
              : other,
      ],
    );
  }

  @override
  void dispose() {
    _signals.cancel();
    super.dispose();
  }
}

final messagingInboxProvider =
    StateNotifierProvider.family<
      MessagingInboxNotifier,
      MessagingInboxState,
      MessagingService?
    >((ref, initialService) {
      return MessagingInboxNotifier(
        ref.watch(messagingBridgeProvider),
        initialService,
      );
    });

/// Every conversation one can write to, for « Transférer ».
final messagingForwardTargetsProvider =
    FutureProvider.autoDispose<List<UnifiedConversationDto>>((ref) async {
      final bridge = ref.watch(messagingBridgeProvider);
      final items = <UnifiedConversationDto>[];
      for (final kind in ConversationKind.values) {
        items.addAll(
          await bridge.loadConversations(ConversationQuery(kind: kind)),
        );
      }
      return [
        for (final item in items)
          if (item.canSend &&
              !item.isBlocked &&
              item.features.contains(MessagingFeature.forward))
            item,
      ];
    });

// ─── Recipients ──────────────────────────────────────────────────────────

class MessagingRecipientsState {
  final List<MessagingRecipientDto> recipients;
  final bool isLoading;
  final bool isOpening;
  final Object? error;

  const MessagingRecipientsState({
    this.recipients = const [],
    this.isLoading = false,
    this.isOpening = false,
    this.error,
  });

  MessagingRecipientsState copyWith({
    List<MessagingRecipientDto>? recipients,
    bool? isLoading,
    bool? isOpening,
    Object? error,
    bool clearError = false,
  }) => MessagingRecipientsState(
    recipients: recipients ?? this.recipients,
    isLoading: isLoading ?? this.isLoading,
    isOpening: isOpening ?? this.isOpening,
    error: clearError ? null : (error ?? this.error),
  );
}

class MessagingRecipientsNotifier
    extends StateNotifier<MessagingRecipientsState> {
  MessagingRecipientsNotifier(this._bridge)
    : super(const MessagingRecipientsState()) {
    search('');
  }

  final MessagingBridge _bridge;
  int _searchRevision = 0;

  Future<void> search(String query) async {
    final revision = ++_searchRevision;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final recipients = await _bridge.searchRecipients(query);
      if (!mounted || revision != _searchRevision) return;
      state = state.copyWith(recipients: recipients, isLoading: false);
    } catch (error) {
      if (!mounted || revision != _searchRevision) return;
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<UnifiedConversationDto> openConversation(int recipientId) async {
    state = state.copyWith(isOpening: true, clearError: true);
    try {
      final conversation = await _bridge.openDirectConversation(recipientId);
      if (mounted) state = state.copyWith(isOpening: false);
      return conversation;
    } catch (error) {
      if (mounted) state = state.copyWith(isOpening: false, error: error);
      rethrow;
    }
  }
}

final messagingRecipientsProvider =
    StateNotifierProvider.autoDispose<
      MessagingRecipientsNotifier,
      MessagingRecipientsState
    >((ref) => MessagingRecipientsNotifier(ref.watch(messagingBridgeProvider)));

// ─── Outbox ──────────────────────────────────────────────────────────────

/// What the account wrote and the bridge has not confirmed (contract
/// messaging v4.1). One per account, alive as long as the app: leaving a
/// conversation or the network never loses a message.
final messagingOutboxProvider = Provider<MessagingOutbox>((ref) {
  ref.watch(userProvider.select((u) => u.id));
  final outbox = MessagingOutbox(
    bridge: () => ref.read(messagingBridgeProvider),
  );
  ref.onDispose(outbox.dispose);
  unawaited(outbox.restore());
  return outbox;
});

// ─── One conversation ────────────────────────────────────────────────────

/// A message typed here and not yet confirmed by the bridge.
class PendingMessage {
  const PendingMessage({
    required this.message,
    required this.text,
    required this.attachmentIds,
    this.replyToId,
  });

  /// Shown as a bubble in `sending` or `failed`.
  final UnifiedMessageDto message;
  final String text;
  final List<int> attachmentIds;
  final int? replyToId;

  bool get failed => message.delivery == MessageDelivery.failed;
}

class ConversationMessagesState {
  /// Messages confirmed by the bridge, oldest first.
  final List<UnifiedMessageDto> confirmed;
  final List<PendingMessage> pending;
  final UnifiedConversationDto? conversation;
  final MessagingPeerStatusDto peerStatus;
  final bool isLoading;
  final bool isLoadingOlder;
  final bool hasOlder;

  /// First message that was unread when the conversation opened.
  final int? firstUnreadId;
  final Object? error;

  const ConversationMessagesState({
    this.confirmed = const [],
    this.pending = const [],
    this.conversation,
    this.peerStatus = MessagingPeerStatusDto.unknown,
    this.isLoading = false,
    this.isLoadingOlder = false,
    this.hasOlder = false,
    this.firstUnreadId,
    this.error,
  });

  /// What the list shows: confirmed messages then local pending ones.
  List<UnifiedMessageDto> get messages => [
    ...confirmed,
    for (final item in pending)
      if (!confirmed.any(item.message.sameAs)) item.message,
  ];

  bool get isSending =>
      pending.any((item) => item.message.delivery == MessageDelivery.sending);

  ConversationMessagesState copyWith({
    List<UnifiedMessageDto>? confirmed,
    List<PendingMessage>? pending,
    UnifiedConversationDto? conversation,
    MessagingPeerStatusDto? peerStatus,
    bool? isLoading,
    bool? isLoadingOlder,
    bool? hasOlder,
    int? firstUnreadId,
    Object? error,
    bool clearError = false,
  }) => ConversationMessagesState(
    confirmed: confirmed ?? this.confirmed,
    pending: pending ?? this.pending,
    conversation: conversation ?? this.conversation,
    peerStatus: peerStatus ?? this.peerStatus,
    isLoading: isLoading ?? this.isLoading,
    isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
    hasOlder: hasOlder ?? this.hasOlder,
    firstUnreadId: firstUnreadId ?? this.firstUnreadId,
    error: clearError ? null : (error ?? this.error),
  );
}

class ConversationMessagesNotifier
    extends StateNotifier<ConversationMessagesState> {
  ConversationMessagesNotifier(
    MessagingBridge bridge,
    this.conversationId, {
    MessagingCapabilitiesDto Function()? capabilities,
    bool visible = true,
    MessagingOutbox? outbox,
  }) : _bridge = bridge is MessagingBridgeNative
           ? MessagingBridgeNative(scope: 'conversation:$conversationId')
           : bridge,
       _visible = visible,
       _ownsOutbox = outbox == null,
       _outbox = outbox ?? MessagingOutbox(bridge: () => bridge),
       _capabilities = capabilities ?? (() => MessagingCapabilitiesDto.none),
       super(const ConversationMessagesState(isLoading: true)) {
    _signals = _bridge.eventsStream.listen((signal) {
      if (signal == 'messages:$conversationId' || signal == 'messages') {
        load();
      } else if (signal == 'status:$conversationId') {
        _loadStatus();
      } else if (signal == 'conversations' || signal == 'capabilities') {
        _loadConversation();
      }
    });
    _outboxEvents = _outbox.events.listen(_onOutbox);
    _syncPending();
    _open();
  }

  static const typingRefresh = Duration(seconds: 3);
  static const typingIdle = Duration(seconds: 5);
  static const draftDelay = Duration(milliseconds: 800);

  bool _visible;
  bool _opened = false;
  void setVisible(bool visible) {
    if (_visible == visible) return;
    _visible = visible;
    if (visible && _opened) unawaited(_markRead());
  }

  final MessagingBridge _bridge;
  final int conversationId;
  final MessagingCapabilitiesDto Function() _capabilities;
  late final StreamSubscription<String> _signals;
  late final StreamSubscription<OutboxEvent> _outboxEvents;
  final MessagingOutbox _outbox;
  final bool _ownsOutbox;
  int _loadRevision = 0;
  DateTime? _typingSentAt;
  Timer? _typingStop;
  Timer? _draftTimer;
  String? _draftPending;

  bool allows(MessagingFeature feature) {
    final conversation = state.conversation;
    return conversation != null &&
        messagingAllows(_capabilities(), conversation, feature);
  }

  Future<void> _open() async {
    await _loadConversation();
    final unread = state.conversation?.unreadCount ?? 0;
    await load();
    if (!mounted) return;
    // The unread count covers received messages only: walk back over them.
    var remaining = unread;
    UnifiedMessageDto? first;
    for (final item in state.confirmed.reversed) {
      if (remaining == 0) break;
      if (item.isMine || item.isSystem) continue;
      first = item;
      remaining--;
    }
    if (first != null && remaining == 0) {
      state = state.copyWith(firstUnreadId: first.id);
    }
    _opened = true;
    unawaited(_markRead());
    unawaited(_loadStatus());
  }

  Future<void> _markRead() async {
    if (!_visible || !_opened || state.isLoading || state.error != null) return;
    try {
      await _bridge.markConversationRead(conversationId);
    } on Object {
      // Read state is retried at the next opening.
    }
  }

  Future<void> _loadConversation() async {
    try {
      final conversation = await _bridge.openConversation(conversationId);
      if (mounted) state = state.copyWith(conversation: conversation);
    } on Object {
      // The screen keeps the conversation it was opened with.
    }
  }

  Future<void> _loadStatus() async {
    try {
      final status = await _bridge.loadPeerStatus(conversationId);
      if (mounted) state = state.copyWith(peerStatus: status);
    } on Object {
      if (mounted) {
        state = state.copyWith(peerStatus: MessagingPeerStatusDto.unknown);
      }
    }
  }

  /// Oldest first by the native `seq` (server id, unsent after); stable for ties.
  static List<UnifiedMessageDto> _bySeq(List<UnifiedMessageDto> items) {
    const end = 1 << 62;
    final indexed = items.asMap().entries.toList()
      ..sort((a, b) {
        final byOrder = (a.value.seq ?? end).compareTo(b.value.seq ?? end);
        return byOrder != 0 ? byOrder : a.key.compareTo(b.key);
      });
    return [for (final entry in indexed) entry.value];
  }

  /// Latest page; older messages already loaded are kept above it.
  Future<void> load() async {
    final revision = ++_loadRevision;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final latest = await _bridge.loadMessages(conversationId);
      if (!mounted || revision != _loadRevision) return;
      // Older pages loaded above the latest page: the items placed before the
      // first one still in the latest page. The native order is the truth;
      // createdAt is rewritten each time a row is saved, so it never decides.
      final anchor = latest.isEmpty
          ? -1
          : state.confirmed.indexWhere(latest.first.sameAs);
      final older = latest.isEmpty
          ? const <UnifiedMessageDto>[]
          : [
              for (final item in state.confirmed.take(anchor < 0 ? 0 : anchor))
                if (!latest.any(item.sameAs)) item,
            ];
      // Opening marks read; later arrivals are read while on screen.
      final hadIncoming = latest.any(
        (item) => !item.isMine && !state.confirmed.any(item.sameAs),
      );
      debugPrint(
        '[w.chat] load conv=$conversationId rev=$revision '
        'avant=[${state.confirmed.map((m) => m.id).join(',')}] '
        'recu=[${latest.map((m) => '${m.id}:${m.delivery.name}:${m.createdAt.toIso8601String()}').join(',')}] '
        'gardes=[${older.map((m) => m.id).join(',')}]',
      );
      state = state.copyWith(
        // A page that momentarily omits a message already shown (state change
        // sending -> sent) must not make it vanish: messages are never removed.
        confirmed: _bySeq([
          ...older,
          ...latest,
          for (final item in state.confirmed)
            if (!latest.any(item.sameAs) && !older.contains(item)) item,
        ]),
        pending: [
          for (final item in state.pending)
            if (!latest.any(item.message.sameAs)) item,
        ],
        isLoading: false,
        hasOlder: _bridge is MessagingPaginationBridge
            ? (_bridge as MessagingPaginationBridge).hasMoreMessages(
                conversationId,
              )
            : state.confirmed.isEmpty
            ? latest.length >= 20
            : state.hasOlder,
      );
      if (hadIncoming) unawaited(_markRead());
    } catch (error) {
      if (!mounted || revision != _loadRevision) return;
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> loadOlder() async {
    if (state.isLoadingOlder || !state.hasOlder) return;
    state = state.copyWith(isLoadingOlder: true);
    try {
      final older = await _bridge.loadMoreMessages(conversationId);
      if (!mounted) return;
      state = state.copyWith(
        confirmed: _bySeq([
          for (final item in older)
            if (!state.confirmed.any(item.sameAs)) item,
          ...state.confirmed,
        ]),
        isLoadingOlder: false,
        hasOlder: _bridge is MessagingPaginationBridge
            ? (_bridge as MessagingPaginationBridge).hasMoreMessages(
                conversationId,
              )
            : older.isNotEmpty,
      );
    } on Object {
      if (mounted) state = state.copyWith(isLoadingOlder: false);
    }
  }

  void _onOutbox(OutboxEvent event) {
    if (!mounted || event.conversationId != conversationId) return;
    if (event is OutboxDelivered) {
      final sent = event.message;
      debugPrint('[w.time] UI: message ${sent.id} delivery=${sent.delivery} affiché');
      debugPrint(
        '[w.chat] delivered conv=$conversationId id=${sent.id} '
        'confirme=[${state.confirmed.map((m) => m.id).join(',')}]',
      );
      state = state.copyWith(
        confirmed: _bySeq([
          for (final item in state.confirmed)
            if (!item.sameAs(sent)) item,
          sent,
        ]),
      );
    }
    _syncPending();
  }

  /// The bubbles of what is written here and not confirmed, from the outbox.
  void _syncPending() {
    state = state.copyWith(
      pending: [
        for (final item in _outbox.itemsFor(conversationId))
          PendingMessage(
            message: item.toMessage(conversationId),
            text: item.text,
            attachmentIds: [for (final a in item.attachments) a.id],
            replyToId: item.replyToId,
          ),
      ],
    );
  }

  /// The bubble shows at once; the outbox sends it, and when the network is
  /// missing keeps it (`queued`) and sends it by itself, in order.
  Future<bool> send(
    String text, {
    List<MessageAttachmentDto> attachments = const [],
    UnifiedMessageDto? replyTo,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty && attachments.isEmpty) return false;
    debugPrint('[w.time] provider.send: texte validé, longueur=${clean.length}');
    _stopTyping();
    _draftTimer?.cancel();
    _draftPending = null;
    try {
      return await _outbox.enqueue(
        conversationId: conversationId,
        text: clean,
        attachments: attachments,
        replyToId: replyTo?.id,
        replyTo: replyTo == null
            ? null
            : MessageQuoteDto(
                id: replyTo.id,
                senderLabel: replyTo.isMine ? 'Vous' : replyTo.senderLabel,
                preview: messagePreview(replyTo),
                type: replyTo.attachments.firstOrNull?.type,
              ),
      );
    } catch (error) {
      if (mounted) state = state.copyWith(error: error);
      return false;
    }
  }

  /// Same client id: the bridge never stores it twice.
  Future<bool> retry(UnifiedMessageDto message) async {
    return _outbox.retry(message.id, conversationId: message.conversationId);
  }

  void discardFailed(UnifiedMessageDto message) {
    unawaited(
      _outbox.discard(message.id, conversationId: message.conversationId),
    );
  }

  void _replace(UnifiedMessageDto message) {
    state = state.copyWith(
      confirmed: [
        for (final item in state.confirmed)
          item.id == message.id ? message : item,
      ],
    );
  }

  Future<void> edit(UnifiedMessageDto message, String text) async {
    _replace(
      await _bridge.editMessage(
        conversationId: conversationId,
        messageId: message.id,
        text: text,
      ),
    );
  }

  Future<void> delete(
    UnifiedMessageDto message, {
    required bool forEveryone,
  }) async {
    await _bridge.deleteMessage(
      conversationId: conversationId,
      messageId: message.id,
      forEveryone: forEveryone,
    );
    if (!mounted) return;
    if (forEveryone) {
      _replace(
        message.copyWith(
          content: '',
          isDeleted: true,
          attachments: const [],
          reactions: const [],
        ),
      );
    } else {
      state = state.copyWith(
        confirmed: [
          for (final item in state.confirmed)
            if (item.id != message.id) item,
        ],
      );
    }
  }

  /// Tapping my current reaction removes it.
  Future<void> react(UnifiedMessageDto message, String key) async {
    final mine = message.reactions
        .where((item) => item.isMine)
        .firstOrNull
        ?.key;
    _replace(
      await _bridge.reactToMessage(
        conversationId: conversationId,
        messageId: message.id,
        key: mine == key ? null : key,
      ),
    );
  }

  /// Answers a service card (accept, decline…); the bridge returns the
  /// message with its new status.
  Future<void> performCardAction(
    UnifiedMessageDto message,
    String actionId,
  ) async {
    final bridge = _bridge;
    if (bridge is! MessagingCardBridge) {
      throw PlatformException(code: 'MESSAGING_FEATURE_DISABLED');
    }
    final updated = await (bridge as MessagingCardBridge).performCardAction(
      conversationId: conversationId,
      messageId: message.id,
      actionId: actionId,
    );
    if (mounted) _replace(updated);
  }

  MessagingInteractiveBridge get _interactive {
    final bridge = _bridge;
    if (bridge is! MessagingInteractiveBridge) {
      throw PlatformException(code: 'MESSAGING_FEATURE_DISABLED');
    }
    return bridge as MessagingInteractiveBridge;
  }

  void _accept(UnifiedMessageDto sent) {
    if (!mounted) return;
    state = state.copyWith(
      confirmed: [
        for (final item in state.confirmed)
          if (!item.sameAs(sent)) item,
        sent,
      ],
    );
  }

  /// v5: a poll (question, 2 to 4 options).
  Future<bool> sendPoll(String question, List<String> options) async {
    try {
      _accept(
        await _interactive.sendPoll(
          conversationId: conversationId,
          question: question,
          options: options,
          clientMessageId: DateTime.now().microsecondsSinceEpoch,
        ),
      );
      return true;
    } catch (error) {
      if (mounted) state = state.copyWith(error: error);
      return false;
    }
  }

  /// v5: a vote is final; the bridge returns the poll with its results.
  Future<void> votePoll(UnifiedMessageDto message, int option) async {
    final updated = await _interactive.votePoll(
      conversationId: conversationId,
      messageId: message.id,
      option: option,
    );
    if (mounted) _replace(updated);
  }

  /// v5: a Buzz, its text as description and its prepared media.
  Future<bool> sendPost(
    String text, {
    List<MessageAttachmentDto> attachments = const [],
  }) async {
    if (text.trim().isEmpty && attachments.isEmpty) return false;
    _stopTyping();
    try {
      _accept(
        await _interactive.sendPost(
          conversationId: conversationId,
          text: text.trim(),
          attachmentIds: [for (final item in attachments) item.id],
          clientMessageId: DateTime.now().microsecondsSinceEpoch,
        ),
      );
      return true;
    } catch (error) {
      if (mounted) state = state.copyWith(error: error);
      return false;
    }
  }

  /// v5: the public space of a Buzz, created at its first opening.
  Future<UnifiedConversationDto> openPostSpace(UnifiedMessageDto message) =>
      _interactive.openPostSpace(
        conversationId: conversationId,
        messageId: message.id,
      );

  Future<void> forward(UnifiedMessageDto message, List<int> targets) =>
      _bridge.forwardMessage(
        conversationId: conversationId,
        messageId: message.id,
        targetConversationIds: targets,
      );

  Future<List<UnifiedMessageDto>> search(String query) =>
      _bridge.searchMessages(conversationId, query);

  Future<void> report(String reason, {UnifiedMessageDto? message}) =>
      _bridge.reportConversation(
        conversationId: conversationId,
        reason: reason,
        messageId: message?.id,
      );

  Future<void> _updateConversation(
    Future<UnifiedConversationDto> change,
  ) async {
    final updated = await change;
    if (mounted) state = state.copyWith(conversation: updated);
  }

  Future<void> setMuted(bool value) =>
      _updateConversation(_bridge.setMuted(conversationId, value));

  Future<void> setArchived(bool value) =>
      _updateConversation(_bridge.setArchived(conversationId, value));

  Future<void> setPinned(bool value) =>
      _updateConversation(_bridge.setPinned(conversationId, value));

  Future<void> setBlocked(bool value) =>
      _updateConversation(_bridge.setBlocked(conversationId, value));

  /// Composer changes: throttled typing signal and a delayed draft save.
  void composerChanged(String text) {
    if (allows(MessagingFeature.typing)) {
      if (text.trim().isEmpty) {
        _stopTyping();
      } else {
        final now = DateTime.now();
        if (_typingSentAt == null ||
            now.difference(_typingSentAt!) >= typingRefresh) {
          _typingSentAt = now;
          unawaited(_safe(_bridge.setTyping(conversationId, true)));
        }
        _typingStop?.cancel();
        _typingStop = Timer(typingIdle, _stopTyping);
      }
    }
    if (allows(MessagingFeature.drafts)) {
      _draftPending = text;
      _draftTimer?.cancel();
      _draftTimer = Timer(draftDelay, _flushDraft);
    }
  }

  void _stopTyping() {
    _typingStop?.cancel();
    if (_typingSentAt == null) return;
    _typingSentAt = null;
    unawaited(_safe(_bridge.setTyping(conversationId, false)));
  }

  void _flushDraft() {
    final draft = _draftPending;
    _draftPending = null;
    if (draft == null) return;
    unawaited(_safe(_bridge.saveDraft(conversationId, draft)));
  }

  static Future<void> _safe(Future<void> call) async {
    try {
      await call;
    } on Object {
      // Typing and drafts are best effort.
    }
  }

  @override
  void dispose() {
    _signals.cancel();
    _outboxEvents.cancel();
    if (_ownsOutbox) _outbox.dispose();
    _draftTimer?.cancel();
    _flushDraft();
    _stopTyping();
    super.dispose();
  }
}

/// One-line text of a message for quotes and previews.
String messagePreview(UnifiedMessageDto message) {
  if (message.isDeleted) return 'Message supprimé';
  if (message.content.isNotEmpty) return message.content;
  final attachment = message.attachments.firstOrNull;
  return switch (attachment?.type) {
    'image' => 'Photo',
    'video' => 'Vidéo',
    'voice' => 'Message vocal',
    'audio' => 'Audio',
    'location' => 'Position',
    'document' => attachment!.label,
    _ => 'Message',
  };
}

final conversationMessagesProvider = StateNotifierProvider.autoDispose
    .family<ConversationMessagesNotifier, ConversationMessagesState, int>((
      ref,
      id,
    ) {
      return ConversationMessagesNotifier(
        ref.watch(messagingBridgeProvider),
        id,
        visible: false,
        outbox: ref.watch(messagingOutboxProvider),
        capabilities: () =>
            ref.read(messagingCapabilitiesProvider).value ??
            MessagingCapabilitiesDto.none,
      );
    });

/// Unread messages of the whole inbox (`getUnreadCount`, independent of any
/// filter): the badge of the Messages tab. It follows the bridge's signals,
/// so it changes the moment a message arrives or a conversation is read.
final messagingUnreadTotalProvider = StreamProvider<int>((ref) async* {
  final bridge = ref.watch(messagingBridgeProvider);
  Future<int> read() async {
    try {
      return await bridge.getUnreadCount();
    } catch (_) {
      return 0;
    }
  }

  yield await read();
  await for (final signal in bridge.eventsStream.handleError((Object _) {})) {
    if (signal == 'conversations' ||
        signal == 'unread' ||
        signal.startsWith('messages:')) {
      yield await read();
    }
  }
});

/// Unread messages of the conversation about a service object (a ride, a
/// booking, a ticket): what the service shows on its own row. It follows the
/// bridge's signals, so the badge changes the moment a message arrives.
final subjectUnreadProvider = StreamProvider.autoDispose
    .family<int, MessagingSubjectDto>((ref, subject) async* {
      final bridge = ref.watch(messagingBridgeProvider);
      Future<int> read() async {
        if (bridge is! MessagingSubjectBridge) return 0;
        try {
          return await (bridge as MessagingSubjectBridge).getUnreadForSubject(
            subject,
          );
        } catch (_) {
          return 0;
        }
      }

      yield await read();
      final id = subject.reference;
      await for (final signal in bridge.eventsStream) {
        if (signal == 'conversations' ||
            signal == 'unread' ||
            signal == 'messages:$id') {
          yield await read();
        }
      }
    });
