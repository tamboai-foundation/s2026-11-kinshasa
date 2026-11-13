import 'dart:async';

import 'package:flutter/services.dart';

/// What the system draws for one conversation: the unread messages, newest
/// last, as the system's own conversation notification (sender, group,
/// history) with its two actions: answer, mark as read.
class MessageNotificationSpec {
  const MessageNotificationSpec({
    required this.conversationId,
    required this.title,
    required this.isGroup,
    required this.lines,
    this.selfName = 'Vous',
  });

  final int conversationId;
  final String title;
  final bool isGroup;
  final String selfName;
  final List<MessageNotificationLine> lines;

  Map<String, Object?> toMap() => {
    'conversationId': conversationId,
    'title': title,
    'group': isGroup,
    'selfName': selfName,
    'messages': [for (final line in lines) line.toMap()],
  };
}

class MessageNotificationLine {
  const MessageNotificationLine({
    required this.sender,
    required this.text,
    required this.at,
  });
  final String sender;
  final String text;
  final DateTime at;

  Map<String, Object?> toMap() => {
    'sender': sender,
    'text': text,
    'at': at.millisecondsSinceEpoch,
  };
}

/// What the person did in a notification, picked up by the app.
sealed class NotificationAction {
  const NotificationAction(this.conversationId);
  final int conversationId;

  static NotificationAction? fromMap(Map<dynamic, dynamic> map) {
    final rawId = map['conversationId'];
    final conversationId = rawId is int && rawId > 0 ? rawId : null;
    if (conversationId == null) return null;
    return switch (map['type']) {
      'reply' when (map['text'] as String?)?.trim().isNotEmpty ?? false =>
        NotificationReply(
          conversationId,
          (map['text'] as String).trim(),
          map['clientMessageId'] is int ? map['clientMessageId'] as int : null,
        ),
      'read' => NotificationRead(conversationId),
      _ => null,
    };
  }
}

/// An answer typed in the notification. Its [clientMessageId] was made when
/// it was typed, so draining it twice never sends it twice.
class NotificationReply extends NotificationAction {
  const NotificationReply(
    super.conversationId,
    this.text,
    this.clientMessageId,
  );
  final String text;
  final int? clientMessageId;
}

class NotificationRead extends NotificationAction {
  const NotificationRead(super.conversationId);
}

/// Something happened in a notification while the app runs.
sealed class NotificationSignal {
  const NotificationSignal();
}

/// There are actions to drain.
class NotificationActionsWaiting extends NotificationSignal {
  const NotificationActionsWaiting();
}

/// A notification was tapped: show this conversation.
class NotificationOpen extends NotificationSignal {
  const NotificationOpen(this.conversationId);
  final int conversationId;
}

/// The system side of message notifications (contract messaging v4.1). The
/// app asks to show or clear one; the system owns it and answers back
/// through [signals] and [drainActions].
abstract interface class MessagingNotificationSurface {
  Future<bool> allowed();

  /// Asks the system permission to notify. True when granted.
  Future<bool> requestPermission();
  Future<bool> show(MessageNotificationSpec spec);
  Future<void> cancel(int conversationId);
  Future<List<NotificationAction>> drainActions();

  /// The conversation a notification opened the app on, once.
  Future<int?> launchConversation();
  Stream<NotificationSignal> get signals;
}

/// Where there is no system notification to drive (tests, desktop).
class NoMessagingNotifications implements MessagingNotificationSurface {
  const NoMessagingNotifications();
  @override
  Future<bool> allowed() async => false;
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<bool> show(MessageNotificationSpec spec) async => false;
  @override
  Future<void> cancel(int conversationId) async {}
  @override
  Future<List<NotificationAction>> drainActions() async => const [];
  @override
  Future<int?> launchConversation() async => null;
  @override
  Stream<NotificationSignal> get signals => const Stream.empty();
}

/// Contract `com.wouanda/messagingNotifications` (Android: conversation
/// notification with direct reply and mark-as-read actions).
class NativeMessagingNotifications implements MessagingNotificationSurface {
  NativeMessagingNotifications({MethodChannel? channel, EventChannel? events})
    : _channel =
          channel ?? const MethodChannel('com.wouanda/messagingNotifications'),
      _events =
          events ??
          const EventChannel('com.wouanda/messagingNotifications/events');

  final MethodChannel _channel;
  final EventChannel _events;

  Future<T?> _call<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<bool> allowed() async => await _call<bool>('allowed') ?? false;

  @override
  Future<bool> requestPermission() async =>
      await _call<bool>('requestPermission') ?? false;

  @override
  Future<bool> show(MessageNotificationSpec spec) async =>
      await _call<bool>('show', spec.toMap()) ?? false;

  @override
  Future<void> cancel(int conversationId) async {
    await _call<void>('cancel', {'conversationId': conversationId});
  }

  @override
  Future<List<NotificationAction>> drainActions() async {
    final raw = await _call<List<dynamic>>('drainActions') ?? const [];
    return [
      for (final item in raw)
        if (item is Map) ?NotificationAction.fromMap(item),
    ];
  }

  @override
  Future<int?> launchConversation() => _call<int>('launchConversation');

  @override
  Stream<NotificationSignal> get signals => _events
      .receiveBroadcastStream()
      .map<NotificationSignal?>((event) {
        if (event is! Map) return null;
        return switch (event['type']) {
          'actions' => const NotificationActionsWaiting(),
          'open' when event['conversationId'] is int => NotificationOpen(
            event['conversationId'] as int,
          ),
          _ => null,
        };
      })
      .where((signal) => signal != null)
      .cast<NotificationSignal>();
}
