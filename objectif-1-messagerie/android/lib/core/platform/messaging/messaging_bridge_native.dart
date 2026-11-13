import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'messaging_bridge.dart';
import 'messaging_models.dart';
import 'messaging_outbox.dart';
import '../bridge_batch.dart';

/// Shared wire serializer for authoritative messaging ports.
abstract class MessagingBridgeChannel
    implements
        MessagingBridge,
        MessagingCardBridge,
        MessagingInteractiveBridge,
        MessagingSubjectBridge,
        MessagingPaginationBridge {
  MessagingBridgeChannel();
  bool _hasMoreConversations = false;
  final _messageMore = <int, bool>{};
  @override
  bool get hasMoreConversations => _hasMoreConversations;
  @override
  bool hasMoreMessages(int conversationId) =>
      _messageMore[conversationId] ?? false;
  Future<dynamic> invoke(String method, [Map<String, Object?>? args]);

  Future<Map<String, dynamic>> _map(
    String method, [
    Map<String, Object?>? args,
  ]) async => Map<String, dynamic>.from((await invoke(method, args)) as Map);

  Future<List<Map<String, dynamic>>> _list(
    String method, [
    Map<String, Object?>? args,
  ]) async {
    final raw = await invoke(method, args);
    final items = raw is Map ? raw['items'] as List : raw as List;
    final more = raw is Map ? raw['hasMore'] as bool : items.isNotEmpty;
    if (method.endsWith('Conversations')) _hasMoreConversations = more;
    if (method == 'loadMessages' || method == 'loadMoreMessages') {
      _messageMore[args!['conversationId'] as int] = more;
    }
    return [for (final item in items) Map<String, dynamic>.from(item as Map)];
  }

  Future<void> _void(String method, Map<String, Object?> args) =>
      invoke(method, args).then((_) {});

  Future<UnifiedConversationDto> _conversation(
    String method,
    Map<String, Object?> args,
  ) async => UnifiedConversationDto.fromMap(await _map(method, args));

  Future<UnifiedMessageDto> _message(
    String method,
    Map<String, Object?> args,
  ) async => UnifiedMessageDto.fromMap(await _map(method, args));

  Future<List<UnifiedMessageDto>> _messages(
    String method,
    Map<String, Object?> args,
  ) async =>
      (await _list(method, args)).map(UnifiedMessageDto.fromMap).toList();

  Future<MessagingCallSessionDto> _call(
    String method,
    Map<String, Object?> args,
  ) async => MessagingCallSessionDto.fromMap(await _map(method, args));

  @override
  Future<List<UnifiedConversationDto>> loadConversations(
    ConversationQuery query,
  ) async => (await _list('loadConversations', {
    'service': query.service?.name,
    'kind': query.kind?.name,
    'search': query.search,
    'archived': query.archived,
    'unreadOnly': query.unreadOnly,
  })).map(UnifiedConversationDto.fromMap).toList();

  @override
  Future<List<UnifiedConversationDto>> loadMoreConversations() async =>
      (await _list(
        'loadMoreConversations',
      )).map(UnifiedConversationDto.fromMap).toList();

  @override
  Future<List<UnifiedMessageDto>> loadMessages(int conversationId) =>
      _messages('loadMessages', {'conversationId': conversationId});

  @override
  Future<List<UnifiedMessageDto>> loadMoreMessages(int conversationId) =>
      _messages('loadMoreMessages', {'conversationId': conversationId});

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
  }) async => MessageAttachmentDto.fromMap(
    await _map('prepareAttachment', {
      'conversationId': conversationId,
      'sourceUri': sourceUri,
      'type': type,
      'label': label,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'durationMs': durationMs,
      'waveform': waveform,
    }),
  );

  @override
  Future<void> discardAttachment(int conversationId, int attachmentId) => _void(
    'discardAttachment',
    {'conversationId': conversationId, 'attachmentId': attachmentId},
  );

  @override
  Future<UnifiedMessageDto> sendMessage({
    required int conversationId,
    required String text,
    int? clientMessageId,
    int? replyToId,
    List<int> attachmentIds = const [],
  }) => _message('sendMessage', {
    'conversationId': conversationId,
    'text': text,
    'clientMessageId': clientMessageId,
    'replyToId': replyToId,
    'attachmentIds': attachmentIds,
  });

  @override
  Future<UnifiedMessageDto> sendCard({
    required int conversationId,
    required MessageCardDraft draft,
    int? clientMessageId,
  }) => _message('sendCard', {
    'conversationId': conversationId,
    'clientMessageId': clientMessageId,
    'card': draft.toMap(),
  });

  @override
  Future<UnifiedMessageDto> performCardAction({
    required int conversationId,
    required int messageId,
    required String actionId,
  }) => _message('performCardAction', {
    'conversationId': conversationId,
    'messageId': messageId,
    'actionId': actionId,
  });

  @override
  Future<UnifiedMessageDto> sendPoll({
    required int conversationId,
    required String question,
    required List<String> options,
    int? clientMessageId,
  }) => _message('sendPoll', {
    'conversationId': conversationId,
    'question': question,
    'options': options,
    'clientMessageId': clientMessageId,
  });

  @override
  Future<UnifiedMessageDto> votePoll({
    required int conversationId,
    required int messageId,
    required int option,
  }) => _message('votePoll', {
    'conversationId': conversationId,
    'messageId': messageId,
    'option': option,
  });

  @override
  Future<UnifiedMessageDto> sendPost({
    required int conversationId,
    required String text,
    List<int> attachmentIds = const [],
    int? clientMessageId,
  }) => _message('sendPost', {
    'conversationId': conversationId,
    'text': text,
    'attachmentIds': attachmentIds,
    'clientMessageId': clientMessageId,
  });

  @override
  Future<UnifiedConversationDto> openPostSpace({
    required int conversationId,
    required int messageId,
  }) => _conversation('openPostSpace', {
    'conversationId': conversationId,
    'messageId': messageId,
  });

  @override
  Future<int> getUnreadForSubject(MessagingSubjectDto subject) async {
    final raw = await invoke('getUnreadForSubject', {
      'subject': subject.toMap(),
    });
    return (raw as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> markConversationRead(int conversationId) =>
      _void('markConversationRead', {'conversationId': conversationId});

  @override
  Future<UnifiedConversationDto> setMuted(int conversationId, bool muted) =>
      _conversation('setMuted', {
        'conversationId': conversationId,
        'value': muted,
      });

  @override
  Future<UnifiedConversationDto> setArchived(
    int conversationId,
    bool archived,
  ) => _conversation('setArchived', {
    'conversationId': conversationId,
    'value': archived,
  });

  @override
  Future<int> getUnreadCount() async =>
      (await invoke('getUnreadCount') as num?)?.toInt() ?? 0;

  @override
  Future<List<MessagingRecipientDto>> searchRecipients(String query) async =>
      (await _list('searchRecipients', {
        'query': query,
      })).map(MessagingRecipientDto.fromMap).toList();

  @override
  Future<UnifiedConversationDto> openDirectConversation(int recipientId) =>
      _conversation('openDirectConversation', {'recipientId': recipientId});

  @override
  Future<UnifiedConversationDto> openConversation(int conversationId) =>
      _conversation('openConversation', {'conversationId': conversationId});
  @override
  Future<UnifiedConversationDto> resolveConversation(String reference) =>
      _conversation('resolveConversation', {'reference': reference});

  @override
  Future<MessagingCapabilitiesDto> getCapabilities() async =>
      MessagingCapabilitiesDto.fromMap(await _map('getCapabilities'));

  @override
  Future<UnifiedMessageDto> editMessage({
    required int conversationId,
    required int messageId,
    required String text,
  }) => _message('editMessage', {
    'conversationId': conversationId,
    'messageId': messageId,
    'text': text,
  });

  @override
  Future<void> deleteMessage({
    required int conversationId,
    required int messageId,
    required bool forEveryone,
  }) => _void('deleteMessage', {
    'conversationId': conversationId,
    'messageId': messageId,
    'forEveryone': forEveryone,
  });

  @override
  Future<UnifiedMessageDto> reactToMessage({
    required int conversationId,
    required int messageId,
    String? key,
  }) => _message('reactToMessage', {
    'conversationId': conversationId,
    'messageId': messageId,
    'key': key,
  });

  @override
  Future<void> forwardMessage({
    required int conversationId,
    required int messageId,
    required List<int> targetConversationIds,
  }) => _void('forwardMessage', {
    'conversationId': conversationId,
    'messageId': messageId,
    'targetConversationIds': targetConversationIds,
  });

  @override
  Future<UnifiedConversationDto> setPinned(int conversationId, bool pinned) =>
      _conversation('setPinned', {
        'conversationId': conversationId,
        'value': pinned,
      });

  @override
  Future<UnifiedConversationDto> markConversationUnread(int conversationId) =>
      _conversation('markConversationUnread', {
        'conversationId': conversationId,
      });

  @override
  Future<void> saveDraft(int conversationId, String text) =>
      _void('saveDraft', {'conversationId': conversationId, 'text': text});

  @override
  Future<MessagingPeerStatusDto> loadPeerStatus(int conversationId) async =>
      MessagingPeerStatusDto.fromMap(
        await _map('loadPeerStatus', {'conversationId': conversationId}),
      );

  @override
  Future<void> setTyping(int conversationId, bool typing) =>
      _void('setTyping', {'conversationId': conversationId, 'value': typing});

  @override
  Future<UnifiedConversationDto> setBlocked(int conversationId, bool blocked) =>
      _conversation('setBlocked', {
        'conversationId': conversationId,
        'value': blocked,
      });

  @override
  Future<void> reportConversation({
    required int conversationId,
    required String reason,
    int? messageId,
  }) => _void('reportConversation', {
    'conversationId': conversationId,
    'reason': reason,
    'messageId': messageId,
  });

  @override
  Future<List<UnifiedMessageDto>> searchMessages(
    int conversationId,
    String query,
  ) => _messages('searchMessages', {
    'conversationId': conversationId,
    'query': query,
  });

  @override
  Future<MessagingCallSessionDto> startCall(
    int conversationId,
    MessagingCallKind kind,
  ) =>
      _call('startCall', {'conversationId': conversationId, 'kind': kind.name});

  @override
  Future<MessagingCallSessionDto?> loadActiveCall() async {
    final raw = await invoke('loadActiveCall');
    return raw == null
        ? null
        : MessagingCallSessionDto.fromMap(Map<String, dynamic>.from(raw));
  }

  @override
  Future<MessagingCallSessionDto> acceptCall(int callId) =>
      _call('acceptCall', {'callId': callId});

  @override
  Future<MessagingCallSessionDto> declineCall(int callId) =>
      _call('declineCall', {'callId': callId});

  @override
  Future<MessagingCallSessionDto> endCall(int callId) =>
      _call('endCall', {'callId': callId});

  @override
  Future<MessagingCallSessionDto> setCallMuted(int callId, bool muted) =>
      _call('setCallMuted', {'callId': callId, 'value': muted});

  @override
  Future<MessagingCallSessionDto> setCallCameraEnabled(
    int callId,
    bool enabled,
  ) => _call('setCallCameraEnabled', {'callId': callId, 'value': enabled});

  @override
  Future<MessagingCallSessionDto> setCallSpeakerEnabled(
    int callId,
    bool enabled,
  ) => _call('setCallSpeakerEnabled', {'callId': callId, 'value': enabled});
}

/// Native general-messaging port. No simulation fallback on channel failure.
class MessagingBridgeNative extends MessagingBridgeChannel
    implements MessagingUnreadByKindBridge, MessagingOutboxBridge {
  MessagingBridgeNative({this.scope = 'background'});

  /// Presentation list context; never a domain identity or an offset.
  final String scope;
  static const _methods = MethodChannel('com.wouanda/messaging');
  static const _events = EventChannel('com.wouanda/messaging/events');
  static final _signals = _events.receiveBroadcastStream().cast<String>();
  @override
  Stream<String> get eventsStream => _signals;
  @override
  Future<dynamic> invoke(String method, [Map<String, Object?>? args]) async {
    final traced = method == 'sendMessage' || method == 'retryMessage';
    final watch = Stopwatch()..start();
    if (traced) debugPrint('[w.time] canal $method -> natif');
    final raw = await _methods.invokeMethod<dynamic>(method, {
      ...?args,
      'scope': scope,
    });
    if (traced) debugPrint('[w.time] canal $method <- natif après ${watch.elapsedMilliseconds} ms');
    if ({
          'loadConversations',
          'loadMoreConversations',
          'loadMessages',
          'loadMoreMessages',
          'searchMessages',
          'searchRecipients',
          'loadOutbox',
          'loadMoreOutbox',
        }.contains(method) &&
        !(raw is Map && raw['items'] is List && raw['hasMore'] is bool)) {
      throw PlatformException(code: 'MESSAGING_INVALID_RESPONSE');
    }
    return raw;
  }

  @override
  Future<BridgeBatch<UnifiedMessageDto>> loadOutbox({
    bool more = false,
  }) async => BridgeBatch.fromMap(
    await invoke(more ? 'loadMoreOutbox' : 'loadOutbox') as Map,
    UnifiedMessageDto.fromMap,
  );
  @override
  Future<UnifiedMessageDto> retryMessage(
    int conversationId,
    int messageId,
  ) async => UnifiedMessageDto.fromMap(
    Map<String, dynamic>.from(
      await invoke('retryMessage', {
            'conversationId': conversationId,
            'messageId': messageId,
          })
          as Map,
    ),
  );
  @override
  Future<Map<ConversationKind, int>> getUnreadCountsByKind() async {
    final raw =
        await const MethodChannel(
          'com.wouanda/messaging',
        ).invokeMapMethod<String, Object?>('getUnreadCountsByKind') ??
        const {};
    return {
      for (final kind in ConversationKind.values)
        kind: (raw[kind.name] as num?)?.toInt() ?? 0,
    };
  }
}
