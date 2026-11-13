import 'dart:async';
import 'package:flutter/services.dart';
import 'messaging_bridge.dart';
import 'messaging_models.dart';

/// A single public inbox, with each service retaining its authority.
class RoutedMessagingBridge
    implements
        MessagingBridge,
        MessagingCardBridge,
        MessagingInteractiveBridge,
        MessagingUnreadByKindBridge,
        MessagingSubjectBridge,
        MessagingServiceEventSink {
  RoutedMessagingBridge(this.general, this.mobility) {
    _subscriptions.add(
      general.eventsStream.listen(_signals.add, onError: _signals.addError),
    );
    _subscriptions.add(
      mobility.eventsStream.listen(_signals.add, onError: _signals.addError),
    );
  }
  final MessagingBridge general;
  final MessagingBridge mobility;
  final _signals = StreamController<String>.broadcast();
  final _subscriptions = <StreamSubscription<String>>[];
  final _mobilityIds = <int>{};
  bool owns(Object id) =>
      id is String ? id.startsWith('go-trip-') : _mobilityIds.contains(id);
  MessagingBridge route(Object? id) =>
      id != null && owns(id) ? mobility : general;
  @override
  Stream<String> get eventsStream => _signals.stream;

  MessagingCardBridge _cards(int conversationId) {
    final owner = route(conversationId);
    if (owner is! MessagingCardBridge) {
      throw PlatformException(code: 'MESSAGING_FEATURE_DISABLED');
    }
    return owner as MessagingCardBridge;
  }

  MessagingInteractiveBridge _interactive(int conversationId) {
    final owner = route(conversationId);
    if (owner is! MessagingInteractiveBridge) {
      throw PlatformException(code: 'MESSAGING_FEATURE_DISABLED');
    }
    return owner as MessagingInteractiveBridge;
  }

  @override
  Future<UnifiedMessageDto> sendPoll({
    required int conversationId,
    required String question,
    required List<String> options,
    int? clientMessageId,
  }) => _interactive(conversationId).sendPoll(
    conversationId: conversationId,
    question: question,
    options: options,
    clientMessageId: clientMessageId,
  );

  @override
  Future<UnifiedMessageDto> votePoll({
    required int conversationId,
    required int messageId,
    required int option,
  }) => _interactive(conversationId).votePoll(
    conversationId: conversationId,
    messageId: messageId,
    option: option,
  );

  @override
  Future<UnifiedMessageDto> sendPost({
    required int conversationId,
    required String text,
    List<int> attachmentIds = const [],
    int? clientMessageId,
  }) => _interactive(conversationId).sendPost(
    conversationId: conversationId,
    text: text,
    attachmentIds: attachmentIds,
    clientMessageId: clientMessageId,
  );

  @override
  Future<UnifiedConversationDto> openPostSpace({
    required int conversationId,
    required int messageId,
  }) => _interactive(
    conversationId,
  ).openPostSpace(conversationId: conversationId, messageId: messageId);

  /// A ride's conversation is the mobility authority's; every other
  /// subject is the general one's (the owners decide, the route is the id).
  @override
  Future<int> getUnreadForSubject(MessagingSubjectDto subject) async {
    final owner = route(subject.reference);
    if (owner is MessagingSubjectBridge) {
      return (owner as MessagingSubjectBridge).getUnreadForSubject(subject);
    }
    try {
      return (await owner.resolveConversation(subject.reference)).unreadCount;
    } on PlatformException {
      return 0;
    }
  }

  @override
  Future<UnifiedMessageDto> postServiceEvent(ServiceEventDraft draft) {
    final owner = route(draft.subject.reference);
    if (owner is! MessagingServiceEventSink) {
      throw PlatformException(code: 'MESSAGING_FEATURE_DISABLED');
    }
    return (owner as MessagingServiceEventSink).postServiceEvent(draft);
  }

  @override
  Future<UnifiedMessageDto> sendCard({
    required int conversationId,
    required MessageCardDraft draft,
    int? clientMessageId,
  }) => _cards(conversationId).sendCard(
    conversationId: conversationId,
    draft: draft,
    clientMessageId: clientMessageId,
  );

  @override
  Future<UnifiedMessageDto> performCardAction({
    required int conversationId,
    required int messageId,
    required String actionId,
  }) => _cards(conversationId).performCardAction(
    conversationId: conversationId,
    messageId: messageId,
    actionId: actionId,
  );
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _signals.close();
  }

  Future<(T?, Object?)> _attempt<T>(Future<T> future) async {
    try {
      return (await future, null);
    } catch (e) {
      return (null, e);
    }
  }

  List<UnifiedConversationDto> _withoutGo(List<UnifiedConversationDto> items) =>
      items
          .where((c) => c.service != MessagingService.go && !owns(c.id))
          .toList();
  @override
  Future<List<UnifiedConversationDto>> loadConversations(
    ConversationQuery query,
  ) async {
    if (query.service == MessagingService.go) {
      final items = await mobility.loadConversations(query);
      _mobilityIds.addAll(items.map((c) => c.id));
      return items;
    }
    if (query.service != null) {
      return _withoutGo(await general.loadConversations(query));
    }
    final pages = await Future.wait([
      _attempt(general.loadConversations(query)),
      _attempt(mobility.loadConversations(query)),
    ]);
    _mobilityIds.addAll(
      (pages[1].$1 ?? const <UnifiedConversationDto>[]).map((c) => c.id),
    );
    final all = [..._withoutGo(pages[0].$1 ?? const []), ...?pages[1].$1];
    all.sort((a, b) {
      final pin = (b.isPinned ? 1 : 0) - (a.isPinned ? 1 : 0);
      return pin != 0
          ? pin
          : (b.lastMessageAt ?? DateTime(1970)).compareTo(
              a.lastMessageAt ?? DateTime(1970),
            );
    });
    final error = pages[0].$2 ?? pages[1].$2;
    if (error != null) {
      throw MessagingPartialFailure(cause: error, conversations: all);
    }
    return all;
  }

  @override
  Future<List<UnifiedConversationDto>> loadMoreConversations() async =>
      _withoutGo(await general.loadMoreConversations());

  /// The general owner by kind; every ride conversation is a private one.
  @override
  Future<Map<ConversationKind, int>> getUnreadCountsByKind() async {
    final owner = general;
    final counts = owner is MessagingUnreadByKindBridge
        ? await (owner as MessagingUnreadByKindBridge).getUnreadCountsByKind()
        : const <ConversationKind, int>{};
    final rides = (await _attempt(mobility.getUnreadCount())).$1 ?? 0;
    return {
      for (final kind in ConversationKind.values)
        kind:
            (counts[kind] ?? 0) + (kind == ConversationKind.direct ? rides : 0),
    };
  }

  @override
  Future<int> getUnreadCount() async {
    final counts = await Future.wait([
      _attempt(general.getUnreadCount()),
      _attempt(mobility.getUnreadCount()),
    ]);
    final count = (counts[0].$1 ?? 0) + (counts[1].$1 ?? 0);
    final error = counts[0].$2 ?? counts[1].$2;
    if (error != null) {
      throw MessagingPartialFailure(cause: error, unreadCount: count);
    }
    return count;
  }

  @override
  Future<MessagingCapabilitiesDto> getCapabilities() async {
    final all = await Future.wait([
      _attempt(general.getCapabilities()),
      _attempt(mobility.getCapabilities()),
    ]);
    if (all.every((value) => value.$1 == null)) {
      throw all[0].$2!;
    }
    final c = all[0].$1 ?? MessagingCapabilitiesDto.none;
    return MessagingCapabilitiesDto(
      features: {...c.features, ...?(all[1].$1?.features)},
      reactions: c.reactions,
      editWindowSeconds: c.editWindowSeconds,
      maxAttachmentBytes: c.maxAttachmentBytes,
      maxTextLength: c.maxTextLength,
    );
  }

  @override
  Future<void> forwardMessage({
    required int conversationId,
    required int messageId,
    required List<int> targetConversationIds,
  }) async {
    if (owns(conversationId) || targetConversationIds.any(owns)) {
      throw PlatformException(code: 'MESSAGING_ACTION_NOT_ALLOWED');
    }
    return general.forwardMessage(
      conversationId: conversationId,
      messageId: messageId,
      targetConversationIds: targetConversationIds,
    );
  }

  @override
  Future<List<UnifiedMessageDto>> loadMessages(int conversationId) =>
      route(conversationId).loadMessages(conversationId);
  @override
  Future<List<UnifiedMessageDto>> loadMoreMessages(int conversationId) =>
      route(conversationId).loadMoreMessages(conversationId);
  @override
  Future<MessageAttachmentDto> prepareAttachment({
    required int conversationId,
    required String sourceUri,
    required String type,
    required String label,
    String? mimeType,
    int? sizeBytes,
    int? durationMs,
    List<double> waveform = const [],
  }) => route(conversationId).prepareAttachment(
    conversationId: conversationId,
    sourceUri: sourceUri,
    type: type,
    label: label,
    mimeType: mimeType,
    sizeBytes: sizeBytes,
    durationMs: durationMs,
    waveform: waveform,
  );
  @override
  Future<void> discardAttachment(int conversationId, int attachmentId) =>
      route(conversationId).discardAttachment(conversationId, attachmentId);
  @override
  Future<UnifiedMessageDto> sendMessage({
    required int conversationId,
    required String text,
    int? clientMessageId,
    int? replyToId,
    List<int> attachmentIds = const [],
  }) => route(conversationId).sendMessage(
    conversationId: conversationId,
    text: text,
    clientMessageId: clientMessageId,
    replyToId: replyToId,
    attachmentIds: attachmentIds,
  );
  @override
  Future<void> markConversationRead(int conversationId) =>
      route(conversationId).markConversationRead(conversationId);
  @override
  Future<UnifiedConversationDto> setMuted(int conversationId, bool muted) =>
      route(conversationId).setMuted(conversationId, muted);
  @override
  Future<UnifiedConversationDto> setArchived(
    int conversationId,
    bool archived,
  ) => route(conversationId).setArchived(conversationId, archived);
  @override
  Future<List<MessagingRecipientDto>> searchRecipients(String query) =>
      route(null).searchRecipients(query);
  @override
  Future<UnifiedConversationDto> openDirectConversation(int recipientId) =>
      route(null).openDirectConversation(recipientId);
  @override
  Future<UnifiedConversationDto> openConversation(int conversationId) async {
    if (owns(conversationId)) return mobility.openConversation(conversationId);
    try {
      return await general.openConversation(conversationId);
    } on PlatformException catch (error) {
      if (error.code != 'MESSAGING_CONVERSATION_NOT_FOUND') rethrow;
      final result = await mobility.openConversation(conversationId);
      _mobilityIds.add(result.id);
      return result;
    }
  }

  @override
  Future<UnifiedConversationDto> resolveConversation(String reference) async {
    final result = await route(reference).resolveConversation(reference);
    if (result.service == MessagingService.go) _mobilityIds.add(result.id);
    return result;
  }

  @override
  Future<UnifiedMessageDto> editMessage({
    required int conversationId,
    required int messageId,
    required String text,
  }) => route(conversationId).editMessage(
    conversationId: conversationId,
    messageId: messageId,
    text: text,
  );
  @override
  Future<void> deleteMessage({
    required int conversationId,
    required int messageId,
    required bool forEveryone,
  }) => route(conversationId).deleteMessage(
    conversationId: conversationId,
    messageId: messageId,
    forEveryone: forEveryone,
  );
  @override
  Future<UnifiedMessageDto> reactToMessage({
    required int conversationId,
    required int messageId,
    String? key,
  }) => route(conversationId).reactToMessage(
    conversationId: conversationId,
    messageId: messageId,
    key: key,
  );
  @override
  Future<UnifiedConversationDto> setPinned(int conversationId, bool pinned) =>
      route(conversationId).setPinned(conversationId, pinned);
  @override
  Future<UnifiedConversationDto> markConversationUnread(int conversationId) =>
      route(conversationId).markConversationUnread(conversationId);
  @override
  Future<void> saveDraft(int conversationId, String text) =>
      route(conversationId).saveDraft(conversationId, text);
  @override
  Future<MessagingPeerStatusDto> loadPeerStatus(int conversationId) =>
      route(conversationId).loadPeerStatus(conversationId);
  @override
  Future<void> setTyping(int conversationId, bool typing) =>
      route(conversationId).setTyping(conversationId, typing);
  @override
  Future<UnifiedConversationDto> setBlocked(int conversationId, bool blocked) =>
      route(conversationId).setBlocked(conversationId, blocked);
  @override
  Future<void> reportConversation({
    required int conversationId,
    required String reason,
    int? messageId,
  }) => route(conversationId).reportConversation(
    conversationId: conversationId,
    reason: reason,
    messageId: messageId,
  );
  @override
  Future<List<UnifiedMessageDto>> searchMessages(
    int conversationId,
    String query,
  ) => route(conversationId).searchMessages(conversationId, query);
  @override
  Future<MessagingCallSessionDto> startCall(
    int conversationId,
    MessagingCallKind kind,
  ) => route(conversationId).startCall(conversationId, kind);
  @override
  Future<MessagingCallSessionDto?> loadActiveCall() =>
      route(null).loadActiveCall();
  @override
  Future<MessagingCallSessionDto> acceptCall(int callId) =>
      route(null).acceptCall(callId);
  @override
  Future<MessagingCallSessionDto> declineCall(int callId) =>
      route(null).declineCall(callId);
  @override
  Future<MessagingCallSessionDto> endCall(int callId) =>
      route(null).endCall(callId);
  @override
  Future<MessagingCallSessionDto> setCallMuted(int callId, bool muted) =>
      route(null).setCallMuted(callId, muted);
  @override
  Future<MessagingCallSessionDto> setCallCameraEnabled(
    int callId,
    bool enabled,
  ) => route(null).setCallCameraEnabled(callId, enabled);
  @override
  Future<MessagingCallSessionDto> setCallSpeakerEnabled(
    int callId,
    bool enabled,
  ) => route(null).setCallSpeakerEnabled(callId, enabled);
}
