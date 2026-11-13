import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'messaging_bridge.dart';
import 'messaging_models.dart';
import 'package:ngoma/core/platform/wouanda_error_code.dart';

class MessagingBridgeMock
    implements
        MessagingBridge,
        MessagingCardBridge,
        MessagingInteractiveBridge,
        MessagingUnreadByKindBridge,
        MessagingSubjectBridge,
        MessagingServiceEventSink {
  MessagingBridgeMock({
    DateTime Function()? clock,
    Set<MessagingFeature> disabledFeatures = const {},
    this.simulatePeers = false,
    this.accountKey,
    this.externalGo = false,
  }) : _clock = clock ?? DateTime.now,
       _disabled = {...disabledFeatures};

  final String? accountKey;
  final bool externalGo;
  String get _key => accountKey == null
      ? 'messaging_bridge_mock_v3'
      : 'messaging_bridge_mock_v3:$accountKey';
  static const pageSize = 20;
  static const editWindow = Duration(minutes: 15);
  static const deleteForEveryoneWindow = Duration(hours: 48);
  static const reactionKeys = ['like', 'heart', 'laugh', 'wow', 'sad', 'fire'];
  static const reportReasons = {
    'spam',
    'harassment',
    'fraud',
    'inappropriate',
    'other',
  };

  /// Development only: the other side reads, types and answers.
  final bool simulatePeers;
  final DateTime Function() _clock;
  final Set<MessagingFeature> _disabled;
  final _signals = StreamController<String>.broadcast();
  final List<UnifiedConversationDto> _conversations = [];
  final List<MessagingRecipientDto> _recipients = const [
    MessagingRecipientDto(
      id: 101,
      displayName: 'Aïcha Nguema',
      subtitle: 'Douala · membre Wouanda',
    ),
    MessagingRecipientDto(
      id: 102,
      displayName: 'Moussa Diallo',
      subtitle: 'Yaoundé · membre Wouanda',
    ),
    MessagingRecipientDto(
      id: 103,
      displayName: 'Grace Mballa',
      subtitle: 'Douala · membre Wouanda',
    ),
  ];
  final Map<int, List<UnifiedMessageDto>> _messages = {};

  /// messageId → reactor → key. `me` is the signed-in account.
  final Map<int, Map<String, String>> _reactions = {};

  /// poll messageId → voter → option index (final).
  final Map<int, Map<String, int>> _votes = {};

  /// Buzz messageId → its public space (a conversation outside the inbox).
  final Map<int, int> _spaces = {};
  final Set<int> _hiddenForMe = {};
  final Map<int, Map<int, MessageAttachmentDto>> _draftAttachments = {};
  final Map<int, MessagingPeerStatusDto> _status = {};
  final List<Map<String, Object?>> reports = [];
  ConversationQuery _lastQuery = const ConversationQuery();
  int _conversationOffset = 0;
  final Map<int, int> _messageOffsets = {};
  Future<void>? _ready;
  MessagingCallSessionDto? _activeCall;
  Timer? _callTransition;
  final List<Timer> _peerTimers = [];
  int _sequence = 0;

  @override
  Stream<String> get eventsStream => _signals.stream;

  /// Kill switch for development and tests, as the back-end would do.
  void setFeatureEnabled(MessagingFeature feature, bool enabled) {
    enabled ? _disabled.remove(feature) : _disabled.add(feature);
    _signals.add('capabilities');
  }

  /// `<service>-<type>-<id>` of a known service: the subject an existing
  /// conversation is about (contract v4). Anything else has none.
  static MessagingSubjectDto? _subjectOf(int conversationId) {
    final match = RegExp(
      r'^(go|shop|stay|love|events|support|account)-([a-z]+)-(.+)$',
    ).firstMatch(_mockReferences[conversationId] ?? '');
    if (match == null) return null;
    return MessagingSubjectDto(
      service: match.group(1)!,
      type: match.group(2)!,
      id: match.group(3)!,
    );
  }

  int _id(String prefix) => 3000000000 + _sequence++;

  Future<void> _ensureReady() => _ready ??= () async {
    await _restore();
    if (externalGo) {
      _conversations.removeWhere(
        (c) => c.service == MessagingService.go || (c.subject?.service == 'go'),
      );
      _messages.removeWhere(
        (id, _) => (_mockReferences[id]?.startsWith('go-trip-') ?? false),
      );
    }
  }();

  Future<void> _restore() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw != null) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        _conversations.addAll(
          (map['conversations'] as List? ?? const []).map(
            (item) => UnifiedConversationDto.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          ),
        );
        for (final entry in (map['messages'] as Map? ?? const {}).entries) {
          _messages[int.parse(
            entry.key.toString(),
          )] = (entry.value as List? ?? const [])
              .map(
                (item) => UnifiedMessageDto.fromMap(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();
        }
        for (final entry in (map['reactions'] as Map? ?? const {}).entries) {
          _reactions[int.parse(entry.key)] = Map<String, String>.from(
            entry.value as Map,
          );
        }
        _hiddenForMe.addAll(
          (map['hidden'] as List? ?? const []).whereType<int>(),
        );
        for (final entry in (map['votes'] as Map? ?? const {}).entries) {
          _votes[int.parse(entry.key.toString())] = Map<String, int>.from(
            entry.value as Map,
          );
        }
        for (final entry in (map['spaces'] as Map? ?? const {}).entries) {
          _spaces[int.parse(entry.key.toString())] = (entry.value as num)
              .toInt();
        }
      } on Object {
        _conversations.clear();
        _messages.clear();
        _reactions.clear();
        _votes.clear();
        _spaces.clear();
        _hiddenForMe.clear();
      }
    }
    if (_conversations.isEmpty) _seed();
  }

  /// What a conversation allows, by kind and service (bridge decision).
  static Set<MessagingFeature> featuresFor(
    ConversationKind kind,
    MessagingService service, {
    bool blocked = false,
  }) {
    if (blocked) {
      return {
        MessagingFeature.copy,
        MessagingFeature.deleteForMe,
        MessagingFeature.archive,
        MessagingFeature.block,
        MessagingFeature.report,
        MessagingFeature.search,
      };
    }
    final all = {...MessagingFeature.values}
      ..remove(MessagingFeature.newConversation);
    return switch (kind) {
      ConversationKind.channel => {
        MessagingFeature.cards,
        MessagingFeature.react,
        MessagingFeature.copy,
        MessagingFeature.forward,
        MessagingFeature.pin,
        MessagingFeature.markUnread,
        MessagingFeature.mute,
        MessagingFeature.archive,
        MessagingFeature.report,
        MessagingFeature.search,
      },
      ConversationKind.group => all..remove(MessagingFeature.presence),
      ConversationKind.direct =>
        all
          // A ride or an order stays between its two parties.
          ..removeAll({
            if (service == MessagingService.go ||
                service == MessagingService.shop ||
                service == MessagingService.stay)
              MessagingFeature.forward,
            if (service != MessagingService.account &&
                service != MessagingService.love)
              MessagingFeature.block,
          }),
    };
  }

  void _seed() {
    final now = _clock();
    UnifiedMessageDto message(
      String conversationId,
      String id,
      String content,
      int minutesAgo, {
      bool mine = false,
      String sender = '',
      String type = 'text',
      int? replyToId,
      MessageDelivery delivery = MessageDelivery.delivered,
      List<MessageAttachmentDto> attachments = const [],
      MessageCardDto? card,
    }) => UnifiedMessageDto(
      id: mockMessagingId(id),
      conversationId: mockMessagingId(conversationId),
      content: content,
      type: type,
      senderLabel: mine ? 'Moi' : sender,
      isMine: mine,
      createdAt: now.subtract(Duration(minutes: minutesAgo)),
      delivery: mine ? delivery : MessageDelivery.delivered,
      replyToId: replyToId,
      attachments: attachments,
      card: card,
    );

    void add(
      String id,
      MessagingService service,
      String title,
      String subtitle,
      String context,
      List<UnifiedMessageDto> messages,
      int unread, {
      ConversationKind kind = ConversationKind.direct,
      bool pinned = false,
      bool canSend = true,
      List<MessagingCallKind> calls = const [
        MessagingCallKind.audio,
        MessagingCallKind.video,
      ],
      MessagingPeerStatusDto status = MessagingPeerStatusDto.unknown,
    }) {
      final last = messages.last;
      _conversations.add(
        UnifiedConversationDto(
          id: mockMessagingId(id),
          service: service,
          subject: _subjectOf(mockMessagingId(id)),
          kind: kind,
          title: title,
          subtitle: subtitle,
          contextLabel: context,
          lastMessage: _preview(last),
          lastMessageAt: last.createdAt,
          lastMessageIsMine: last.isMine,
          lastMessageDelivery: last.isMine ? last.delivery : null,
          unreadCount: unread,
          isPinned: pinned,
          canSend: canSend,
          callMethods: calls,
          features: featuresFor(kind, service),
        ),
      );
      _messages[mockMessagingId(id)] = messages;
      _status[mockMessagingId(id)] = status;
    }

    const shop = 'shop-product-204';
    add(
      shop,
      MessagingService.shop,
      'Maison Kotto',
      'Vendeur',
      'Annonce #204',
      [
        message(
          shop,
          '$shop-1',
          'Bonjour, le panier tressé est-il disponible en grand ?',
          52,
          mine: true,
          delivery: MessageDelivery.read,
        ),
        message(
          shop,
          '$shop-2',
          'Oui, il me reste deux pièces en grand format.',
          47,
          sender: 'Maison Kotto',
        ),
        message(
          shop,
          '$shop-3',
          'Parfait, je prends celui en raphia naturel.',
          45,
          mine: true,
          replyToId: mockMessagingId('$shop-2'),
          delivery: MessageDelivery.read,
        ),
        message(
          shop,
          '$shop-4',
          'Votre article est prêt pour la livraison.',
          4,
          sender: 'Maison Kotto',
        ),
      ],
      2,
      pinned: true,
      status: const MessagingPeerStatusDto(isOnline: true),
    );
    _reactions[mockMessagingId('$shop-3')] = {'seller': 'like'};
    const love = 'love-match-amina';
    add(
      love,
      MessagingService.love,
      'Amina',
      'Match',
      'Wouanda Love',
      [
        message(
          love,
          '$love-1',
          'Appel audio · 4 min',
          1440 + 30,
          type: 'system',
        ),
        message(
          love,
          '$love-2',
          'J’ai adoré la balade au bord du Wouri.',
          26,
          sender: 'Amina',
        ),
        message(
          love,
          '$love-3',
          'Moi aussi, on recommence vite.',
          22,
          mine: true,
          delivery: MessageDelivery.read,
        ),
        message(
          love,
          '$love-4',
          'On confirme notre sortie de samedi ?',
          18,
          sender: 'Amina',
        ),
        message(
          love,
          '$love-5',
          '',
          17,
          sender: 'Amina',
          type: 'card',
          card: const MessageCardDto(
            kind: 'dateProposal',
            title: 'Dîner au bord du Wouri',
            subtitle: 'Le Wouri Lounge, Bonapriso',
            value: 'Samedi · 19:30',
            status: 'pending',
            facts: [
              MessageCardFactDto(label: 'Lieu', value: 'Le Wouri Lounge'),
              MessageCardFactDto(label: 'Quand', value: 'Samedi à 19:30'),
            ],
            actions: _answerActions,
          ),
        ),
      ],
      1,
      status: MessagingPeerStatusDto(
        lastSeenAt: now.subtract(const Duration(minutes: 12)),
      ),
    );
    _reactions[mockMessagingId('$love-3')] = {'amina': 'heart'};
    const stay = 'stay-reservation-88';
    add(
      stay,
      MessagingService.stay,
      'Résidence Akwa',
      'Hôte',
      'Réservation #88',
      [
        message(
          stay,
          '$stay-1',
          'Le logement sera disponible dès 14 h.',
          43,
          sender: 'Résidence Akwa',
        ),
      ],
      0,
    );
    const go = 'go-trip-772';
    add(
      go,
      MessagingService.go,
      'Jean · Chauffeur',
      'Course',
      'Course #772',
      [
        message(
          go,
          '$go-1',
          'Je suis devant l’entrée principale.',
          70,
          sender: 'Jean',
        ),
      ],
      0,
      calls: const [MessagingCallKind.audio],
    );
    const ticket = 'events-ticket-31';
    add(
      ticket,
      MessagingService.events,
      'Afro Vibes',
      'Organisation',
      'Billet #31',
      [
        message(
          ticket,
          '$ticket-1',
          'Les portes ouvrent à 18 h 30.',
          150,
          sender: 'Afro Vibes',
        ),
      ],
      0,
    );
    const group = 'group-afro-vibes';
    add(
      group,
      MessagingService.events,
      'Afro Vibes · Équipe',
      '18 membres',
      'Groupe événement',
      [
        message(
          group,
          '$group-1',
          'Kevin a rejoint le groupe',
          60,
          type: 'system',
        ),
        message(
          group,
          '$group-2',
          'La playlist finale est disponible.',
          9,
          sender: 'Kevin',
          attachments: const [
            MessageAttachmentDto(
              id: 4000000000,
              type: 'document',
              label: 'playlist-afro-vibes.pdf',
            ),
          ],
        ),
      ],
      4,
      kind: ConversationKind.group,
    );
    const channel = 'channel-wouanda-news';
    add(
      channel,
      MessagingService.support,
      'Wouanda Actualités',
      'Canal officiel',
      'Canal',
      [
        message(
          channel,
          '$channel-1',
          'Découvrez les nouveautés de la semaine.',
          25,
          sender: 'Wouanda',
        ),
      ],
      1,
      kind: ConversationKind.channel,
      canSend: false,
      calls: const [],
    );
    _persist();
  }

  static String _preview(UnifiedMessageDto message) {
    if (message.isDeleted) return 'Message supprimé';
    if (message.content.isNotEmpty) return message.content;
    if (message.event case final event?) return _eventPreview(event.code);
    if (message.card case final card?) {
      return '${_kindPreview(card.kind)} · ${card.title}';
    }
    if (message.type == 'poll') return 'Sondage · ${message.content}';
    if (message.type == 'post') {
      return message.content.isEmpty ? 'Buzz' : 'Buzz · ${message.content}';
    }
    final attachment = message.attachments.firstOrNull;
    return switch (attachment?.type) {
      'image' => 'Photo',
      'video' => 'Vidéo',
      'voice' => 'Message vocal',
      'audio' => 'Audio',
      'location' => 'Position',
      'document' => attachment!.label,
      _ => '',
    };
  }

  // ─── Capabilities ──────────────────────────────────────────────────────

  Set<MessagingFeature> get _globalFeatures =>
      {...MessagingFeature.values}..removeAll(_disabled);

  @override
  Future<MessagingCapabilitiesDto> getCapabilities() async {
    await _ensureReady();
    return MessagingCapabilitiesDto(
      features: _globalFeatures,
      reactions: reactionKeys,
      editWindowSeconds: editWindow.inSeconds,
      maxAttachmentBytes: 25 * 1024 * 1024,
      maxTextLength: 4000,
    );
  }

  bool _enabled(UnifiedConversationDto conversation, MessagingFeature f) =>
      !_disabled.contains(f) && conversation.features.contains(f);

  void _require(UnifiedConversationDto conversation, MessagingFeature f) {
    if (!_enabled(conversation, f)) {
      throw PlatformException(code: 'MESSAGING_FEATURE_DISABLED');
    }
  }

  /// Bridge-side projection: rights, quotes, reactions and receipts resolved
  /// for the signed-in account at read time.
  UnifiedMessageDto _project(UnifiedMessageDto message) {
    final conversation = _conversation(message.conversationId);
    final age = _clock().difference(message.createdAt);
    final open = message.isMine && !message.isDeleted && !message.isSystem;
    final reactors = _reactions[message.id] ?? const {};
    final counts = <String, int>{};
    for (final key in reactors.values) {
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final quoted = message.replyToId == null
        ? null
        : _messages[message.conversationId]
              ?.where((item) => item.id == message.replyToId)
              .firstOrNull;
    final delivery =
        message.delivery == MessageDelivery.read &&
            !_enabled(conversation, MessagingFeature.readReceipts)
        ? MessageDelivery.delivered
        : message.delivery;
    return UnifiedMessageDto(
      id: message.id,
      clientMessageId: message.clientMessageId,
      conversationId: message.conversationId,
      content: message.content,
      type: message.type,
      senderLabel: message.senderLabel,
      isMine: message.isMine,
      createdAt: message.createdAt,
      editedAt: message.editedAt,
      isDeleted: message.isDeleted,
      isForwarded: message.isForwarded,
      delivery: delivery,
      media: message.media,
      replyToId: message.replyToId,
      replyTo: quoted == null
          ? null
          : MessageQuoteDto(
              id: quoted.id,
              senderLabel: quoted.isMine ? 'Vous' : quoted.senderLabel,
              preview: _preview(quoted),
              type: quoted.attachments.firstOrNull?.type,
            ),
      reactions: [
        for (final entry in counts.entries)
          MessageReactionDto(
            key: entry.key,
            count: entry.value,
            isMine: reactors['me'] == entry.key,
          ),
      ],
      canEdit:
          open &&
          message.content.isNotEmpty &&
          age < editWindow &&
          _enabled(conversation, MessagingFeature.edit),
      canDeleteForEveryone:
          open &&
          age < deleteForEveryoneWindow &&
          _enabled(conversation, MessagingFeature.deleteForEveryone),
      attachments: message.attachments,
      card: _projectCard(message),
      event: message.event,
      poll: _projectPoll(message),
      post: message.type == 'post' ? _projectPost(message) : null,
    );
  }

  MessagePollDto? _projectPoll(UnifiedMessageDto message) {
    final poll = message.poll;
    if (message.type != 'poll' || poll == null) return null;
    final votes = _votes[message.id] ?? const {};
    final counts = List.filled(poll.options.length, 0);
    for (final index in votes.values) {
      if (index >= 0 && index < counts.length) counts[index]++;
    }
    return MessagePollDto(
      options: [
        for (var i = 0; i < poll.options.length; i++)
          MessagePollOptionDto(label: poll.options[i].label, votes: counts[i]),
      ],
      total: votes.length,
      myVote: votes['me'],
    );
  }

  MessagePostDto _projectPost(UnifiedMessageDto message) {
    final space = _spaces[message.id];
    return MessagePostDto(
      spaceId: space,
      comments: space == null
          ? 0
          : (_messages[space] ?? const [])
                .where((item) => !item.isDeleted && !item.isSystem)
                .length,
    );
  }

  // ─── Polls and Buzz (v5) ───────────────────────────────────────────────

  UnifiedConversationDto _sendable(int conversationId, MessagingFeature f) {
    final conversation = _conversation(conversationId);
    _require(conversation, f);
    if (conversation.isBlocked) {
      throw PlatformException(code: 'MESSAGING_BLOCKED');
    }
    if (!conversation.canSend) {
      throw PlatformException(code: 'MESSAGING_SEND_FORBIDDEN');
    }
    return conversation;
  }

  Future<UnifiedMessageDto> _append(UnifiedMessageDto message) async {
    final conversationId = message.conversationId;
    _messages[conversationId]!.add(message);
    _replaceConversation(
      conversationId,
      _conversation(conversationId).copyWith(
        lastMessage: _preview(message),
        lastMessageAt: message.createdAt,
        lastMessageIsMine: true,
        lastMessageDelivery: MessageDelivery.sent,
        unreadCount: 0,
        isMarkedUnread: false,
      ),
    );
    await _persist();
    _signals
      ..add('messages:$conversationId')
      ..add('conversations');
    return _project(message);
  }

  @override
  Future<UnifiedMessageDto> sendPoll({
    required int conversationId,
    required String question,
    required List<String> options,
    int? clientMessageId,
  }) async {
    await _ensureConversation(conversationId);
    _sendable(conversationId, MessagingFeature.poll);
    if (clientMessageId != null) {
      final previous = _messages[conversationId]!
          .where((item) => item.clientMessageId == clientMessageId)
          .firstOrNull;
      if (previous != null) return _project(previous);
    }
    final labels = [
      for (final option in options)
        if (option.trim().isNotEmpty) option.trim(),
    ];
    if (question.trim().isEmpty || labels.length < 2 || labels.length > 4) {
      throw PlatformException(code: WouandaErrorCode.validationFailed);
    }
    return _append(
      UnifiedMessageDto(
        id: _id('msg'),
        clientMessageId: clientMessageId,
        conversationId: conversationId,
        content: question.trim(),
        type: 'poll',
        senderLabel: 'Moi',
        isMine: true,
        createdAt: _clock(),
        delivery: MessageDelivery.sent,
        poll: MessagePollDto(
          options: [
            for (final label in labels) MessagePollOptionDto(label: label),
          ],
        ),
      ),
    );
  }

  @override
  Future<UnifiedMessageDto> votePoll({
    required int conversationId,
    required int messageId,
    required int option,
  }) async {
    await _ensureConversation(conversationId);
    final message = _message(conversationId, messageId);
    final poll = message.poll;
    if (message.type != 'poll' || poll == null) {
      throw PlatformException(code: WouandaErrorCode.validationFailed);
    }
    if (option < 0 || option >= poll.options.length) {
      throw PlatformException(code: WouandaErrorCode.validationFailed);
    }
    final votes = _votes.putIfAbsent(messageId, () => {});
    if (votes.containsKey('me')) return _project(message);
    votes['me'] = option;
    await _persist();
    _signals.add('messages:$conversationId');
    return _project(message);
  }

  @override
  Future<UnifiedMessageDto> sendPost({
    required int conversationId,
    required String text,
    List<int> attachmentIds = const [],
    int? clientMessageId,
  }) async {
    await _ensureConversation(conversationId);
    _sendable(conversationId, MessagingFeature.post);
    if (clientMessageId != null) {
      final previous = _messages[conversationId]!
          .where((item) => item.clientMessageId == clientMessageId)
          .firstOrNull;
      if (previous != null) return _project(previous);
    }
    final clean = text.trim();
    if (clean.isEmpty && attachmentIds.isEmpty) {
      throw PlatformException(code: WouandaErrorCode.validationFailed);
    }
    final drafts = _draftAttachments[conversationId] ?? const {};
    final attachments = <MessageAttachmentDto>[];
    for (final id in attachmentIds) {
      final attachment = drafts[id];
      if (attachment == null ||
          attachment.uploadState != AttachmentUploadState.ready) {
        throw PlatformException(code: 'MESSAGING_ATTACHMENT_NOT_READY');
      }
      attachments.add(attachment);
    }
    for (final id in attachmentIds) {
      _draftAttachments[conversationId]?.remove(id);
    }
    return _append(
      UnifiedMessageDto(
        id: _id('msg'),
        clientMessageId: clientMessageId,
        conversationId: conversationId,
        content: clean,
        type: 'post',
        senderLabel: 'Moi',
        isMine: true,
        createdAt: _clock(),
        delivery: MessageDelivery.sent,
        attachments: attachments,
      ),
    );
  }

  @override
  Future<UnifiedConversationDto> openPostSpace({
    required int conversationId,
    required int messageId,
  }) async {
    await _ensureConversation(conversationId);
    final message = _message(conversationId, messageId);
    if (message.type != 'post') {
      throw PlatformException(code: WouandaErrorCode.validationFailed);
    }
    final known = _spaces[messageId];
    if (known != null && _conversations.any((item) => item.id == known)) {
      return _projectConversation(_conversation(known));
    }
    final parent = _conversation(conversationId);
    final author = message.isMine ? 'Vous' : message.senderLabel;
    final space = UnifiedConversationDto(
      id: _id('space'),
      service: parent.service,
      serviceKey: parent.serviceKey,
      kind: ConversationKind.group,
      title: 'Buzz · $author',
      subtitle: 'Espace public',
      features: featuresFor(ConversationKind.group, parent.service)
        ..removeAll({MessagingFeature.poll, MessagingFeature.post}),
    );
    _conversations.add(space);
    _messages[space.id] = [];
    _spaces[messageId] = space.id;
    await _persist();
    _signals.add('messages:$conversationId');
    return space;
  }

  bool _isSpace(int conversationId) => _spaces.containsValue(conversationId);

  MessageCardDto? _projectCard(UnifiedMessageDto message) {
    final card = message.card;
    if (card == null) return null;
    return message.isMine || card.status != 'pending'
        ? card.copyWith(actions: const [])
        : card;
  }

  /// Answers an invitation, a proposal or an offer (v3): codes only.
  static const _answerActions = ['decline', 'accept'];

  /// The inbox line of a card, written by the bridge like « Photo ».
  static String _kindPreview(String kind) => switch (kind) {
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

  static bool _answerable(String kind) =>
      kind == 'invitation' || kind == 'dateProposal' || kind == 'offer';

  @override
  Future<UnifiedMessageDto> sendCard({
    required int conversationId,
    required MessageCardDraft draft,
    int? clientMessageId,
  }) async {
    await _ensureConversation(conversationId);
    final conversation = _conversation(conversationId);
    _require(conversation, MessagingFeature.cards);
    if (conversation.isBlocked) {
      throw PlatformException(code: 'MESSAGING_BLOCKED');
    }
    if (!conversation.canSend) {
      throw PlatformException(code: 'MESSAGING_SEND_FORBIDDEN');
    }
    if (clientMessageId != null) {
      final previous = _messages[conversationId]!
          .where((item) => item.clientMessageId == clientMessageId)
          .firstOrNull;
      if (previous != null) return _project(previous);
    }
    if (draft.title.trim().isEmpty || draft.refId.trim().isEmpty) {
      throw PlatformException(code: WouandaErrorCode.validationFailed);
    }
    final answerable = _answerable(draft.kind);
    final message = UnifiedMessageDto(
      id: _id('msg'),
      clientMessageId: clientMessageId,
      conversationId: mockMessagingId(conversationId),
      content: '',
      type: 'card',
      senderLabel: 'Moi',
      isMine: true,
      createdAt: _clock(),
      delivery: MessageDelivery.sent,
      card: MessageCardDto(
        kind: draft.kind,
        title: draft.title.trim(),
        subtitle: draft.subtitle,
        media: draft.media,
        value: draft.value,
        route: draft.route,
        facts: draft.facts,
        status: answerable ? 'pending' : null,
        actions: answerable ? _answerActions : const [],
      ),
    );
    _messages[conversationId]!.add(message);
    _replaceConversation(
      conversationId,
      _conversation(conversationId).copyWith(
        lastMessage: _preview(message),
        lastMessageAt: message.createdAt,
        lastMessageIsMine: true,
        lastMessageDelivery: MessageDelivery.sent,
      ),
    );
    await _persist();
    _signals
      ..add('messages:$conversationId')
      ..add('conversations');
    return _project(message);
  }

  @override
  Future<UnifiedMessageDto> performCardAction({
    required int conversationId,
    required int messageId,
    required String actionId,
  }) async {
    await _ensureConversation(conversationId);
    _require(_conversation(conversationId), MessagingFeature.cards);
    final message = _message(conversationId, messageId);
    final card = message.card;
    if (card == null ||
        message.isMine ||
        card.status != 'pending' ||
        !card.actions.contains(actionId)) {
      throw PlatformException(code: 'MESSAGING_ACTION_NOT_ALLOWED');
    }
    final accepted = actionId == 'accept';
    final updated = message.copyWith(
      card: card.copyWith(
        status: accepted ? 'accepted' : 'declined',
        actions: const [],
      ),
    );
    final list = _messages[conversationId]!;
    list[list.indexWhere((item) => item.id == messageId)] = updated;
    await _persist();
    _signals.add('messages:$conversationId');
    return _project(updated);
  }

  List<UnifiedMessageDto> _visible(int conversationId) => [
    for (final message in _messages[conversationId]!)
      if (!_hiddenForMe.contains(message.id)) message,
  ];

  // ─── Conversations ─────────────────────────────────────────────────────

  @override
  Future<List<UnifiedConversationDto>> loadConversations(
    ConversationQuery query,
  ) async {
    await _ensureReady();
    _lastQuery = query;
    _conversationOffset = 0;
    return _nextConversations();
  }

  @override
  Future<List<UnifiedConversationDto>> loadMoreConversations() async {
    await _ensureReady();
    return _nextConversations();
  }

  List<UnifiedConversationDto> _nextConversations() {
    final term = _lastQuery.search?.trim().toLowerCase() ?? '';
    final selected =
        _conversations.where((conversation) {
          // A Buzz space is reached from its Buzz, never from the inbox.
          if (_isSpace(conversation.id)) return false;
          if (conversation.isArchived != _lastQuery.archived) return false;
          if (_lastQuery.unreadOnly && !conversation.isUnread) return false;
          if (_lastQuery.service != null &&
              conversation.service != _lastQuery.service) {
            return false;
          }
          if (_lastQuery.kind != null && conversation.kind != _lastQuery.kind) {
            return false;
          }
          if (term.isEmpty) return true;
          // A word found anywhere in the conversation, cards included, not
          // only in its last line.
          bool inMessages() =>
              (_messages[conversation.id] ?? const []).any((m) {
                if (m.isDeleted) return false;
                final card = m.card;
                return m.content.toLowerCase().contains(term) ||
                    (card != null &&
                        [card.title, card.subtitle, card.value]
                            .whereType<String>()
                            .any((text) => text.toLowerCase().contains(term)));
              });
          return conversation.title.toLowerCase().contains(term) ||
              (conversation.lastMessage?.toLowerCase().contains(term) ??
                  false) ||
              (conversation.contextLabel?.toLowerCase().contains(term) ??
                  false) ||
              inMessages();
        }).toList()..sort((a, b) {
          if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
          return (b.lastMessageAt ?? DateTime(1970)).compareTo(
            a.lastMessageAt ?? DateTime(1970),
          );
        });
    final end = (_conversationOffset + pageSize).clamp(0, selected.length);
    final page = selected.sublist(_conversationOffset, end);
    _conversationOffset = end;
    return [for (final item in page) _projectConversation(item)];
  }

  /// Drafts and receipts follow the global switches too.
  UnifiedConversationDto _projectConversation(UnifiedConversationDto item) {
    var value = item;
    if (!_enabled(item, MessagingFeature.drafts) && item.hasDraft) {
      value = value.copyWith(clearDraft: true);
    }
    if (item.lastMessageDelivery == MessageDelivery.read &&
        !_enabled(item, MessagingFeature.readReceipts)) {
      value = value.copyWith(lastMessageDelivery: MessageDelivery.delivered);
    }
    return value;
  }

  @override
  Future<List<UnifiedMessageDto>> loadMessages(int conversationId) async {
    await _ensureConversation(conversationId);
    final all = _visible(conversationId);
    final start = (all.length - pageSize).clamp(0, all.length);
    _messageOffsets[conversationId] = start;
    return all.sublist(start).map(_project).toList();
  }

  @override
  Future<List<UnifiedMessageDto>> loadMoreMessages(int conversationId) async {
    await _ensureConversation(conversationId);
    final all = _visible(conversationId);
    final end = (_messageOffsets[conversationId] ?? all.length).clamp(
      0,
      all.length,
    );
    final start = (end - pageSize).clamp(0, end);
    _messageOffsets[conversationId] = start;
    return all.sublist(start, end).map(_project).toList();
  }

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
  }) async {
    await _ensureConversation(conversationId);
    final conversation = _conversation(conversationId);
    if (!conversation.canSend) {
      throw PlatformException(code: 'MESSAGING_SEND_FORBIDDEN');
    }
    if (sourceUri.trim().isEmpty || label.trim().isEmpty) {
      throw PlatformException(code: WouandaErrorCode.validationFailed);
    }
    if ((sizeBytes ?? 0) > 25 * 1024 * 1024) {
      throw PlatformException(code: 'MESSAGING_ATTACHMENT_TOO_LARGE');
    }
    const supportedTypes = {
      'image',
      'video',
      'audio',
      'voice',
      'document',
      'location',
    };
    if (!supportedTypes.contains(type)) {
      throw PlatformException(code: WouandaErrorCode.validationFailed);
    }
    final source = Uri.tryParse(sourceUri);
    final remote = source?.scheme == 'http' || source?.scheme == 'https';
    final media = MediaDto(
      type: MediaType.fromCode(type == 'voice' ? 'audio' : type),
      url: remote ? sourceUri : null,
      path: remote ? null : sourceUri,
      label: label,
    );
    final attachment = MessageAttachmentDto(
      id: _id('attachment'),
      type: type,
      label: label.trim(),
      preview: type == 'image' ? media : null,
      media: media,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      durationMs: durationMs,
      waveform: waveform,
      uploadState: AttachmentUploadState.ready,
      uploadProgress: 1,
    );
    _draftAttachments.putIfAbsent(conversationId, () => {})[attachment.id] =
        attachment;
    _signals.add('attachment:${attachment.id}');
    return attachment;
  }

  @override
  Future<void> discardAttachment(int conversationId, int attachmentId) async {
    await _ensureConversation(conversationId);
    _draftAttachments[conversationId]?.remove(attachmentId);
    _signals.add('attachment:$attachmentId');
  }

  @override
  Future<UnifiedMessageDto> sendMessage({
    required int conversationId,
    required String text,
    int? clientMessageId,
    int? replyToId,
    List<int> attachmentIds = const [],
  }) async {
    await _ensureConversation(conversationId);
    final conversation = _conversation(conversationId);
    if (conversation.isBlocked) {
      throw PlatformException(code: 'MESSAGING_BLOCKED');
    }
    if (!conversation.canSend) {
      throw PlatformException(code: 'MESSAGING_SEND_FORBIDDEN');
    }
    // Idempotent retry: the same client id returns the stored message.
    if (clientMessageId != null) {
      final previous = _messages[conversationId]!
          .where((item) => item.clientMessageId == clientMessageId)
          .firstOrNull;
      if (previous != null) return _project(previous);
    }
    final clean = text.trim();
    if (clean.isEmpty && attachmentIds.isEmpty) {
      throw PlatformException(code: WouandaErrorCode.validationFailed);
    }
    if (replyToId != null) {
      _require(conversation, MessagingFeature.reply);
      if (!_messages[conversationId]!.any((item) => item.id == replyToId)) {
        throw PlatformException(code: 'MESSAGING_MESSAGE_NOT_FOUND');
      }
    }
    final drafts = _draftAttachments[conversationId] ?? const {};
    final attachments = <MessageAttachmentDto>[];
    for (final id in attachmentIds) {
      final attachment = drafts[id];
      if (attachment == null ||
          attachment.uploadState != AttachmentUploadState.ready) {
        throw PlatformException(code: 'MESSAGING_ATTACHMENT_NOT_READY');
      }
      attachments.add(attachment);
    }
    final message = UnifiedMessageDto(
      id: _id('msg'),
      clientMessageId: clientMessageId,
      conversationId: conversationId,
      content: clean,
      type: 'text',
      senderLabel: 'Moi',
      isMine: true,
      createdAt: _clock(),
      delivery: MessageDelivery.sent,
      replyToId: replyToId,
      attachments: attachments,
    );
    _messages[conversationId]!.add(message);
    for (final id in attachmentIds) {
      _draftAttachments[conversationId]?.remove(id);
    }
    _replaceConversation(
      conversationId,
      conversation.copyWith(
        lastMessage: _preview(message),
        lastMessageAt: message.createdAt,
        lastMessageIsMine: true,
        lastMessageDelivery: MessageDelivery.sent,
        unreadCount: 0,
        isMarkedUnread: false,
        clearDraft: true,
      ),
    );
    await _persist();
    _signals.add('messages:$conversationId');
    _signals.add('conversations');
    if (simulatePeers) _simulateReply(conversationId, message.id);
    return _project(message);
  }

  /// Development peer: delivered, read, typing, then a short answer.
  void _simulateReply(int conversationId, int messageId) {
    final conversation = _conversation(conversationId);
    if (conversation.kind == ConversationKind.channel) return;
    void later(int ms, void Function() run) =>
        _peerTimers.add(Timer(Duration(milliseconds: ms), run));
    later(
      500,
      () => _setDelivery(conversationId, messageId, MessageDelivery.delivered),
    );
    later(1300, () {
      _setDelivery(conversationId, messageId, MessageDelivery.read);
      _setStatus(
        conversationId,
        MessagingPeerStatusDto(
          isTyping: true,
          typingLabel: conversation.kind == ConversationKind.group
              ? 'Kevin écrit…'
              : null,
          isOnline: true,
        ),
      );
    });
    later(3200, () {
      _setStatus(conversationId, const MessagingPeerStatusDto(isOnline: true));
      final reply = UnifiedMessageDto(
        id: _id('msg'),
        conversationId: conversationId,
        content: 'Bien reçu, merci.',
        type: 'text',
        senderLabel: conversation.kind == ConversationKind.group
            ? 'Kevin'
            : conversation.title,
        isMine: false,
        createdAt: _clock(),
        delivery: MessageDelivery.delivered,
      );
      _messages[conversationId]?.add(reply);
      _replaceConversation(
        conversationId,
        _conversation(conversationId).copyWith(
          lastMessage: reply.content,
          lastMessageAt: reply.createdAt,
          lastMessageIsMine: false,
          unreadCount: _conversation(conversationId).unreadCount + 1,
        ),
      );
      _persist();
      _signals
        ..add('messages:$conversationId')
        ..add('conversations')
        ..add('unread');
    });
  }

  void _setDelivery(int conversationId, int id, MessageDelivery value) {
    final list = _messages[conversationId];
    final index = list?.indexWhere((item) => item.id == id) ?? -1;
    if (index < 0) return;
    list![index] = list[index].copyWith(delivery: value);
    final conversation = _conversation(conversationId);
    if (conversation.lastMessageIsMine) {
      _replaceConversation(
        conversationId,
        conversation.copyWith(lastMessageDelivery: value),
      );
    }
    _signals
      ..add('messages:$conversationId')
      ..add('conversations');
  }

  void _setStatus(int conversationId, MessagingPeerStatusDto value) {
    _status[conversationId] = value;
    _signals.add('status:$conversationId');
  }

  @override
  Future<void> markConversationRead(int conversationId) async {
    await _ensureConversation(conversationId);
    final current = _conversation(conversationId);
    _replaceConversation(
      conversationId,
      current.copyWith(unreadCount: 0, isMarkedUnread: false),
    );
    await _persist();
    _signals.add('unread');
    _signals.add('conversations');
  }

  @override
  Future<UnifiedConversationDto> markConversationUnread(
    int conversationId,
  ) async {
    await _ensureConversation(conversationId);
    final current = _conversation(conversationId);
    _require(current, MessagingFeature.markUnread);
    final updated = current.copyWith(isMarkedUnread: true);
    _replaceConversation(conversationId, updated);
    await _persist();
    _signals
      ..add('unread')
      ..add('conversations');
    return updated;
  }

  Future<UnifiedConversationDto> _update(
    int conversationId,
    MessagingFeature feature,
    UnifiedConversationDto Function(UnifiedConversationDto) change,
  ) async {
    await _ensureConversation(conversationId);
    final current = _conversation(conversationId);
    _require(current, feature);
    final updated = change(current);
    _replaceConversation(conversationId, updated);
    await _persist();
    _signals.add('conversations');
    return updated;
  }

  @override
  Future<UnifiedConversationDto> setMuted(int conversationId, bool muted) =>
      _update(
        conversationId,
        MessagingFeature.mute,
        (value) => value.copyWith(isMuted: muted),
      );

  @override
  Future<UnifiedConversationDto> setArchived(
    int conversationId,
    bool archived,
  ) => _update(
    conversationId,
    MessagingFeature.archive,
    (value) => value.copyWith(isArchived: archived),
  );

  @override
  Future<UnifiedConversationDto> setPinned(int conversationId, bool pinned) =>
      _update(
        conversationId,
        MessagingFeature.pin,
        (value) => value.copyWith(isPinned: pinned),
      );

  @override
  Future<UnifiedConversationDto> setBlocked(
    int conversationId,
    bool blocked,
  ) async {
    final updated = await _update(
      conversationId,
      MessagingFeature.block,
      (value) => value.copyWith(
        isBlocked: blocked,
        canSend: !blocked,
        callMethods: blocked
            ? const []
            : const [MessagingCallKind.audio, MessagingCallKind.video],
        features: featuresFor(value.kind, value.service, blocked: blocked),
      ),
    );
    _signals.add('messages:$conversationId');
    return updated;
  }

  @override
  Future<void> saveDraft(int conversationId, String text) async {
    await _ensureConversation(conversationId);
    final current = _conversation(conversationId);
    _require(current, MessagingFeature.drafts);
    final clean = text.trim();
    if ((current.draft ?? '') == clean) return;
    _replaceConversation(
      conversationId,
      clean.isEmpty
          ? current.copyWith(clearDraft: true)
          : current.copyWith(draft: clean),
    );
    await _persist();
    _signals.add('conversations');
  }

  @override
  Future<MessagingPeerStatusDto> loadPeerStatus(int conversationId) async {
    await _ensureConversation(conversationId);
    final conversation = _conversation(conversationId);
    final status = _status[conversationId] ?? MessagingPeerStatusDto.unknown;
    final presence = _enabled(conversation, MessagingFeature.presence);
    final typing = _enabled(conversation, MessagingFeature.typing);
    return MessagingPeerStatusDto(
      isTyping: typing && status.isTyping,
      typingLabel: typing ? status.typingLabel : null,
      isOnline: presence && status.isOnline,
      lastSeenAt: presence ? status.lastSeenAt : null,
    );
  }

  @override
  Future<void> setTyping(int conversationId, bool typing) async {
    await _ensureConversation(conversationId);
    _require(_conversation(conversationId), MessagingFeature.typing);
  }

  @override
  Future<void> reportConversation({
    required int conversationId,
    required String reason,
    int? messageId,
  }) async {
    await _ensureConversation(conversationId);
    _require(_conversation(conversationId), MessagingFeature.report);
    if (!reportReasons.contains(reason)) {
      throw PlatformException(code: WouandaErrorCode.validationFailed);
    }
    if (messageId != null) _message(conversationId, messageId);
    reports.add({
      'conversationId': conversationId,
      'reason': reason,
      'messageId': messageId,
    });
  }

  @override
  Future<List<UnifiedMessageDto>> searchMessages(
    int conversationId,
    String query,
  ) async {
    await _ensureConversation(conversationId);
    _require(_conversation(conversationId), MessagingFeature.search);
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return const [];
    return _visible(conversationId)
        .where(
          (item) =>
              !item.isDeleted &&
              !item.isSystem &&
              (item.content.toLowerCase().contains(term) ||
                  item.attachments.any(
                    (a) => a.label.toLowerCase().contains(term),
                  )),
        )
        .toList()
        .reversed
        .map(_project)
        .toList();
  }

  // ─── Message actions ───────────────────────────────────────────────────

  UnifiedMessageDto _message(int conversationId, int messageId) =>
      _messages[conversationId]!
          .where((item) => item.id == messageId)
          .firstOrNull ??
      (throw PlatformException(code: 'MESSAGING_MESSAGE_NOT_FOUND'));

  void _replaceMessage(UnifiedMessageDto value) {
    final list = _messages[value.conversationId]!;
    list[list.indexWhere((item) => item.id == value.id)] = value;
  }

  void _refreshLast(int conversationId) {
    final last = _visible(conversationId).lastOrNull;
    if (last == null) return;
    _replaceConversation(
      conversationId,
      _conversation(conversationId).copyWith(
        lastMessage: _preview(last),
        lastMessageAt: last.createdAt,
        lastMessageIsMine: last.isMine,
      ),
    );
  }

  @override
  Future<UnifiedMessageDto> editMessage({
    required int conversationId,
    required int messageId,
    required String text,
  }) async {
    await _ensureConversation(conversationId);
    _require(_conversation(conversationId), MessagingFeature.edit);
    final message = _message(conversationId, messageId);
    final clean = text.trim();
    if (clean.isEmpty) {
      throw PlatformException(code: WouandaErrorCode.validationFailed);
    }
    if (!_project(message).canEdit) {
      throw PlatformException(
        code: message.isMine
            ? 'MESSAGING_EDIT_WINDOW_EXPIRED'
            : WouandaErrorCode.forbidden,
      );
    }
    final edited = message.copyWith(content: clean, editedAt: _clock());
    _replaceMessage(edited);
    _refreshLast(conversationId);
    await _persist();
    _signals
      ..add('messages:$conversationId')
      ..add('conversations');
    return _project(edited);
  }

  @override
  Future<void> deleteMessage({
    required int conversationId,
    required int messageId,
    required bool forEveryone,
  }) async {
    await _ensureConversation(conversationId);
    final conversation = _conversation(conversationId);
    final message = _message(conversationId, messageId);
    if (forEveryone) {
      _require(conversation, MessagingFeature.deleteForEveryone);
      if (!_project(message).canDeleteForEveryone) {
        throw PlatformException(code: WouandaErrorCode.forbidden);
      }
      _replaceMessage(
        message.copyWith(
          content: '',
          isDeleted: true,
          attachments: const [],
          reactions: const [],
        ),
      );
      _reactions.remove(messageId);
    } else {
      _require(conversation, MessagingFeature.deleteForMe);
      _hiddenForMe.add(messageId);
    }
    _refreshLast(conversationId);
    await _persist();
    _signals
      ..add('messages:$conversationId')
      ..add('conversations');
  }

  @override
  Future<UnifiedMessageDto> reactToMessage({
    required int conversationId,
    required int messageId,
    String? key,
  }) async {
    await _ensureConversation(conversationId);
    _require(_conversation(conversationId), MessagingFeature.react);
    final message = _message(conversationId, messageId);
    if (message.isDeleted || message.isSystem) {
      throw PlatformException(code: WouandaErrorCode.forbidden);
    }
    // Any emoji typed on the phone, one symbol at most.
    if (key != null &&
        !reactionKeys.contains(key) &&
        key.characters.length != 1) {
      throw PlatformException(code: WouandaErrorCode.validationFailed);
    }
    final reactors = _reactions.putIfAbsent(messageId, () => {});
    key == null ? reactors.remove('me') : reactors['me'] = key;
    await _persist();
    _signals.add('messages:$conversationId');
    return _project(message);
  }

  @override
  Future<void> forwardMessage({
    required int conversationId,
    required int messageId,
    required List<int> targetConversationIds,
  }) async {
    await _ensureConversation(conversationId);
    _require(_conversation(conversationId), MessagingFeature.forward);
    final source = _message(conversationId, messageId);
    if (source.isDeleted || source.isSystem || targetConversationIds.isEmpty) {
      throw PlatformException(code: WouandaErrorCode.validationFailed);
    }
    for (final target in targetConversationIds) {
      await _ensureConversation(target);
      final conversation = _conversation(target);
      if (!conversation.canSend || conversation.isBlocked) {
        throw PlatformException(code: 'MESSAGING_SEND_FORBIDDEN');
      }
    }
    for (final target in targetConversationIds) {
      final copy = UnifiedMessageDto(
        id: _id('msg'),
        conversationId: target,
        content: source.content,
        type: 'text',
        senderLabel: 'Moi',
        isMine: true,
        createdAt: _clock(),
        delivery: MessageDelivery.sent,
        isForwarded: true,
        attachments: source.attachments,
      );
      _messages[target]!.add(copy);
      _replaceConversation(
        target,
        _conversation(target).copyWith(
          lastMessage: _preview(copy),
          lastMessageAt: copy.createdAt,
          lastMessageIsMine: true,
          lastMessageDelivery: MessageDelivery.sent,
        ),
      );
      _signals.add('messages:$target');
    }
    await _persist();
    _signals.add('conversations');
  }

  @override
  Future<Map<ConversationKind, int>> getUnreadCountsByKind() async {
    await _ensureReady();
    final counts = {for (final kind in ConversationKind.values) kind: 0};
    for (final item in _conversations.where(
      (c) => !c.isArchived && !c.isMuted,
    )) {
      counts[item.kind] =
          counts[item.kind]! +
          (item.unreadCount > 0
              ? item.unreadCount
              : (item.isMarkedUnread ? 1 : 0));
    }
    return counts;
  }

  @override
  Future<int> getUnreadForSubject(MessagingSubjectDto subject) async {
    await _ensureReady();
    final match = _conversations.where((c) => c.subject == subject).firstOrNull;
    if (match == null) return 0;
    return match.unreadCount > 0
        ? match.unreadCount
        : (match.isMarkedUnread ? 1 : 0);
  }

  /// The inbox line of a service event, written by the bridge like « Photo ».
  static String _eventPreview(String code) => switch (code) {
    'trip.assigned' => 'Chauffeur en route',
    'trip.arrived' => 'Votre chauffeur est arrivé',
    'trip.started' => 'Course commencée',
    'trip.completed' => 'Course terminée',
    'trip.cancelled' => 'Course annulée',
    'booking.requested' => 'Demande de réservation',
    'booking.accepted' => 'Réservation acceptée',
    'booking.declined' => 'Réservation refusée',
    'booking.cancelled' => 'Réservation annulée',
    'ticket.purchased' => 'Billet confirmé',
    'ticket.cancelled' => 'Billet annulé',
    'event.cancelled' => 'Événement annulé',
    'event.rescheduled' => 'Événement reprogrammé',
    _ => 'Mise à jour',
  };

  @override
  Future<UnifiedMessageDto> postServiceEvent(ServiceEventDraft draft) async {
    await _ensureReady();
    final id = mockMessagingId(draft.subject.reference);
    final clientId = mockMessagingId('evt:${draft.eventId}');
    var conversation = _conversations.where((c) => c.id == id).firstOrNull;
    if (conversation == null) {
      final seed = draft.seed;
      if (seed == null) {
        throw PlatformException(code: 'MESSAGING_CONVERSATION_NOT_FOUND');
      }
      final service = MessagingService.values
          .where((value) => value.name == draft.subject.service)
          .firstOrNull;
      conversation = UnifiedConversationDto(
        id: id,
        service: service ?? MessagingService.other,
        serviceKey: draft.subject.service,
        subject: draft.subject,
        kind: seed.kind,
        title: seed.title,
        subtitle: seed.subtitle,
        avatar: seed.avatar,
        canSend: seed.canSend,
        contextLabel: seed.contextTitle,
        context: ConversationContextDto(
          title: seed.contextTitle,
          status: draft.contextStatus,
          route: seed.contextRoute,
          actions: [
            if (seed.contextRoute != null)
              ConversationContextActionDto(
                code: 'open',
                route: seed.contextRoute,
              ),
          ],
        ),
        features: featuresFor(seed.kind, service ?? MessagingService.other),
      );
      _conversations.add(conversation);
      _messages[id] = [];
    } else {
      final replay = (_messages[id] ?? const <UnifiedMessageDto>[])
          .where((m) => m.clientMessageId == clientId)
          .firstOrNull;
      if (replay != null) return _project(replay);
    }
    final message = UnifiedMessageDto(
      id: _id('msg'),
      clientMessageId: clientId,
      conversationId: id,
      content: '',
      type: 'system',
      senderLabel: '',
      isMine: false,
      createdAt: _clock(),
      delivery: MessageDelivery.delivered,
      event: MessageServiceEventDto(code: draft.code, params: draft.params),
    );
    _messages[id]!.add(message);
    final context = conversation.context;
    _replaceConversation(
      id,
      conversation.copyWith(
        lastMessage: _eventPreview(draft.code),
        lastMessageAt: message.createdAt,
        lastMessageIsMine: false,
        unreadCount: conversation.unreadCount + 1,
        context: draft.contextStatus == null || context == null
            ? null
            : ConversationContextDto(
                title: context.title,
                status: draft.contextStatus,
                route: context.route,
                actions: context.actions,
              ),
        // Once the owner closes it, it is read only for good.
        canSend: draft.closedReason == null ? null : false,
        closedReason: draft.closedReason,
      ),
    );
    await _persist();
    _signals
      ..add('messages:$id')
      ..add('conversations')
      ..add('unread');
    return _project(message);
  }

  @override
  Future<int> getUnreadCount() async {
    await _ensureReady();
    return _conversations
        .where((item) => !item.isArchived)
        .fold<int>(
          0,
          (sum, item) =>
              sum +
              (item.unreadCount > 0
                  ? item.unreadCount
                  : (item.isMarkedUnread ? 1 : 0)),
        );
  }

  @override
  Future<List<MessagingRecipientDto>> searchRecipients(String query) async {
    await _ensureReady();
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return _recipients;
    return _recipients
        .where(
          (recipient) =>
              recipient.displayName.toLowerCase().contains(term) ||
              (recipient.subtitle?.toLowerCase().contains(term) ?? false),
        )
        .toList();
  }

  @override
  Future<UnifiedConversationDto> openDirectConversation(int recipientId) async {
    await _ensureReady();
    if (_disabled.contains(MessagingFeature.newConversation)) {
      throw PlatformException(code: 'MESSAGING_FEATURE_DISABLED');
    }
    final recipient = _recipients.firstWhere(
      (item) => item.id == recipientId,
      orElse: () =>
          throw PlatformException(code: 'MESSAGING_RECIPIENT_NOT_FOUND'),
    );
    final existing = _conversations.where(
      (item) =>
          item.kind == ConversationKind.direct &&
          item.service == MessagingService.account &&
          item.peerId == recipient.id,
    );
    if (existing.isNotEmpty) return existing.first;

    final conversation = UnifiedConversationDto(
      id: mockMessagingId('direct-${recipient.id}'),
      service: MessagingService.account,
      kind: ConversationKind.direct,
      peerId: recipient.id,
      title: recipient.displayName,
      subtitle: recipient.subtitle ?? 'Membre Wouanda',
      avatar: recipient.avatar,
      canSend: true,
      features: featuresFor(ConversationKind.direct, MessagingService.account),
    );
    _conversations.add(conversation);
    _messages[conversation.id] = [];
    await _persist();
    _signals.add('conversations');
    return conversation;
  }

  @override
  Future<UnifiedConversationDto> openConversation(int id) => _resolve(id);
  @override
  Future<UnifiedConversationDto> resolveConversation(String reference) =>
      _resolve(reference);
  Future<UnifiedConversationDto> _resolve(Object reference) async {
    final conversationId = mockMessagingId(reference);
    final legacyReference = _mockReferences[conversationId] ?? '';
    if (externalGo && legacyReference.startsWith('go-trip-')) {
      throw PlatformException(code: 'MESSAGING_CONVERSATION_NOT_FOUND');
    }
    await _ensureReady();
    final existing = _conversations.where((item) => item.id == conversationId);
    if (existing.isNotEmpty) return _projectConversation(existing.first);

    // The production bridge resolves these projections from each service.
    // The mock accepts only the global prefixes defined by the contract.
    final projection = switch (legacyReference.split('-').first) {
      'go' => (
        MessagingService.go,
        'Votre chauffeur',
        'Course Wouanda Go',
        'Course',
      ),
      'shop' => (
        MessagingService.shop,
        'Conversation Shop',
        'Acheteur et vendeur',
        'Article',
      ),
      'stay' => (
        MessagingService.stay,
        'Conversation Stay',
        'Hôte et voyageur',
        'Réservation',
      ),
      'love' => (
        MessagingService.love,
        'Conversation Love',
        'Votre match',
        'Rencontre',
      ),
      'events' => (
        MessagingService.events,
        'Conversation Events',
        'Événement',
        'Billet',
      ),
      _ => null,
    };
    if (projection == null) {
      throw PlatformException(code: 'MESSAGING_CONVERSATION_NOT_FOUND');
    }
    final conversation = UnifiedConversationDto(
      id: conversationId,
      service: projection.$1,
      subject: _subjectOf(conversationId),
      title: projection.$2,
      subtitle: projection.$3,
      contextLabel: '${projection.$4} · ${legacyReference.split('-').last}',
      canSend: true,
      callMethods: projection.$1 == MessagingService.go
          ? const [MessagingCallKind.audio]
          : const [MessagingCallKind.audio, MessagingCallKind.video],
      features: featuresFor(ConversationKind.direct, projection.$1),
    );
    _conversations.add(conversation);
    _messages[conversationId] = [];
    await _persist();
    _signals.add('conversations');
    return conversation;
  }

  @override
  Future<MessagingCallSessionDto> startCall(
    int conversationId,
    MessagingCallKind kind,
  ) async {
    await _ensureConversation(conversationId);
    final conversation = _conversation(conversationId);
    if (!conversation.callMethods.contains(kind)) {
      throw PlatformException(code: 'MESSAGING_CALL_FORBIDDEN');
    }
    if (_activeCall != null && _activeCall!.state != MessagingCallState.ended) {
      throw PlatformException(code: 'MESSAGING_CALL_BUSY');
    }
    _activeCall = MessagingCallSessionDto(
      id: _id('call'),
      conversationId: conversationId,
      kind: kind,
      state: MessagingCallState.connecting,
      startedAt: _clock(),
      isCameraEnabled: kind == MessagingCallKind.video,
    );
    _signals.add('calls');
    _signals.add('call:${_activeCall!.id}');
    _callTransition?.cancel();
    _callTransition = Timer(const Duration(milliseconds: 700), () {
      final active = _activeCall;
      if (active == null || active.state != MessagingCallState.connecting) {
        return;
      }
      _activeCall = active.copyWith(
        state: MessagingCallState.active,
        connectedAt: _clock(),
      );
      _signals.add('call:${active.id}');
    });
    return _activeCall!;
  }

  @override
  Future<MessagingCallSessionDto?> loadActiveCall() async {
    await _ensureReady();
    return _activeCall;
  }

  MessagingCallSessionDto _requireCall(int callId) {
    final call = _activeCall;
    if (call == null || call.id != callId) {
      throw PlatformException(code: 'MESSAGING_CALL_NOT_FOUND');
    }
    return call;
  }

  /// Development only: the other side calls me. The real bridge raises the
  /// `calls` signal from the network.
  Future<MessagingCallSessionDto> simulateIncomingCall(
    int conversationId,
    MessagingCallKind kind,
  ) async {
    await _ensureConversation(conversationId);
    _activeCall = MessagingCallSessionDto(
      id: _id('call'),
      conversationId: conversationId,
      kind: kind,
      state: MessagingCallState.ringing,
      startedAt: _clock(),
      isIncoming: true,
    );
    _signals.add('calls');
    return _activeCall!;
  }

  @override
  Future<MessagingCallSessionDto> acceptCall(int callId) async {
    final call = _requireCall(callId);
    if (call.state != MessagingCallState.ringing) {
      throw PlatformException(code: 'MESSAGING_CALL_NOT_FOUND');
    }
    _activeCall = call.copyWith(
      state: MessagingCallState.active,
      connectedAt: _clock(),
      isCameraEnabled: call.kind == MessagingCallKind.video,
    );
    _signals.add('call:$callId');
    return _activeCall!;
  }

  @override
  Future<MessagingCallSessionDto> declineCall(int callId) async {
    _activeCall = _requireCall(callId).copyWith(
      state: MessagingCallState.declined,
      endedAt: _clock(),
      endReason: 'declined',
    );
    _signals.add('call:$callId');
    return _activeCall!;
  }

  @override
  Future<MessagingCallSessionDto> endCall(int callId) async {
    _callTransition?.cancel();
    _activeCall = _requireCall(callId).copyWith(
      state: MessagingCallState.ended,
      endedAt: _clock(),
      endReason: 'ended_by_user',
    );
    _signals.add('call:$callId');
    return _activeCall!;
  }

  @override
  Future<MessagingCallSessionDto> setCallMuted(int callId, bool muted) async {
    _activeCall = _requireCall(callId).copyWith(isMuted: muted);
    _signals.add('call:$callId');
    return _activeCall!;
  }

  @override
  Future<MessagingCallSessionDto> setCallCameraEnabled(
    int callId,
    bool enabled,
  ) async {
    _activeCall = _requireCall(callId).copyWith(isCameraEnabled: enabled);
    _signals.add('call:$callId');
    return _activeCall!;
  }

  @override
  Future<MessagingCallSessionDto> setCallSpeakerEnabled(
    int callId,
    bool enabled,
  ) async {
    _activeCall = _requireCall(callId).copyWith(isSpeakerEnabled: enabled);
    _signals.add('call:$callId');
    return _activeCall!;
  }

  Future<void> _ensureConversation(int id) async {
    if (externalGo && (_mockReferences[id]?.startsWith('go-trip-') ?? false)) {
      throw PlatformException(code: WouandaErrorCode.forbidden);
    }
    await _ensureReady();
    if (!_conversations.any((item) => item.id == id)) {
      throw PlatformException(code: 'MESSAGING_CONVERSATION_NOT_FOUND');
    }
  }

  UnifiedConversationDto _conversation(int id) =>
      _conversations.firstWhere((item) => item.id == id);

  void _replaceConversation(int id, UnifiedConversationDto value) {
    _conversations[_conversations.indexWhere((item) => item.id == id)] = value;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'conversations': _conversations.map((item) => item.toMap()).toList(),
        'messages': {
          for (final entry in _messages.entries)
            entry.key.toString(): entry.value
                .map((item) => item.toMap())
                .toList(),
        },
        'reactions': {
          for (final entry in _reactions.entries)
            entry.key.toString(): entry.value,
        },
        'hidden': _hiddenForMe.toList(),
        'votes': {
          for (final entry in _votes.entries)
            entry.key.toString(): entry.value,
        },
        'spaces': {
          for (final entry in _spaces.entries)
            entry.key.toString(): entry.value,
        },
      }),
    );
  }

  void dispose() {
    _callTransition?.cancel();
    for (final timer in _peerTimers) {
      timer.cancel();
    }
    _signals.close();
  }
}

// Reference aliases exist only in this test double; wire DTO identities are int.
final _mockReferences = <int, String>{};
int mockMessagingId(Object reference) {
  if (reference is int) {
    if (reference >= 1000000000000 && reference < 2000000000000) {
      _mockReferences[reference] = 'go-trip-${reference - 1000000000000}';
    }
    return reference;
  }
  final text = reference.toString();
  // Keep the existing demo thread identity when its context changes from the
  // retired order fixture to an announcement. Subject references are not IDs.
  if (text == 'shop-product-204') {
    const id = 1063294460;
    _mockReferences[id] = text;
    return id;
  }
  final trip = RegExp(r'^go-trip-(\d+)$').firstMatch(text);
  if (trip != null) {
    final id = 1000000000000 + int.parse(trip.group(1)!);
    _mockReferences[id] = text;
    return id;
  }
  var id = 1;
  for (final unit in text.codeUnits) {
    id = (id * 31 + unit) % 2147483647;
  }
  _mockReferences[id] = text;
  return id;
}
