import 'package:ngoma/core/shared/media_dto.dart';
export 'package:ngoma/core/shared/media_dto.dart';

/// The services the app knew when messaging was written. A service added
/// later is `other` here and carries its own open key
/// (`UnifiedConversationDto.serviceKey`, resolved by the service registry):
/// no change to messaging is needed to add one (contract messaging v4).
enum MessagingService { shop, love, stay, go, events, support, account, other }

/// What a conversation is about, stated by the service that owns it
/// (contract messaging v4): `go / trip / 10001`, `stay / reservation / 88`,
/// `events / ticket / 31`. Kotlin resolves its textual reference to an integer
/// conversation identity; Flutter never derives that identity.
class MessagingSubjectDto {
  final String service;
  final String type;
  final String id;

  const MessagingSubjectDto({
    required this.service,
    required this.type,
    required this.id,
  });

  /// `<service>-<type>-<id>`: an owning-service reference, not a conversation ID.
  String get reference => '$service-$type-$id';

  @override
  bool operator ==(Object other) =>
      other is MessagingSubjectDto &&
      other.service == service &&
      other.type == type &&
      other.id == id;

  @override
  int get hashCode => Object.hash(service, type, id);

  @override
  String toString() => '$service/$type/$id';

  factory MessagingSubjectDto.fromMap(Map<String, dynamic> map) =>
      MessagingSubjectDto(
        service: map['service'] as String? ?? '',
        type: map['type'] as String? ?? '',
        id: '${map['id'] ?? ''}',
      );

  Map<String, Object?> toMap() => {'service': service, 'type': type, 'id': id};
}

/// The living header of a conversation (contract messaging v4): what it is
/// about, where that stands, and where to go. Codes only (protocol §3.1):
/// the status is worded by Flutter, the route is checked against the
/// service registry before it is followed.
class ConversationContextDto {
  final String title;

  /// `scheduled`, `inProgress`, `arrived`, `completed`, `cancelled`,
  /// `pending`, `confirmed`… (unknown: no status shown).
  final String? status;
  final String? route;

  /// What the reader may do from here, as codes (`open`, `track`, `pay`…),
  /// each with the destination the service proposes.
  final List<ConversationContextActionDto> actions;

  const ConversationContextDto({
    required this.title,
    this.status,
    this.route,
    this.actions = const [],
  });

  factory ConversationContextDto.fromMap(Map<String, dynamic> map) =>
      ConversationContextDto(
        title: map['title'] as String? ?? '',
        status: map['status'] as String?,
        route: map['route'] as String?,
        actions: [
          for (final item in map['actions'] as List? ?? const [])
            if (item is Map)
              ConversationContextActionDto.fromMap(
                Map<String, dynamic>.from(item),
              ),
        ],
      );

  Map<String, Object?> toMap() => {
    'title': title,
    'status': status,
    'route': route,
    'actions': actions.map((item) => item.toMap()).toList(),
  };
}

class ConversationContextActionDto {
  final String code;
  final String? route;
  const ConversationContextActionDto({required this.code, this.route});

  factory ConversationContextActionDto.fromMap(Map<String, dynamic> map) =>
      ConversationContextActionDto(
        code: map['code'] as String? ?? '',
        route: map['route'] as String?,
      );

  Map<String, Object?> toMap() => {'code': code, 'route': route};
}

/// Something that happened in a service, told inside its conversation
/// (contract messaging v4): `trip.driverArrived`, `booking.accepted`,
/// `ticket.purchased`. A code and its parameters; the words are Flutter's.
class MessageServiceEventDto {
  final String code;
  final Map<String, Object?> params;
  const MessageServiceEventDto({required this.code, this.params = const {}});

  factory MessageServiceEventDto.fromMap(Map<String, dynamic> map) =>
      MessageServiceEventDto(
        code: map['code'] as String? ?? '',
        params: map['params'] is Map
            ? Map<String, Object?>.from(map['params'] as Map)
            : const {},
      );

  Map<String, Object?> toMap() => {'code': code, 'params': params};
}

/// What a service tells the messaging when something happens (v4). The
/// owning authority posts it; the real bridge resolves participants and
/// rights itself, the [seed] only lets the development bridge draw a
/// conversation it has not seen yet.
class ServiceEventDraft {
  final MessagingSubjectDto subject;
  final String code;
  final Map<String, Object?> params;

  /// Idempotence: the same id never posts twice.
  final String eventId;

  /// The conversation's status, when this event changes it.
  final String? contextStatus;

  /// Locks the conversation (`ended`, `cancelled`…): read only from now on.
  final String? closedReason;
  final ConversationSeed? seed;

  const ServiceEventDraft({
    required this.subject,
    required this.code,
    required this.eventId,
    this.params = const {},
    this.contextStatus,
    this.closedReason,
    this.seed,
  });

