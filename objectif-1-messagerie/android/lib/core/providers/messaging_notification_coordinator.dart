import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ngoma/core/platform/messaging/messaging_bridge.dart';
import 'package:ngoma/core/platform/messaging/messaging_models.dart';
import 'package:ngoma/core/platform/messaging/messaging_notifications.dart';
import 'package:ngoma/core/platform/messaging/messaging_outbox.dart';
import 'package:ngoma/core/providers/messaging_provider.dart';

/// The system side of messages (contract messaging v4.1): a notification for
/// what arrived while the app is not in front, answered and marked read from
/// the notification itself, opening the conversation when tapped.
///
/// - The notification follows the unread state of the inbox: it appears when
///   a conversation gets unread messages while the app is behind, it changes
///   with them, and it goes when they are read, wherever that happens.
/// - An answer typed in it goes through the shared outbox: the same
///   `clientMessageId`, in order, and by itself when the connection is back.
/// - Muted, archived and blocked conversations never notify, nor does anything
///   while the app is in front (it tells the person itself).
class MessagingNotificationCoordinator {
  MessagingNotificationCoordinator({
    required this.surface,
    required MessagingBridge Function() bridge,
    required this.outbox,
    required this.onOpen,
    bool Function()? inForeground,
    this.debounce = const Duration(milliseconds: 400),
    this.maxLines = 5,
  }) : _bridge = bridge,
       _inForeground = inForeground ?? _lifecycleForeground;

  final MessagingNotificationSurface surface;
  final MessagingOutbox outbox;
  final void Function(int conversationId) onOpen;
  final Duration debounce;
  final int maxLines;
  final MessagingBridge Function() _bridge;
  final bool Function() _inForeground;

  /// What the system shows for each conversation, to draw it only when it
  /// changes: `unread | last message time`.
  final _shown = <int, String>{};
  StreamSubscription<String>? _bridgeSignals;
  StreamSubscription<NotificationSignal>? _surfaceSignals;
  Timer? _timer;
  bool _syncing = false;
  bool _again = false;
  bool _disposed = false;

  static bool _lifecycleForeground() {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  void _listenToBridge() {
    _bridgeSignals?.cancel();
    _bridgeSignals = _bridge().eventsStream.listen((signal) {
      if (signal == 'conversations' || signal.startsWith('messages:')) {
        schedule();
      }
    });
  }

  /// The account changed, so did the bridge: listen to the new one, and
  /// forget what the old one had shown.
  void rebind() {
    _listenToBridge();
    _shown.clear();
    schedule();
  }

  Future<void> start() async {
    _listenToBridge();
    _surfaceSignals = surface.signals.listen((signal) {
      switch (signal) {
        case NotificationActionsWaiting():
          unawaited(drainActions());
        case NotificationOpen(:final conversationId):
          onOpen(conversationId);
      }
    });
    await drainActions();
    final launch = await surface.launchConversation();
    if (launch != null) onOpen(launch);
    await sync();
  }

  /// The app moved to or from the front.
  void lifecycleChanged() {
    unawaited(drainActions());
    schedule();
  }

  void schedule() {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(sync()));
  }

  /// Draws, updates or clears the notifications to match the inbox.
  Future<void> sync() async {
    if (_disposed) return;
    if (_syncing) {
      _again = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _again = false;
        await _syncOnce();
      } while (_again && !_disposed);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _syncOnce() async {
    List<UnifiedConversationDto> unread;
    try {
      unread = await _bridge().loadConversations(
        const ConversationQuery(unreadOnly: true),
      );
    } on MessagingPartialFailure catch (partial) {
      unread = partial.conversations ?? const [];
    } on Object {
      return;
    }
    final allowed = await surface.allowed();
    final live = <int>{};
    for (final conversation in unread) {
      if (conversation.unreadCount <= 0 ||
          conversation.isMuted ||
          conversation.isArchived ||
          conversation.isBlocked) {
        continue;
      }
      live.add(conversation.id);
      final signature =
          '${conversation.unreadCount}|'
          '${conversation.lastMessageAt?.millisecondsSinceEpoch}';
      if (_shown[conversation.id] == signature) continue;
      // In front, the app tells it itself: remember it as seen, so going
      // behind does not replay what the person has already had.
      // (Behind, even the conversation left open on screen notifies: nobody
      // is looking at it.)
      if (!allowed || _inForeground()) {
        _shown[conversation.id] = signature;
        continue;
      }
      final spec = await _specOf(conversation);
      if (spec == null) continue;
      if (await surface.show(spec)) _shown[conversation.id] = signature;
    }
    // Read somewhere else (the app, another device): the notification goes.
    for (final id in _shown.keys.toList()) {
      if (live.contains(id)) continue;
      _shown.remove(id);
      await surface.cancel(id);
    }
  }

  Future<MessageNotificationSpec?> _specOf(
    UnifiedConversationDto conversation,
  ) async {
    List<UnifiedMessageDto> messages;
    try {
      messages = await _bridge().loadMessages(conversation.id);
    } on Object {
      return null;
    }
    // The unread count covers received messages: walk back over them.
    final lines = <MessageNotificationLine>[];
    for (final message in messages.reversed) {
      if (lines.length >= conversation.unreadCount ||
          lines.length >= maxLines) {
        break;
      }
      if (message.isMine || message.isSystem || message.event != null) continue;
      final text = messagePreview(message);
      if (text.isEmpty) continue;
      lines.insert(
        0,
        MessageNotificationLine(
          sender: message.senderLabel,
          text: text,
          at: message.createdAt,
        ),
      );
    }
    if (lines.isEmpty) return null;
    return MessageNotificationSpec(
      conversationId: conversation.id,
      title: conversation.title,
      isGroup: conversation.kind != ConversationKind.direct,
      lines: lines,
    );
  }

  /// Sends the answers given in notifications and applies the "read" marks.
  Future<void> drainActions() async {
    if (_disposed) return;
    final actions = await surface.drainActions();
    for (final action in actions) {
      switch (action) {
        case NotificationReply():
          // Through the outbox: offline, it waits and leaves by itself.
          await outbox.enqueue(
            conversationId: action.conversationId,
            text: action.text,
            clientMessageId: action.clientMessageId,
          );
          await _markRead(action.conversationId);
        case NotificationRead():
          await _markRead(action.conversationId);
      }
    }
    if (actions.isNotEmpty) schedule();
  }

  Future<void> _markRead(int conversationId) async {
    try {
      await _bridge().markConversationRead(conversationId);
    } on Object {
      // The conversation stays unread; the next opening marks it.
    }
  }

  static const _askedKey = 'messaging_notifications_asked_v1';

  /// Asks the system permission to notify, once, when the person starts
  /// using messages (not at launch, with nothing to show for it).
  Future<void> askPermissionOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_askedKey) ?? false) return;
      if (await surface.allowed()) return;
      await prefs.setBool(_askedKey, true);
      await surface.requestPermission();
    } on Object {
      // No preferences or no system dialog: nothing to ask.
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _bridgeSignals?.cancel();
    _surfaceSignals?.cancel();
  }
}

/// Android has a system notification to drive; elsewhere there is none.
final messagingNotificationSurfaceProvider =
    Provider<MessagingNotificationSurface>(
      (ref) => Platform.isAndroid
          ? NativeMessagingNotifications()
          : const NoMessagingNotifications(),
    );
