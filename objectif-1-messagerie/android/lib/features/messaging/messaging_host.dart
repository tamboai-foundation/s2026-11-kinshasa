import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ngoma/core/platform/messaging/messaging_bridge_provider.dart';
import 'package:ngoma/core/platform/messaging/messaging_outbox.dart';
import 'package:ngoma/core/providers/messaging_notification_coordinator.dart';
import 'package:ngoma/core/providers/messaging_provider.dart';

/// What messaging does for the whole app, with no screen of its own
/// (contract messaging v4.1):
///
/// - keeps the outbox alive and wakes it when it can act: the network is
///   back, the app comes back to the front. What was written offline then
///   leaves at once, in order, without anyone pressing anything;
/// - keeps the message notifications: shown while the app is behind, answered
///   and marked read from the notification, opening their conversation.
class MessagingHost extends ConsumerStatefulWidget {
  const MessagingHost({
    super.key,
    required this.child,
    required this.onOpenConversation,
  });
  final Widget child;

  /// How a conversation opens (a route): the host does not know the router.
  final void Function(int conversationId) onOpenConversation;

  @override
  ConsumerState<MessagingHost> createState() => _MessagingHostState();
}

class _MessagingHostState extends ConsumerState<MessagingHost>
    with WidgetsBindingObserver {
  StreamSubscription<OutboxEvent>? _written;
  MessagingNotificationCoordinator? _notifications;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Reading it starts it: the previous launch's messages leave now.
    final outbox = ref.read(messagingOutboxProvider);
    _notifications = MessagingNotificationCoordinator(
      surface: ref.read(messagingNotificationSurfaceProvider),
      bridge: () => ref.read(messagingBridgeProvider),
      outbox: outbox,
      onOpen: widget.onOpenConversation,
    );
    unawaited(_notifications!.start());
    // The first message a person sends is the moment to offer to tell them
    // when the answer comes (not at launch, with nothing to show for it).
    _written = outbox.events.listen((event) {
      if (event is OutboxChanged &&
          outbox
              .itemsFor(event.conversationId)
              .any((item) => item.phase == OutboxPhase.sending)) {
        unawaited(_notifications?.askPermissionOnce());
      }
    });
    // The account changed: its own inbox, its own notifications.
    ref.listenManual(messagingBridgeProvider, (_, _) {
      _notifications?.rebind();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _notifications?.lifecycleChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _written?.cancel();
    _notifications?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