  Map<String, Object?> toMap() => {
    'subject': subject.toMap(),
    'code': code,
    'params': params,
    'eventId': eventId,
    'contextStatus': contextStatus,
    'closedReason': closedReason,
    'seed': seed?.toMap(),
  };
}

/// Display hints for a conversation the owner creates (development bridge).
class ConversationSeed {
  final String title;
  final String subtitle;
  final ConversationKind kind;
  final String contextTitle;
  final String? contextRoute;
  final MediaDto? avatar;
  final bool canSend;

  const ConversationSeed({
    required this.title,
    this.subtitle = '',
    this.kind = ConversationKind.direct,
    required this.contextTitle,
    this.contextRoute,
    this.avatar,
    this.canSend = true,
  });

  Map<String, Object?> toMap() => {
    'title': title,
    'subtitle': subtitle,
    'kind': kind.name,
    'contextTitle': contextTitle,
    'contextRoute': contextRoute,
    'avatar': avatar?.toMap(),
    'canSend': canSend,
  };
}

enum ConversationKind { direct, group, channel }

/// `queued` is local only: written, waiting for a connection to leave (the
/// bridge never sends it).
enum MessageDelivery { sending, queued, sent, delivered, read, failed }

enum MessageInputMethod { camera, gallery, document, voice, location }

enum AttachmentUploadState { local, uploading, ready, failed }

enum MessagingCallKind { audio, video }

enum MessagingCallState {
  ringing,
  connecting,
  active,
  reconnecting,
  ended,
  declined,
  missed,
  failed,
}

/// Messaging functions the back-end can switch off (contract v2,
/// « Capacités pilotées par le back-end »).
enum MessagingFeature {
  reply,
  react,
  edit,
  deleteForMe,
  deleteForEveryone,
  forward,
  copy,
  typing,
  presence,
  readReceipts,
  drafts,
  pin,
  markUnread,
  mute,
  archive,
  block,
  report,
  search,
  newConversation,

  /// v3: messages that carry a service object (an article, an event, an
  /// invitation…) as a card with its own actions.
  cards,

  /// v5: polls (question, 2 to 4 options, one final vote each).
  poll,

  /// v5: « Buzz », a rich message opening its own public space (likes,
  /// reactions, comments, media scrolled sideways).
  post,
}

List<T> _enumList<T extends Enum>(Object? raw, List<T> values) => [
  for (final item in raw is List ? raw : const [])
    ?values.where((value) => value.name == item).firstOrNull,
];

/// Global switches; [features] ∩ `Conversation.features` decides what shows.
class MessagingCapabilitiesDto {
  final Set<MessagingFeature> features;
  final List<String> reactions;
  final int? editWindowSeconds;
  final int? maxAttachmentBytes;
  final int? maxTextLength;

  const MessagingCapabilitiesDto({
    this.features = const {},
    this.reactions = const [],
    this.editWindowSeconds,
    this.maxAttachmentBytes,
    this.maxTextLength,
  });

  /// Before the bridge answers: nothing optional is shown.
  static const none = MessagingCapabilitiesDto();

  bool has(MessagingFeature feature) => features.contains(feature);

  factory MessagingCapabilitiesDto.fromMap(Map<String, dynamic> map) =>
      MessagingCapabilitiesDto(
        features: _enumList(map['features'], MessagingFeature.values).toSet(),
        reactions: (map['reactions'] as List? ?? const [])
            .whereType<String>()
            .toList(),
        editWindowSeconds: (map['editWindowSeconds'] as num?)?.toInt(),
        maxAttachmentBytes: (map['maxAttachmentBytes'] as num?)?.toInt(),
        maxTextLength: (map['maxTextLength'] as num?)?.toInt(),
      );

  Map<String, Object?> toMap() => {
    'features': features.map((item) => item.name).toList(),
    'reactions': reactions,
    'editWindowSeconds': editWindowSeconds,
    'maxAttachmentBytes': maxAttachmentBytes,
    'maxTextLength': maxTextLength,
  };
}

/// Presence and typing of the other side, empty when switched off.
class MessagingPeerStatusDto {
  final bool isTyping;
  final String? typingLabel;
  final bool isOnline;
  final DateTime? lastSeenAt;

  const MessagingPeerStatusDto({
    this.isTyping = false,
    this.typingLabel,
    this.isOnline = false,
    this.lastSeenAt,
  });

  static const unknown = MessagingPeerStatusDto();

  factory MessagingPeerStatusDto.fromMap(Map<String, dynamic> map) =>
      MessagingPeerStatusDto(
        isTyping: map['isTyping'] as bool? ?? false,
        typingLabel: map['typingLabel'] as String?,
        isOnline: map['isOnline'] as bool? ?? false,
        lastSeenAt: DateTime.tryParse(map['lastSeenAt'] as String? ?? ''),
      );

  Map<String, Object?> toMap() => {
    'isTyping': isTyping,
    'typingLabel': typingLabel,
    'isOnline': isOnline,
    'lastSeenAt': lastSeenAt?.toUtc().toIso8601String(),
  };
}

