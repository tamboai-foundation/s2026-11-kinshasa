import 'dart:async';
import 'package:flutter/foundation.dart';
import 'messaging_bridge.dart';
import 'messaging_models.dart';
import '../bridge_batch.dart';

enum OutboxPhase { sending, waiting, failed }

/// Immutable projection of a native outgoing message, never a Dart queue.
class OutboxItem {
  const OutboxItem(this.message);
  final UnifiedMessageDto message;
  int get id => message.id;
  int get conversationId => message.conversationId;
  String get text => message.content;
  DateTime get createdAt => message.createdAt;
  List<MessageAttachmentDto> get attachments => message.attachments;
  int? get replyToId => message.replyToId;
  MessageQuoteDto? get replyTo => message.replyTo;
  OutboxPhase get phase => switch (message.delivery) {
    MessageDelivery.sending => OutboxPhase.sending,
    MessageDelivery.failed => OutboxPhase.failed,
    _ => OutboxPhase.waiting,
  };
  bool get isPending => phase != OutboxPhase.failed;
  UnifiedMessageDto toMessage(int conversationOf) => message;
}

sealed class OutboxEvent {
  const OutboxEvent(this.conversationId);
  final int conversationId;
}

class OutboxChanged extends OutboxEvent {
  const OutboxChanged(super.conversationId);
}

class OutboxDelivered extends OutboxEvent {
  const OutboxDelivered(super.conversationId, this.message);
  final UnifiedMessageDto message;
}

abstract interface class MessagingOutboxBridge {
  Future<BridgeBatch<UnifiedMessageDto>> loadOutbox({bool more = false});
  Future<UnifiedMessageDto> retryMessage(int conversationId, int messageId);
}

/// View cache and user commands only. Kotlin persists, retries and allocates
/// identities. Losing a response triggers a read, never a second Dart send.
class MessagingOutbox {
  MessagingOutbox({required MessagingBridge Function() bridge})
    : _bridge = bridge {
    _signals = _bridge().eventsStream.listen((key) {
      if (key.startsWith('messages:')) unawaited(restore());
    });
  }
  final MessagingBridge Function() _bridge;
  final _events = StreamController<OutboxEvent>.broadcast();
  late final StreamSubscription<String> _signals;
  List<OutboxItem> _items = const [];
  int _revision = 0;
  bool _closed = false;
  Stream<OutboxEvent> get events => _events.stream;
  List<OutboxItem> itemsFor(int id) =>
      _items.where((item) => item.conversationId == id).toList();
  int get pendingCount => _items.where((item) => item.isPending).length;
  int pendingIn(int id) => itemsFor(id).where((item) => item.isPending).length;
  bool get hasPending => pendingCount > 0;
  Future<void> restore() async {
    final bridge = _bridge();
    if (bridge is! MessagingOutboxBridge) return;
    final revision = ++_revision;
    final BridgeBatch<UnifiedMessageDto> batch;
    try {
      batch = await (bridge as MessagingOutboxBridge).loadOutbox();
    } catch (_) {
      return;
    }
    if (_closed || revision != _revision) return;
    final ids = {
      for (final item in _items) item.conversationId,
      for (final item in batch.items) item.conversationId,
    };
    _items = [for (final message in batch.items) OutboxItem(message)];
    for (final id in ids) {
      _events.add(OutboxChanged(id));
    }
  }

  Future<bool> enqueue({
    required int conversationId,
    required String text,
    List<MessageAttachmentDto> attachments = const [],
    int? replyToId,
    MessageQuoteDto? replyTo,
    int? clientMessageId,
  }) async {
    final watch = Stopwatch()..start();
    void mark(String step) => debugPrint('[w.time] dart envoi +${watch.elapsedMilliseconds} ms | $step');
    mark('enqueue appelé (validation du texte faite)');
    try {
      final message = await _bridge().sendMessage(
        conversationId: conversationId,
        text: text,
        attachmentIds: [for (final a in attachments) a.id],
        replyToId: replyToId,
        clientMessageId: clientMessageId,
      );
      mark('réponse native reçue (message ${message.id}, delivery=${message.delivery})');
      if (!_closed) _events.add(OutboxDelivered(conversationId, message));
      mark('OutboxDelivered émis (bulle mise à jour)');
      await restore();
      mark('restore() terminé');
      return true; // Kotlin owns it, including when its delivery is queued.
    } catch (e) {
      mark('ERREUR $e');
      await restore();
      rethrow;
    }
  }

  Future<bool> retry(int id, {int? conversationId}) async {
    final owner =
        conversationId ??
        _items.where((item) => item.id == id).firstOrNull?.conversationId;
    final bridge = _bridge();
    if (owner == null || bridge is! MessagingOutboxBridge) return false;
    final message = await (bridge as MessagingOutboxBridge).retryMessage(
      owner,
      id,
    );
    if (!_closed) _events.add(OutboxDelivered(owner, message));
    await restore();
    return true;
  }

  Future<void> discard(int id, {int? conversationId}) async {
    final owner =
        conversationId ??
        _items.where((item) => item.id == id).firstOrNull?.conversationId;
    if (owner == null) return;
    await _bridge().deleteMessage(
      conversationId: owner,
      messageId: id,
      forEveryone: false,
    );
    await restore();
  }

  void dispose() {
    _closed = true;
    _signals.cancel();
    _events.close();
  }
}
