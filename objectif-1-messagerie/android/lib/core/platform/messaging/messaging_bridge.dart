import 'messaging_models.dart';

class ConversationQuery {
  final MessagingService? service;
  final ConversationKind? kind;
  final String? search;
  final bool archived;

  /// Only conversations with unread messages or marked unread.
  final bool unreadOnly;

  const ConversationQuery({
    this.service,
    this.kind,
    this.search,
    this.archived = false,
    this.unreadOnly = false,
  });
}

/// Available inbox data when one owner is temporarily unreachable.
/// The caller must keep the error visible: this is not a complete snapshot.
class MessagingPartialFailure implements Exception {
  const MessagingPartialFailure({
    required this.cause,
    this.conversations,
    this.unreadCount,
  });
  final Object cause;
  final List<UnifiedConversationDto>? conversations;
  final int? unreadCount;
}

abstract interface class MessagingPaginationBridge {
  bool get hasMoreConversations;
  bool hasMoreMessages(int conversationId);
}

/// Contract `com.wouanda/messaging`.
abstract class MessagingBridge {
  Stream<String> get eventsStream;

  Future<List<UnifiedConversationDto>> loadConversations(
    ConversationQuery query,
  );
  Future<List<UnifiedConversationDto>> loadMoreConversations();
  Future<List<UnifiedMessageDto>> loadMessages(int conversationId);
  Future<List<UnifiedMessageDto>> loadMoreMessages(int conversationId);
  Future<MessageAttachmentDto> prepareAttachment({
    required int conversationId,
    required String sourceUri,
    required String type,
    required String label,
    String? mimeType,
    int? sizeBytes,
    int? durationMs,
    List<double> waveform = const [],
  });
  Future<void> discardAttachment(int conversationId, int attachmentId);

  /// [clientMessageId] makes the send idempotent: a retry after a lost
  /// answer returns the same message, never a duplicate.
  Future<UnifiedMessageDto> sendMessage({
    required int conversationId,
    required String text,
    int? clientMessageId,
    int? replyToId,
    List<int> attachmentIds = const [],
  });
  Future<void> markConversationRead(int conversationId);
  Future<UnifiedConversationDto> setMuted(int conversationId, bool muted);
  Future<UnifiedConversationDto> setArchived(int conversationId, bool archived);
  Future<int> getUnreadCount();
  Future<List<MessagingRecipientDto>> searchRecipients(String query);
  Future<UnifiedConversationDto> openDirectConversation(int recipientId);
  Future<UnifiedConversationDto> openConversation(int conversationId);

  /// A service reference or navigation key; Kotlin returns the integer identity.
  Future<UnifiedConversationDto> resolveConversation(String reference);
  // ─── v2: capabilities and message actions ─────────────────────────────

  /// Global switches; a feature shows only if also in `Conversation.features`.
  Future<MessagingCapabilitiesDto> getCapabilities();
  Future<UnifiedMessageDto> editMessage({
    required int conversationId,
    required int messageId,
    required String text,
  });
  Future<void> deleteMessage({
    required int conversationId,
    required int messageId,
    required bool forEveryone,
  });

  /// [key] null removes my reaction.
  Future<UnifiedMessageDto> reactToMessage({
    required int conversationId,
    required int messageId,
    String? key,
  });
  Future<void> forwardMessage({
    required int conversationId,
    required int messageId,
    required List<int> targetConversationIds,
  });
  Future<UnifiedConversationDto> setPinned(int conversationId, bool pinned);
  Future<UnifiedConversationDto> markConversationUnread(int conversationId);
  Future<void> saveDraft(int conversationId, String text);
  Future<MessagingPeerStatusDto> loadPeerStatus(int conversationId);
  Future<void> setTyping(int conversationId, bool typing);
  Future<UnifiedConversationDto> setBlocked(int conversationId, bool blocked);
  Future<void> reportConversation({
    required int conversationId,
    required String reason,
    int? messageId,
  });
  Future<List<UnifiedMessageDto>> searchMessages(
    int conversationId,
    String query,
  );