/// The quoted message of a reply, resolved by the bridge.
class MessageQuoteDto {
  final int id;
  final String senderLabel;
  final String preview;
  final String? type;

  const MessageQuoteDto({
    required this.id,
    required this.senderLabel,
    required this.preview,
    this.type,
  });

  factory MessageQuoteDto.fromMap(Map<String, dynamic> map) => MessageQuoteDto(
    id: (map['id'] as num).toInt(),
    senderLabel: map['senderLabel'] as String? ?? '',
    preview: map['preview'] as String? ?? '',
    type: map['type'] as String?,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'senderLabel': senderLabel,
    'preview': preview,
    'type': type,
  };
}

/// One reaction key under a message (`like`, `heart`…), never an emoji.
class MessageReactionDto {
  final String key;
  final int count;
  final bool isMine;

  const MessageReactionDto({
    required this.key,
    required this.count,
    this.isMine = false,
  });

  factory MessageReactionDto.fromMap(Map<String, dynamic> map) =>
      MessageReactionDto(
        key: map['key'] as String? ?? '',
        count: (map['count'] as num?)?.toInt() ?? 0,
        isMine: map['isMine'] as bool? ?? false,
      );

  Map<String, Object?> toMap() => {
    'key': key,
    'count': count,
    'isMine': isMine,
  };
}

/// One answer of a poll and how many chose it.
class MessagePollOptionDto {
  final String label;
  final int votes;

  const MessagePollOptionDto({required this.label, this.votes = 0});

  factory MessagePollOptionDto.fromMap(Map<String, dynamic> map) =>
      MessagePollOptionDto(
        label: map['label'] as String? ?? '',
        votes: (map['votes'] as num?)?.toInt() ?? 0,
      );

  Map<String, Object?> toMap() => {'label': label, 'votes': votes};
}

/// A poll message (`type: poll`): the question is the message content.
/// A vote is final; results show once the account has voted.
class MessagePollDto {
  final List<MessagePollOptionDto> options;
  final int total;

  /// Index of the account's option; null while it has not voted.
  final int? myVote;

  const MessagePollDto({required this.options, this.total = 0, this.myVote});

  bool get hasVoted => myVote != null;

