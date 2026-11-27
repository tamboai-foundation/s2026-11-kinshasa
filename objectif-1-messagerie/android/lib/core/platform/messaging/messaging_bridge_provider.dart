import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'messaging_bridge.dart';
import 'messaging_bridge_native.dart';
import '../../providers/user_provider.dart';

final messagingBridgeProvider = Provider<MessagingBridge>((ref) {
  ref.watch(userProvider.select((user) => (user.id, user.isAuthenticated)));
  return MessagingBridgeNative();
});
