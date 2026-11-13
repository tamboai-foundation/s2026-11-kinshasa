import 'package:flutter/material.dart';
import 'package:ngoma/core/widgets/wouanda_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ngoma/core/platform/messaging/messaging_models.dart';
import 'package:ngoma/core/superapp/wouanda_service_registry.dart';
import 'package:ngoma/core/theme.dart';
import 'package:wouanda_design/wouanda_design.dart';

/// Label, mark and tint of each service in the inbox and conversations.
String messagingServiceLabel(MessagingService value) {
  // Product service names come from the common registry, as in the Hub.
  if (![
    MessagingService.account,
    MessagingService.support,
    MessagingService.other,
  ].contains(value)) {
    for (final service in WouandaServiceRegistry.all) {
      if (service.key == value.name) return service.label;
    }
  }
  return switch (value) {
    MessagingService.support => 'Assistance',
    MessagingService.account => 'Personnel',
    _ => 'Autres',
  };
}

IconData messagingServiceIcon(MessagingService value) => switch (value) {
  MessagingService.shop => LucideIcons.shoppingBag,
  MessagingService.love => LucideIcons.heart,
  MessagingService.stay => LucideIcons.house,
  MessagingService.go => LucideIcons.car,
  MessagingService.events => LucideIcons.ticket,
  MessagingService.support => LucideIcons.headphones,
  MessagingService.account => LucideIcons.userRound,
  MessagingService.other => LucideIcons.messageCircle,
};

Color messagingServiceColor(MessagingService value) => switch (value) {
  MessagingService.shop => AppTheme.wouandaShop,
  MessagingService.love => AppTheme.wouandaLove,
  MessagingService.stay => AppTheme.wouandaStay,
  MessagingService.go => AppTheme.wouandaGo,
  MessagingService.events => AppTheme.wouandaEvents,
  MessagingService.support => WouandaColors.brand,
  MessagingService.account => WouandaColors.brand,
  MessagingService.other => WouandaColors.brand,
};

/// A service the messaging did not know when it was written (`other`) is
/// named and tinted by the service registry from its open key: adding a
/// service touches the registry, never messaging (contract messaging v4).
WouandaServiceDefinition? _registered(UnifiedConversationDto conversation) {
  if (conversation.service != MessagingService.other) return null;
  for (final service in WouandaServiceRegistry.all) {
    if (service.key == conversation.serviceKey) return service;
  }
  return null;
}

String messagingConversationServiceLabel(UnifiedConversationDto c) =>
    _registered(c)?.label ?? messagingServiceLabel(c.service);

IconData messagingConversationIcon(UnifiedConversationDto c) =>
    _registered(c)?.icon ?? messagingServiceIcon(c.service);

Color messagingConversationColor(UnifiedConversationDto c) =>
    _registered(c)?.color ?? messagingServiceColor(c.service);

/// Round avatar: initial on the service tint (12 %), small service mark.
class MessagingAvatar extends StatelessWidget {
  const MessagingAvatar({
    super.key,
    required this.conversation,
    this.radius = 24,
    this.showServiceMark = true,
    this.online = false,
  });

  final UnifiedConversationDto conversation;
  final double radius;
  final bool showServiceMark;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final accent = messagingConversationColor(conversation);
    final size = radius * 2;
    final markSize = (radius * .82).clamp(16.0, 22.0);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          WouandaPersonAvatar(
            radius: radius,
            name: conversation.title,
            photoUrl: conversation.avatarUrl,
            backgroundColor: accent.withValues(alpha: .12),
            foregroundColor: accent,
            placeholder: conversation.kind == ConversationKind.channel
                ? Icon(LucideIcons.megaphone, size: radius * .8, color: accent)
                : conversation.kind == ConversationKind.group
                ? Icon(LucideIcons.users, size: radius * .8, color: accent)
                : null,
          ),
          if (online)
            Positioned(
              right: showServiceMark ? 0 : -1,
              top: showServiceMark ? 0 : null,
              bottom: showServiceMark ? null : -1,
              child: WouandaPresenceDot(
                key: const ValueKey('messaging-online-dot'),
                active: true,
                size: radius * .5,
                ringColor: WouandaColors.surface(brightness),
              ),
            ),
          if (showServiceMark)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: markSize,
                height: markSize,
                decoration: BoxDecoration(
                  color: WouandaColors.surface(brightness),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    messagingConversationIcon(conversation),
                    size: markSize * .5,
                    color: accent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