  factory MessagePollDto.fromMap(Map<String, dynamic> map) => MessagePollDto(
    options: (map['options'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              MessagePollOptionDto.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList(),
    total: (map['total'] as num?)?.toInt() ?? 0,
    myVote: (map['myVote'] as num?)?.toInt(),
  );

  Map<String, Object?> toMap() => {
    'options': options.map((item) => item.toMap()).toList(),
    'total': total,
    'myVote': myVote,
  };
}

/// A « Buzz » (`type: post`): content is its description, attachments its
/// media; [spaceId] is its public conversation once opened.
class MessagePostDto {
  final int? spaceId;
  final int comments;

  const MessagePostDto({this.spaceId, this.comments = 0});

  factory MessagePostDto.fromMap(Map<String, dynamic> map) => MessagePostDto(
    spaceId: (map['spaceId'] as num?)?.toInt(),
    comments: (map['comments'] as num?)?.toInt() ?? 0,
  );

  Map<String, Object?> toMap() => {'spaceId': spaceId, 'comments': comments};
}

class MessagingRecipientDto {
  final int id;
  final String displayName;
  final String? subtitle;
  final MediaDto? avatar;
  String? get avatarUrl => avatar?.source;

  const MessagingRecipientDto({
    required this.id,
    required this.displayName,
    this.subtitle,
    this.avatar,
  });

  factory MessagingRecipientDto.fromMap(Map<String, dynamic> map) =>
      MessagingRecipientDto(
        id: (map['id'] as num?)?.toInt() ?? 0,
        displayName: map['displayName'] as String? ?? '',
        subtitle: map['subtitle'] as String?,
        avatar: MediaDto.fromMapOrNull(map['avatar']),
      );

  Map<String, Object?> toMap() => {
    'id': id,
    'displayName': displayName,
    'subtitle': subtitle,
    'avatar': avatar?.toMap(),
  };
}

class MessageAttachmentDto {
  final int id;
  final String type;
  final String label;
  final MediaDto? preview;
  String? get previewUrl => preview?.source;
  final MediaDto? media;
  String? get mediaUrl => media?.source;
  final String? mimeType;
  final int? sizeBytes;
  final int? durationMs;
  final int? width;
  final int? height;
  final List<double> waveform;
  final AttachmentUploadState uploadState;
  final double? uploadProgress;

  const MessageAttachmentDto({
    required this.id,
    required this.type,
    required this.label,
    this.preview,
    this.media,
    this.mimeType,
    this.sizeBytes,
    this.durationMs,
    this.width,
    this.height,
    this.waveform = const [],
    this.uploadState = AttachmentUploadState.ready,
    this.uploadProgress,
  });

  factory MessageAttachmentDto.fromMap(Map<String, dynamic> map) =>
      MessageAttachmentDto(
        id: (map['id'] as num).toInt(),
        type: map['type'] as String? ?? 'file',
        label: map['label'] as String? ?? '',
        preview: MediaDto.fromMapOrNull(map['preview']),
        media: MediaDto.fromMapOrNull(map['media']),
        mimeType: map['mimeType'] as String?,
        sizeBytes: (map['sizeBytes'] as num?)?.toInt(),
        durationMs: (map['durationMs'] as num?)?.toInt(),
        width: (map['width'] as num?)?.toInt(),
        height: (map['height'] as num?)?.toInt(),
        waveform: (map['waveform'] as List? ?? const [])
            .whereType<num>()
            .map((value) => value.toDouble().clamp(0, 1).toDouble())
            .toList(),
        uploadState: AttachmentUploadState.values.firstWhere(
          (value) => value.name == map['uploadState'],
          orElse: () => AttachmentUploadState.ready,
        ),
        uploadProgress: (map['uploadProgress'] as num?)?.toDouble(),
      );

  Map<String, Object?> toMap() => {
    'id': id,
    'type': type,
    'label': label,
    'preview': preview?.toMap(),
    'media': media?.toMap(),
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
    'durationMs': durationMs,
    'width': width,
    'height': height,
    'waveform': waveform,
    'uploadState': uploadState.name,
    'uploadProgress': uploadProgress,
  };
}

class UnifiedConversationDto {
  final int id;
  final MessagingService service;

  /// The service's open key (`go`, `stay`, a future `food`…): what names and
  /// tints it through the service registry when [service] is `other`.
  final String serviceKey;
  final MessagingSubjectDto? subject;
  final ConversationContextDto? context;

  /// Why the conversation is read only (`ended`, `cancelled`, `expired`),
  /// when the owner closed it; null: open (or closed for another reason).
  final String? closedReason;
  final ConversationKind kind;
  final int? peerId;
  final String title;
  final String subtitle;
  final MediaDto? avatar;
  String? get avatarUrl => avatar?.source;
  final String? contextLabel;
  final String? contextRoute;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final bool lastMessageIsMine;
  final MessageDelivery? lastMessageDelivery;
  final int unreadCount;
  final bool isMarkedUnread;
  final bool isMuted;
  final bool isArchived;
  final bool isPinned;
  final bool isBlocked;
  final String? draft;
  final bool canSend;
  final List<String> quickReplies;

  /// Values completing the words of [quickReplies] (go v1.17: `landmark`
  /// for `at_landmark`).
  final Map<String, String> quickReplyParams;
  final int? maxTextLength;
  final List<MessageInputMethod> inputMethods;
  final List<MessagingCallKind> callMethods;
  final Set<MessagingFeature> features;

  const UnifiedConversationDto({
    required this.id,
    required this.service,
    String? serviceKey,
    this.subject,
    this.context,
    this.closedReason,
    this.kind = ConversationKind.direct,
    this.peerId,
    required this.title,
    required this.subtitle,
    this.avatar,
    this.contextLabel,
    this.contextRoute,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageIsMine = false,
    this.lastMessageDelivery,
    this.unreadCount = 0,
    this.isMarkedUnread = false,
    this.isMuted = false,
    this.isArchived = false,
    this.isPinned = false,
    this.isBlocked = false,
    this.draft,
    this.canSend = true,
    this.quickReplies = const [],
    this.quickReplyParams = const {},
    this.maxTextLength,
    this.inputMethods = const [
      MessageInputMethod.camera,
      MessageInputMethod.gallery,
      MessageInputMethod.document,
      MessageInputMethod.voice,
    ],
    this.callMethods = const [MessagingCallKind.audio, MessagingCallKind.video],
    this.features = const {},
  }) : serviceKey = serviceKey ?? '';

  /// The service key to look up (the enum name when the bridge gave none).
  String get effectiveServiceKey =>
      serviceKey.isEmpty ? service.name : serviceKey;

  /// Unread for the badge: real count, or the « marked unread » dot.
  bool get isUnread => unreadCount > 0 || isMarkedUnread;

  bool get hasDraft => draft != null && draft!.trim().isNotEmpty;

  factory UnifiedConversationDto.fromMap(Map<String, dynamic> map) =>
      UnifiedConversationDto(
        id: (map['id'] as num).toInt(),
        service: MessagingService.values.firstWhere(
          (value) => value.name == map['service'],
          orElse: () => MessagingService.other,
        ),
        serviceKey: map['service'] as String?,
        subject: map['subject'] is Map
            ? MessagingSubjectDto.fromMap(
                Map<String, dynamic>.from(map['subject'] as Map),
              )
            : null,
        context: map['context'] is Map
            ? ConversationContextDto.fromMap(
                Map<String, dynamic>.from(map['context'] as Map),
              )
            : null,
        closedReason: map['closedReason'] as String?,
        kind: ConversationKind.values.firstWhere(
          (value) => value.name == map['kind'],
          orElse: () => ConversationKind.direct,
        ),
        peerId: (map['peerId'] as num?)?.toInt(),
        title: map['title'] as String? ?? '',
        subtitle: map['subtitle'] as String? ?? '',
        avatar: MediaDto.fromMapOrNull(map['avatar']),
        contextLabel: map['contextLabel'] as String?,
        contextRoute: map['contextRoute'] as String?,
        lastMessage: map['lastMessage'] as String?,
        lastMessageAt: DateTime.tryParse(map['lastMessageAt'] as String? ?? ''),
        lastMessageIsMine: map['lastMessageIsMine'] as bool? ?? false,
        lastMessageDelivery: MessageDelivery.values
            .where((value) => value.name == map['lastMessageDelivery'])
            .firstOrNull,
        unreadCount: (map['unreadCount'] as num?)?.toInt() ?? 0,
        isMarkedUnread: map['isMarkedUnread'] as bool? ?? false,
        isMuted: map['isMuted'] as bool? ?? false,
        isArchived: map['isArchived'] as bool? ?? false,
        isPinned: map['isPinned'] as bool? ?? false,
        isBlocked: map['isBlocked'] as bool? ?? false,
        draft: map['draft'] as String?,
        canSend: map['canSend'] as bool? ?? false,
        quickReplies: List<String>.unmodifiable(
          (map['quickReplies'] as List? ?? const []).whereType<String>(),
        ),
        quickReplyParams: {
          for (final MapEntry(:key, :value)
              in (map['quickReplyParams'] as Map? ?? const {}).entries)
            if (value is String) key.toString(): value,
        },
        maxTextLength: (map['maxTextLength'] as num?)?.toInt(),
        inputMethods: map['inputMethods'] is List
            ? _enumList(map['inputMethods'], MessageInputMethod.values)
            : const [
                MessageInputMethod.camera,
                MessageInputMethod.gallery,
                MessageInputMethod.document,
                MessageInputMethod.voice,
              ],
        callMethods: map['callMethods'] is List
            ? _enumList(map['callMethods'], MessagingCallKind.values)
            : const [MessagingCallKind.audio, MessagingCallKind.video],
        // Absent = switched off: an older bridge shows a reduced UI.
        features: _enumList(map['features'], MessagingFeature.values).toSet(),
      );

  UnifiedConversationDto copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    bool? lastMessageIsMine,
    MessageDelivery? lastMessageDelivery,
    int? unreadCount,
    bool? isMarkedUnread,
    bool? isMuted,
    bool? isArchived,
    bool? isPinned,
    bool? isBlocked,
    String? draft,
    bool clearDraft = false,
    bool? canSend,
    List<MessagingCallKind>? callMethods,
    Set<MessagingFeature>? features,
    ConversationContextDto? context,
    String? closedReason,
  }) => UnifiedConversationDto(
    id: id,
    service: service,
    serviceKey: serviceKey,
    subject: subject,
    context: context ?? this.context,
    closedReason: closedReason ?? this.closedReason,
    kind: kind,
    peerId: peerId,
    title: title,
    subtitle: subtitle,
    avatar: avatar,
    contextLabel: contextLabel,
    contextRoute: contextRoute,
    lastMessage: lastMessage ?? this.lastMessage,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    lastMessageIsMine: lastMessageIsMine ?? this.lastMessageIsMine,
    lastMessageDelivery: lastMessageDelivery ?? this.lastMessageDelivery,
    unreadCount: unreadCount ?? this.unreadCount,
    isMarkedUnread: isMarkedUnread ?? this.isMarkedUnread,
    isMuted: isMuted ?? this.isMuted,
    isArchived: isArchived ?? this.isArchived,
    isPinned: isPinned ?? this.isPinned,
    isBlocked: isBlocked ?? this.isBlocked,
    draft: clearDraft ? null : (draft ?? this.draft),
    canSend: canSend ?? this.canSend,
    quickReplies: quickReplies,
    quickReplyParams: quickReplyParams,
    maxTextLength: maxTextLength,
    inputMethods: inputMethods,
    callMethods: callMethods ?? this.callMethods,
    features: features ?? this.features,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'service': effectiveServiceKey,
    'subject': subject?.toMap(),
    'context': context?.toMap(),
    'closedReason': closedReason,
    'kind': kind.name,
    'peerId': peerId,
    'title': title,
    'subtitle': subtitle,
    'avatar': avatar?.toMap(),
    'contextLabel': contextLabel,
    'contextRoute': contextRoute,
    'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt?.toUtc().toIso8601String(),
    'lastMessageIsMine': lastMessageIsMine,
    'lastMessageDelivery': lastMessageDelivery?.name,
    'unreadCount': unreadCount,
    'isMarkedUnread': isMarkedUnread,
    'isMuted': isMuted,
    'isArchived': isArchived,
    'isPinned': isPinned,
    'isBlocked': isBlocked,
    'draft': draft,
    'canSend': canSend,
    'quickReplies': quickReplies,
    'quickReplyParams': quickReplyParams,
    'maxTextLength': maxTextLength,
    'inputMethods': inputMethods.map((item) => item.name).toList(),
    'callMethods': callMethods.map((item) => item.name).toList(),
    'features': features.map((item) => item.name).toList(),
  };
}

