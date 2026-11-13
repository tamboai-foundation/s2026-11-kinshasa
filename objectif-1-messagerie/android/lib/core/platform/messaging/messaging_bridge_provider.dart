import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'messaging_bridge.dart';
import 'messaging_bridge_mock.dart';
import '../../providers/user_provider.dart';

/// Mock of the UI <-> TModeler messaging bridge. Replace it with an
/// implementation of [MessagingBridge] on top of TModeler (see README.md).
final messagingBridgeProvider = Provider<MessagingBridge>((ref) {
  ref.watch(userProvider.select((user) => (user.id, user.isAuthenticated)));
  return MessagingBridgeMock(simulatePeers: true);
});