  // ─── Calls ─────────────────────────────────────────────────────────────
  Future<MessagingCallSessionDto> startCall(
    int conversationId,
    MessagingCallKind kind,
  );
  Future<MessagingCallSessionDto?> loadActiveCall();

  /// The incoming call rings until accepted or declined.
  Future<MessagingCallSessionDto> acceptCall(int callId);
  Future<MessagingCallSessionDto> declineCall(int callId);
  Future<MessagingCallSessionDto> endCall(int callId);
  Future<MessagingCallSessionDto> setCallMuted(int callId, bool muted);
  Future<MessagingCallSessionDto> setCallCameraEnabled(
    int callId,
    bool enabled,
  );
  Future<MessagingCallSessionDto> setCallSpeakerEnabled(
    int callId,
    bool enabled,
  );
}

/// Optional capability (contract v3): messages that carry a service object.
/// A bridge without it shares nothing as a card; callers check
/// `bridge is MessagingCardBridge` and the `cards` feature.
abstract interface class MessagingCardBridge {
  /// Shares a service object in [conversationId]; the bridge resolves the card
  /// and the actions each side may take.
  Future<UnifiedMessageDto> sendCard({
    required int conversationId,
    required MessageCardDraft draft,
    int? clientMessageId,
  });

  /// Answers a card (accept, decline…); the bridge returns the message with
  /// its new status and the actions left.
  Future<UnifiedMessageDto> performCardAction({
    required int conversationId,
    required int messageId,
    required String actionId,
  });
}

/// Optional capability (contract v5): polls and « Buzz » messages.
/// Callers check `bridge is MessagingInteractiveBridge` and the `poll` /
/// `post` features of the conversation.
abstract interface class MessagingInteractiveBridge {
  /// Sends a poll: [question] and 2 to 4 [options].
  Future<UnifiedMessageDto> sendPoll({
    required int conversationId,
    required String question,
    required List<String> options,
    int? clientMessageId,
  });

  /// Votes for the option at index [option]; a vote is final, the bridge
  /// returns the message with the results.
  Future<UnifiedMessageDto> votePoll({
    required int conversationId,
    required int messageId,
    required int option,
  });

  /// Sends a Buzz: [text] is its description, [attachmentIds] its media.
  Future<UnifiedMessageDto> sendPost({
    required int conversationId,
    required String text,
    List<int> attachmentIds = const [],
    int? clientMessageId,
  });

  /// Opens the public space of a Buzz (created on first opening): a
  /// conversation everyone may read and comment, outside the inbox.
  Future<UnifiedConversationDto> openPostSpace({
    required int conversationId,
    required int messageId,
  });
}

/// Optional capability (contract v3.1): unread messages per kind of
/// conversation, so « Groupes » says it has news while « Privées » is shown.
abstract interface class MessagingUnreadByKindBridge {
  Future<Map<ConversationKind, int>> getUnreadCountsByKind();
}

/// Optional capability (contract v4): conversations anchored on a service
/// object. Opening one is `resolveConversation(subject.reference)`; this
/// adds the lightweight read a service needs for the badge on its own row.
abstract interface class MessagingSubjectBridge {
  /// Unread messages of the conversation about [subject]; 0 when none exists.
  Future<int> getUnreadForSubject(MessagingSubjectDto subject);
}

/// Development side of contract v4: the owning authority tells the messaging
/// what happened. In production the owner writes into the conversation
/// itself (Kotlin → TModeler); this is the same call for the mock authorities.
abstract interface class MessagingServiceEventSink {
  /// Posts [draft] in the conversation of its subject (created from its
  /// seed when new); idempotent by `draft.eventId`.
  Future<UnifiedMessageDto> postServiceEvent(ServiceEventDraft draft);
}