class MessagingCallSessionDto {
  final int id;
  final int conversationId;
  final MessagingCallKind kind;
  final MessagingCallState state;
  final DateTime? startedAt;
  final DateTime? connectedAt;
  final DateTime? endedAt;
  final String? endReason;
  final bool isIncoming;
  final int? initiatorId;
  final List<int> participantIds;
  final bool isMuted;
  final bool isCameraEnabled;
  final bool isSpeakerEnabled;
  final String? localRendererId;
  final List<String> remoteRendererIds;

  const MessagingCallSessionDto({
    required this.id,
    required this.conversationId,
    required this.kind,
    required this.state,
    this.startedAt,
    this.connectedAt,
    this.endedAt,
    this.endReason,
    this.isIncoming = false,
    this.initiatorId,
    this.participantIds = const [],
    this.isMuted = false,
    this.isCameraEnabled = false,
    this.isSpeakerEnabled = false,
    this.localRendererId,
    this.remoteRendererIds = const [],
  });

  factory MessagingCallSessionDto.fromMap(Map<String, dynamic> map) =>
      MessagingCallSessionDto(
        id: (map['id'] as num).toInt(),
        conversationId: (map['conversationId'] as num).toInt(),
        kind: MessagingCallKind.values.firstWhere(
          (value) => value.name == map['kind'],
          orElse: () => MessagingCallKind.audio,
        ),
        state: MessagingCallState.values.firstWhere(
          (value) => value.name == map['state'],
          orElse: () => MessagingCallState.failed,
        ),
        startedAt: DateTime.tryParse(map['startedAt'] as String? ?? ''),
        connectedAt: DateTime.tryParse(map['connectedAt'] as String? ?? ''),
        endedAt: DateTime.tryParse(map['endedAt'] as String? ?? ''),
        endReason: map['endReason'] as String?,
        isIncoming: map['isIncoming'] as bool? ?? false,
        initiatorId: (map['initiatorId'] as num?)?.toInt(),
        participantIds: (map['participantIds'] as List? ?? const [])
            .whereType<num>()
            .map((value) => value.toInt())
            .toList(),
        isMuted: map['isMuted'] as bool? ?? false,
        isCameraEnabled: map['isCameraEnabled'] as bool? ?? false,
        isSpeakerEnabled: map['isSpeakerEnabled'] as bool? ?? false,
        localRendererId: map['localRendererId'] as String?,
        remoteRendererIds: (map['remoteRendererIds'] as List? ?? const [])
            .whereType<String>()
            .toList(),
      );

