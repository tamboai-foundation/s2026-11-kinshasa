import 'package:flutter/material.dart';
import 'package:ngoma/core/widgets/wouanda_loading_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ngoma/core/widgets/wouanda_error_state.dart';
import 'package:ngoma/core/platform/messaging/messaging_bridge_provider.dart';
import 'package:ngoma/core/platform/messaging/messaging_models.dart';
import 'package:ngoma/features/messaging/unified_conversation_screen.dart';

/// Resolves a service-owned global conversation id through the one messaging
/// bridge, then mounts the same conversation UI used by the global inbox.
final _opening = FutureProvider.autoDispose
    .family<UnifiedConversationDto, Object>((ref, id) {
      final bridge = ref.watch(messagingBridgeProvider);
      final numeric = id is int ? id : int.tryParse(id.toString());
      return numeric == null
          ? bridge.resolveConversation(id.toString())
          : bridge.openConversation(numeric);
    }, retry: (_, _) => null);

class UnifiedConversationLoader extends ConsumerWidget {
  const UnifiedConversationLoader({
    super.key,
    required this.conversationId,
    this.initialDraft,
  });

  final Object conversationId;
  final String? initialDraft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(_opening(conversationId));
    if (!snapshot.isLoading && !snapshot.hasError && snapshot.hasValue) {
      return UnifiedConversationScreen(
        conversation: snapshot.requireValue,
        initialDraft: initialDraft,
      );
    }
    if (snapshot.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: WouandaErrorState(
          icon: LucideIcons.messageCircleWarning,
          title: 'Conversation indisponible',
          message: 'Chargement interrompu.',
          onRetry: () => ref.invalidate(_opening(conversationId)),
        ),
      );
    }
    return const Scaffold(body: WouandaPageLoading());
  }
}
