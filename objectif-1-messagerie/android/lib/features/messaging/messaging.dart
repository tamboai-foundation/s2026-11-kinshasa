/// Public UI entry points. Other modules use core/platform/messaging for data.
library;

export 'call_screen.dart' show MessagingCallScreen, IncomingCallHost;
export 'messaging_inbox_screen.dart' show MessagingInboxScreen;
export 'unified_conversation_loader.dart' show UnifiedConversationLoader;
export 'unified_conversation_screen.dart' show UnifiedConversationScreen;

export 'messaging_input_service.dart'
    show MessagingInputService, messagingInputServiceProvider;
export 'share_to_conversation.dart' show shareToConversation;
export 'message_card_view.dart'
    show
        MessageCardView,
        messageCardKindIcon,
        messageCardKindLabel,
        messageCardStatusLabel;
export 'conversation_parts.dart'
    show ConversationContextBanner, OutboxBanner, SystemMessagePill;
export 'messaging_host.dart' show MessagingHost;
export 'service_event_words.dart'
    show
        messageClosedReasonText,
        messageContextActionLabel,
        messageContextStatusLabel,
        messageEventIcon,
        messageEventText,
        messageRouteAllowed;