  MessagingCallSessionDto copyWith({
    MessagingCallState? state,
    DateTime? connectedAt,
    DateTime? endedAt,
    String? endReason,
    bool? isMuted,
    bool? isCameraEnabled,
    bool? isSpeakerEnabled,
  }) => MessagingCallSessionDto(
    id: id,
    conversationId: conversationId,
    kind: kind,
    state: state ?? this.state,
    startedAt: startedAt,
    connectedAt: connectedAt ?? this.connectedAt,
    endedAt: endedAt ?? this.endedAt,
    endReason: endReason ?? this.endReason,
    isIncoming: isIncoming,
    initiatorId: initiatorId,
    participantIds: participantIds,
    isMuted: isMuted ?? this.isMuted,
    isCameraEnabled: isCameraEnabled ?? this.isCameraEnabled,
    isSpeakerEnabled: isSpeakerEnabled ?? this.isSpeakerEnabled,
    localRendererId: localRendererId,
    remoteRendererIds: remoteRendererIds,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'conversationId': conversationId,
    'kind': kind.name,
    'state': state.name,
    'startedAt': startedAt?.toUtc().toIso8601String(),
    'connectedAt': connectedAt?.toUtc().toIso8601String(),
    'endedAt': endedAt?.toUtc().toIso8601String(),
    'endReason': endReason,
    'isIncoming': isIncoming,
    'initiatorId': initiatorId,
    'participantIds': participantIds,
    'isMuted': isMuted,
    'isCameraEnabled': isCameraEnabled,
    'isSpeakerEnabled': isSpeakerEnabled,
    'localRendererId': localRendererId,
    'remoteRendererIds': remoteRendererIds,
  };
}

/// What a service object looks like inside a conversation (v3): an article,
/// a stay, an event, a ride, an invitation, a date, a gift, a payment, a
/// place. The bridge builds it from the service that owns the object and
/// sends codes only (kind, status, actions); the words are Flutter's
/// (protocol §3.1). Flutter never invents a status or an action.
class MessageCardDto {
  /// `product`, `listing`, `event`, `trip`, `booking`, `invitation`,
  /// `dateProposal`, `gift`, `payment`, `location` — or any kind a service
  /// adds later (drawn generically).
  final String kind;
  final String title;
  final String? subtitle;
  final MediaDto? media;

  /// A price, an amount, a date: the one figure that matters.
  final String? value;

  /// `pending`, `accepted`, `declined`, `expired`, `cancelled`, `paid`…
  final String? status;

  /// An internal destination (checked against the app's registry).
  final String? route;
  final List<MessageCardFactDto> facts;

  /// What the reader may do now, as codes (`accept`, `decline`, `cancel`,
  /// `pay`), decided by the bridge: none for the sender of an invitation,
  /// none once answered.
  final List<String> actions;

  const MessageCardDto({
    required this.kind,
    required this.title,
    this.subtitle,
    this.media,
    this.value,
    this.status,
    this.route,
    this.facts = const [],
    this.actions = const [],
  });

  factory MessageCardDto.fromMap(Map<String, dynamic> map) => MessageCardDto(
    kind: map['kind'] as String? ?? 'generic',
    title: map['title'] as String? ?? '',
    subtitle: map['subtitle'] as String?,
    media: MediaDto.fromMapOrNull(map['media']),
    value: map['value'] as String?,
    status: map['status'] as String?,
    route: map['route'] as String?,
    facts: [
      for (final item in map['facts'] as List? ?? const [])
        if (item is Map)
          MessageCardFactDto.fromMap(Map<String, dynamic>.from(item)),
    ],
    actions: [
      for (final item in map['actions'] as List? ?? const [])
        if (item is String) item,
    ],
  );

  MessageCardDto copyWith({String? status, List<String>? actions}) =>
      MessageCardDto(
        kind: kind,
        title: title,
        subtitle: subtitle,
        media: media,
        value: value,
        status: status ?? this.status,
        route: route,
        facts: facts,
        actions: actions ?? this.actions,
      );

  Map<String, Object?> toMap() => {
    'kind': kind,
    'title': title,
    'subtitle': subtitle,
    'media': media?.toMap(),
    'value': value,
    'status': status,
    'route': route,
    'facts': facts.map((item) => item.toMap()).toList(),
    'actions': actions,
  };
}

class MessageCardFactDto {
  final String label;
  final String value;
  const MessageCardFactDto({required this.label, required this.value});

  factory MessageCardFactDto.fromMap(Map<String, dynamic> map) =>
      MessageCardFactDto(
        label: map['label'] as String? ?? '',
        value: map['value'] as String? ?? '',
      );

  Map<String, Object?> toMap() => {'label': label, 'value': value};
}

/// What a service asks to share (v3). The bridge resolves the object from
/// `kind` + `refId` with the owning service; the display hints only let the
/// development bridge draw it, the production bridge uses its own data.
class MessageCardDraft {
  final String kind;
  final String refId;
  final Map<String, Object?> params;
  final String title;
  final String? subtitle;
  final MediaDto? media;
  final String? value;
  final String? route;
  final List<MessageCardFactDto> facts;

  const MessageCardDraft({
    required this.kind,
    required this.refId,
    required this.title,
    this.params = const {},
    this.subtitle,
    this.media,
    this.value,
    this.route,
    this.facts = const [],
  });

  Map<String, Object?> toMap() => {
    'kind': kind,
    'refId': refId,
    'params': params,
    'title': title,
    'subtitle': subtitle,
    'media': media?.toMap(),
    'value': value,
    'route': route,
    'facts': facts.map((item) => item.toMap()).toList(),
  };
}

class UnifiedMessageDto {
  final int id;
  final int? clientMessageId;
  final int conversationId;
  final String content;
  final String type;
  final String senderLabel;
  final bool isMine;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isDeleted;
  final bool isForwarded;
  final MessageDelivery delivery;
  final MediaDto? media;
  String? get mediaUrl => media?.source;
  final int? replyToId;
  final MessageQuoteDto? replyTo;
  final List<MessageReactionDto> reactions;
  final bool canEdit;
  final bool canDeleteForEveryone;
  final List<MessageAttachmentDto> attachments;

  /// Display order from the native side: server id, unsent messages after.
  final int? seq;

  /// v3: the service object this message carries.
  final MessageCardDto? card;

  /// v4: what happened in the service, when this is its message.
  final MessageServiceEventDto? event;

  /// v5: the poll, when `type` is `poll`.
  final MessagePollDto? poll;

  /// v5: the Buzz, when `type` is `post`.
  final MessagePostDto? post;

  const UnifiedMessageDto({
    required this.id,
    this.clientMessageId,
    required this.conversationId,
    required this.content,
    required this.type,
    required this.senderLabel,
    required this.isMine,
    required this.createdAt,
    required this.delivery,
    this.editedAt,
    this.isDeleted = false,
    this.isForwarded = false,
    this.media,
    this.replyToId,
    this.replyTo,
    this.reactions = const [],
    this.canEdit = false,
    this.canDeleteForEveryone = false,
    this.attachments = const [],
    this.seq,
    this.card,
    this.event,
    this.poll,
    this.post,
  });

  bool get isPoll => type == 'poll' && poll != null;
  bool get isPost => type == 'post';

  bool get isSystem => type == 'system';

  /// Same message whether it is the local pending copy or the bridge's.
  bool sameAs(UnifiedMessageDto other) =>
      id == other.id ||
      (clientMessageId != null && clientMessageId == other.clientMessageId);

  factory UnifiedMessageDto.fromMap(
    Map<String, dynamic> map,
  ) => UnifiedMessageDto(
    id: (map['id'] as num).toInt(),
    clientMessageId: (map['clientMessageId'] as num?)?.toInt(),
    conversationId: (map['conversationId'] as num).toInt(),
    content: map['content'] as String? ?? '',
    type: map['type'] as String? ?? 'text',
    senderLabel: map['senderLabel'] as String? ?? '',
    isMine: map['isMine'] as bool? ?? false,
    createdAt:
        DateTime.tryParse(map['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    editedAt: DateTime.tryParse(map['editedAt'] as String? ?? ''),
    isDeleted: map['isDeleted'] as bool? ?? false,
    isForwarded: map['isForwarded'] as bool? ?? false,
    delivery: MessageDelivery.values.firstWhere(
      (value) => value.name == map['delivery'],
      orElse: () => MessageDelivery.sent,
    ),
    media: MediaDto.fromMapOrNull(map['media']),
    replyToId: (map['replyToId'] as num?)?.toInt(),
    replyTo: map['replyTo'] is Map
        ? MessageQuoteDto.fromMap(
            Map<String, dynamic>.from(map['replyTo'] as Map),
          )
        : null,
    reactions: (map['reactions'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => MessageReactionDto.fromMap(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.count > 0)
        .toList(),
    canEdit: map['canEdit'] as bool? ?? false,
    canDeleteForEveryone: map['canDeleteForEveryone'] as bool? ?? false,
    attachments: (map['attachments'] as List? ?? const [])
        .map(
          (item) => MessageAttachmentDto.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(),
    card: map['card'] is Map
        ? MessageCardDto.fromMap(Map<String, dynamic>.from(map['card'] as Map))
        : null,
    seq: (map['seq'] as num?)?.toInt(),
    event: map['event'] is Map
        ? MessageServiceEventDto.fromMap(
            Map<String, dynamic>.from(map['event'] as Map),
          )
        : null,
    poll: map['poll'] is Map
        ? MessagePollDto.fromMap(Map<String, dynamic>.from(map['poll'] as Map))
        : null,
    post: map['post'] is Map
        ? MessagePostDto.fromMap(Map<String, dynamic>.from(map['post'] as Map))
        : null,
  );

  UnifiedMessageDto copyWith({
    String? content,
    DateTime? editedAt,
    bool? isDeleted,
    MessageDelivery? delivery,
    List<MessageReactionDto>? reactions,
    bool? canEdit,
    bool? canDeleteForEveryone,
    List<MessageAttachmentDto>? attachments,
    MessageCardDto? card,
    MessagePollDto? poll,
    MessagePostDto? post,
  }) => UnifiedMessageDto(
    id: id,
    clientMessageId: clientMessageId,
    conversationId: conversationId,
    content: content ?? this.content,
    type: type,
    senderLabel: senderLabel,
    isMine: isMine,
    createdAt: createdAt,
    editedAt: editedAt ?? this.editedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    isForwarded: isForwarded,
    delivery: delivery ?? this.delivery,
    media: media,
    replyToId: replyToId,
    replyTo: replyTo,
    reactions: reactions ?? this.reactions,
    canEdit: canEdit ?? this.canEdit,
    canDeleteForEveryone: canDeleteForEveryone ?? this.canDeleteForEveryone,
    attachments: attachments ?? this.attachments,
    seq: seq,
    card: card ?? this.card,
    event: event,
    poll: poll ?? this.poll,
    post: post ?? this.post,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'clientMessageId': clientMessageId,
    'conversationId': conversationId,
    'content': content,
    'type': type,
    'senderLabel': senderLabel,
    'isMine': isMine,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'editedAt': editedAt?.toUtc().toIso8601String(),
    'isDeleted': isDeleted,
    'isForwarded': isForwarded,
    'delivery': delivery.name,
    'media': media?.toMap(),
    'replyToId': replyToId,
    'replyTo': replyTo?.toMap(),
    'reactions': reactions.map((item) => item.toMap()).toList(),
    'canEdit': canEdit,
    'canDeleteForEveryone': canDeleteForEveryone,
    'attachments': attachments.map((item) => item.toMap()).toList(),
    'seq': seq,
    'card': card?.toMap(),
    'event': event?.toMap(),
    'poll': poll?.toMap(),
    'post': post?.toMap(),
  };
}
