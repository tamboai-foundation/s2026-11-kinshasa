import 'package:ngoma/core/widgets/wouanda_draggable_sheet.dart';
import 'package:ngoma/core/widgets/wouanda_conversation.dart';
import 'package:ngoma/core/widgets/wouanda_loading_state.dart';
import 'dart:async';
import 'package:ngoma/core/platform/messaging/messaging_visibility.dart';
import 'package:ngoma/core/widgets/wouanda_chip_rail.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ngoma/core/platform/messaging/messaging_models.dart';
import 'package:ngoma/core/platform/messaging/messaging_quick_replies.dart';
import 'package:ngoma/core/i18n/l10n.dart';
import 'package:ngoma/core/platform/messaging/messaging_bridge.dart';
import 'package:ngoma/core/platform/messaging/messaging_bridge_provider.dart';
import 'package:ngoma/core/providers/messaging_provider.dart';
import 'package:ngoma/core/theme.dart';
import 'package:ngoma/core/widgets/wouanda_platform_widgets.dart';
import 'package:ngoma/features/messaging/buzz_viewer_screen.dart';
import 'package:ngoma/features/messaging/call_screen.dart';
import 'package:ngoma/features/messaging/conversation_actions.dart';
import 'package:ngoma/features/messaging/messaging_input_service.dart';
import 'package:ngoma/features/messaging/conversation_parts.dart';
import 'package:ngoma/features/messaging/service_event_words.dart';
import 'package:ngoma/features/messaging/messaging_document_viewer.dart';
import 'package:ngoma/features/messaging/messaging_media_viewer.dart';
import 'package:ngoma/features/messaging/messaging_service_style.dart';
import 'package:ngoma/features/messaging/poll_post_parts.dart';
import 'package:ngoma/features/messaging/voice_recorder_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:wouanda_design/wouanda_design.dart';

class UnifiedConversationScreen extends ConsumerStatefulWidget {
  final UnifiedConversationDto conversation;
  final String? initialDraft;
  const UnifiedConversationScreen({
    super.key,
    required this.conversation,
    this.initialDraft,
  });
  @override
  ConsumerState<UnifiedConversationScreen> createState() =>
      _UnifiedConversationScreenState();
}

class _UnifiedConversationScreenState
    extends ConsumerState<UnifiedConversationScreen>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final List<MessageAttachmentDto> _attachments = [];
  final Map<int, GlobalKey> _keys = {};

  bool _preparingAttachment = false;
  bool _recordingVoice = false;

  /// v5: the next send is a Buzz (text as description, drafts as media).
  bool _postMode = false;

  /// Typing only rebuilds the screen when the field goes empty or non-empty.
  bool _hadText = false;
  bool _showJump = false;
  UnifiedMessageDto? _replyTo;
  UnifiedMessageDto? _editing;
  int? _highlightId;
  Timer? _highlightTimer;

  int get _id => widget.conversation.id;

  ConversationMessagesNotifier get _notifier =>
      ref.read(conversationMessagesProvider(_id).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.text = widget.initialDraft ?? widget.conversation.draft ?? '';
    _hadText = _controller.text.trim().isNotEmpty;
    _scroll.addListener(_onScroll);
  }

  bool _foreground = true;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _updateVisibility();
  }

  void _updateVisibility() {
    final visible = _foreground && (ModalRoute.of(context)?.isCurrent ?? true);
    _notifier.setVisible(visible);
    if (visible) {
      activeMessagingConversation.value = _id;
    } else if (activeMessagingConversation.value == _id) {
      activeMessagingConversation.value = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _updateVisibility();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (activeMessagingConversation.value == _id) {
      activeMessagingConversation.value = null;
    }
    _highlightTimer?.cancel();
    _scroll.dispose();
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    // Reversed list: the top of the history is the max extent.
    if (position.pixels >= position.maxScrollExtent - 240) {
      unawaited(_notifier.loadOlder());
    }
    final show = position.pixels > 360;
    if (show != _showJump) setState(() => _showJump = show);
  }

  GlobalKey _keyFor(int id) => _keys.putIfAbsent(id, GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationMessagesProvider(_id));
    final conversation = state.conversation ?? widget.conversation;
    final capabilities =
        ref.watch(messagingCapabilitiesProvider).value ??
        MessagingCapabilitiesDto.none;
    bool allows(MessagingFeature feature) =>
        messagingAllows(capabilities, conversation, feature);
    final inputService = ref.watch(messagingInputServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = state.peerStatus;
    final typing = allows(MessagingFeature.typing) && status.isTyping;
    final presence = allows(MessagingFeature.presence)
        ? describePresence(status)
        : null;
    final messages = state.messages;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      appBar: AppBar(
        titleSpacing: 0,
        title: Semantics(
          button: true,
          label: 'Détails de la conversation',
          child: InkWell(
            key: const ValueKey('messaging-conversation-header'),
            onTap: () => _openDetails(conversation, allows, status),
            borderRadius: BorderRadius.circular(WouandaSpacing.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  MessagingAvatar(
                    conversation: conversation,
                    radius: 18,
                    showServiceMark: false,
                    online: presence == 'en ligne',
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                conversation.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (conversation.isMuted) ...[
                              const SizedBox(width: 4),
                              Icon(
                                LucideIcons.bellOff,
                                size: 14,
                                color: AppTheme.getTextSecondary(isDark),
                              ),
                            ],
                          ],
                        ),
                        AnimatedSwitcher(
                          duration: WouandaMotion.duration(
                            context,
                            WouandaMotion.fast,
                          ),
                          child: Text(
                            typing
                                ? (status.typingLabel ?? 'écrit…')
                                : (presence ?? conversation.subtitle),
                            key: ValueKey(typing ? 'typing' : presence),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.caption(
                              color: typing
                                  ? context.palette.accent
                                  : AppTheme.getTextSecondary(isDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          if (conversation.callMethods.contains(MessagingCallKind.audio))
            IconButton(
              tooltip: 'Appel audio',
              onPressed: () =>
                  _startCall(conversation, MessagingCallKind.audio),
              icon: const Icon(LucideIcons.phone),
            ),
          if (conversation.callMethods.contains(MessagingCallKind.video))
            IconButton(
              tooltip: 'Appel vidéo',
              onPressed: () =>
                  _startCall(conversation, MessagingCallKind.video),
              icon: const Icon(LucideIcons.video),
            ),
          IconButton(
            key: const ValueKey('messaging-conversation-more'),
            tooltip: 'Plus d’options',
            onPressed: () => _openDetails(conversation, allows, status),
            icon: const Icon(LucideIcons.ellipsisVertical),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          ConversationContextBanner(
            conversation: conversation,
            onOpen: _contextRoute(conversation) == null
                ? null
                : () => context.push(_contextRoute(conversation)!),
            onRoute: (route) => context.push(route),
          ),
          OutboxBanner(
            waiting: state.messages
                .where((item) => item.delivery == MessageDelivery.queued)
                .length,
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildList(
                    state,
                    messages,
                    conversation,
                    allows,
                    capabilities,
                    typing ? status.typingLabel : null,
                    showTyping: typing,
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: AnimatedScale(
                    scale: _showJump ? 1 : 0,
                    duration: WouandaMotion.duration(
                      context,
                      WouandaMotion.fast,
                    ),
                    child: FloatingActionButton.small(
                      key: const ValueKey('messaging-jump-latest'),
                      heroTag: null,
                      tooltip: 'Derniers messages',
                      backgroundColor: context.palette.surface,
                      foregroundColor: context.palette.accent,
                      elevation: 2,
                      onPressed: _jumpToLatest,
                      child: const Icon(LucideIcons.chevronsDown),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (conversation.canSend &&
              !conversation.isBlocked &&
              conversation.quickReplies.isNotEmpty)
            WouandaChipRail<String>(
              key: const ValueKey('messaging-quick-replies'),
              // Codes from the source (go v1.17), words in the reader's
              // language; the message sent is those words.
              chips: [
                for (final code in conversation.quickReplies)
                  WouandaChip(
                    value: code,
                    label: messagingQuickReplyLabel(
                      context.l10n,
                      code,
                      landmark: conversation.quickReplyParams['landmark'],
                    ),
                  ),
              ],
              selected: null,
              onSelected: (code) {
                if (code != null) {
                  unawaited(
                    _notifier.send(
                      messagingQuickReplyLabel(
                        context.l10n,
                        code,
                        landmark: conversation.quickReplyParams['landmark'],
                      ),
                    ),
                  );
                  _jumpToLatest();
                }
              },
            ),
          if (conversation.canSend && !conversation.isBlocked)
            _buildComposer(state, conversation, inputService)
          else
            _ReadOnlyFooter(
              conversation: conversation,
              onUnblock:
                  conversation.isBlocked && allows(MessagingFeature.block)
                  ? () => _run(() => _notifier.setBlocked(false))
                  : null,
            ),
        ],
      ),
    );
  }

  Widget _buildList(
    ConversationMessagesState state,
    List<UnifiedMessageDto> messages,
    UnifiedConversationDto conversation,
    bool Function(MessagingFeature) allows,
    MessagingCapabilitiesDto capabilities,
    String? typingLabel, {
    required bool showTyping,
  }) {
    if (state.isLoading && messages.isEmpty) {
      return const WouandaLoadingState();
    }
    if (state.error != null && messages.isEmpty) {
      return WouandaEmptyState(
        icon: LucideIcons.messageCircleWarning,
        art: WouandaArt.messages,
        title: 'Messages indisponibles',
        message: 'Vérifiez la connexion puis réessayez.',
        actionLabel: 'Réessayer',
        onAction: _notifier.load,
      );
    }
    if (messages.isEmpty) {
      return WouandaEmptyState(
        icon: LucideIcons.messageCircle,
        art: WouandaArt.messages,
        title: 'Aucun message',
        message: conversation.canSend
            ? 'Envoyez un premier message.'
            : 'Les messages apparaîtront ici.',
      );
    }
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    final group = conversation.kind == ConversationKind.group;
    final entries = <Widget>[];
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final previous = i > 0 ? messages[i - 1] : null;
      final next = i < messages.length - 1 ? messages[i + 1] : null;
      final newDay =
          previous == null || !sameDay(previous.createdAt, message.createdAt);
      bool sameRun(UnifiedMessageDto? other) =>
          other != null &&
          !other.isSystem &&
          other.isMine == message.isMine &&
          other.senderLabel == message.senderLabel &&
          sameDay(other.createdAt, message.createdAt) &&
          message.createdAt.difference(other.createdAt).inMinutes.abs() < 5;
      if (newDay) entries.add(DaySeparator(day: message.createdAt));
      if (message.id == state.firstUnreadId) {
        entries.add(const UnreadDivider());
      }
      if (message.isSystem) {
        entries.add(SystemMessagePill(message: message));
        continue;
      }
      final actions = messageActionsFor(message, allows);
      final canReply =
          allows(MessagingFeature.reply) &&
          !message.isDeleted &&
          message.delivery != MessageDelivery.sending &&
          message.delivery != MessageDelivery.queued &&
          message.delivery != MessageDelivery.failed &&
          conversation.canSend;
      entries.add(
        RepaintBoundary(
          key: _keyFor(message.id),
          child: SwipeToReply(
            onReply: canReply ? () => _startReply(message) : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: () => _openActions(
                message,
                actions,
                allows(MessagingFeature.react) &&
                    !message.isDeleted &&
                    message.delivery != MessageDelivery.sending &&
                    message.delivery != MessageDelivery.queued &&
                    message.delivery != MessageDelivery.failed,
              ),
              child: MessageBubble(
                key: ValueKey('messaging-bubble-${message.id}'),
                message: message,
                firstOfGroup: newDay || !sameRun(previous),
                lastOfGroup: !sameRun(next),
                showSender: group,
                highlighted: message.id == _highlightId,
                onQuoteTap: message.replyTo == null
                    ? null
                    : () => _jumpTo(message.replyTo!.id),
                onReactionTap: allows(MessagingFeature.react)
                    ? (key) => _run(() => _notifier.react(message, key))
                    : null,
                onRetry: () => _run(() => _notifier.retry(message)),
                onCardOpen: _cardRoute(message.card) == null
                    ? null
                    : () => context.push(_cardRoute(message.card)!),
                onCardAction: (actionId) => _answerCard(message, actionId),
                busyCardAction: _cardBusy[message.id],
                onAttachmentTap: (attachment) => openMessagingAttachment(
                  context,
                  attachments: message.attachments,
                  attachment: attachment,
                  caption: message.content,
                ),
                onPollVote: message.isPoll && conversation.canSend
                    ? (option) => _run(() => _notifier.votePoll(message, option))
                    : null,
                onPostOpen: message.isPost ? () => _openPostSpace(message) : null,
              ),
            ),
          ),
        ),
      );
    }
    if (showTyping) {
      entries.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TypingIndicatorBubble(
            key: const ValueKey('messaging-typing'),
            label: typingLabel,
          ),
        ),
      );
    }
    final loader = state.hasOlder ? 1 : 0;
    return ListView.builder(
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: entries.length + loader,
      itemBuilder: (context, index) {
        if (index == entries.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: WouandaBusyBar(size: 22)),
          );
        }
        return entries[entries.length - 1 - index];
      },
    );
  }

  Widget _buildComposer(
    ConversationMessagesState state,
    UnifiedConversationDto conversation,
    MessagingInputService inputService,
  ) {
    final attachMethods = _attachMethods(conversation);
    final context_ = _editing ?? _replyTo;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (context_ != null)
              ComposerContextBanner(
                message: context_,
                editing: _editing != null,
                onClose: _cancelContext,
              ),
            if (_postMode && _editing == null)
              _PostModeBanner(
                onClose: () => setState(() => _postMode = false),
              ),
            if (_attachments.isNotEmpty && _editing == null)
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachments.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final attachment = _attachments[index];
                    return _DraftAttachmentPreview(
                      attachment: attachment,
                      onDelete: () => _discardAttachment(attachment),
                      onOpen:
                          attachment.type == 'voice' ||
                              attachment.type == 'audio'
                          ? null
                          : () => openMessagingAttachment(
                              context,
                              attachments: _attachments,
                              attachment: attachment,
                              caption: _controller.text,
                            ),
                    );
                  },
                ),
              ),
            if (_recordingVoice)
              VoiceRecorderBar(
                key: const ValueKey('messaging-voice-bar'),
                service: inputService,
                onCancel: () => setState(() => _recordingVoice = false),
                onSend: _sendVoice,
                onDenied: () {
                  setState(() => _recordingVoice = false);
                  _showMessage('Autorisez le micro pour enregistrer.');
                },
              )
            else
              WouandaConversationComposer(
                controller: _controller,
                maxLength: conversation.maxTextLength,
                focusNode: _focus,
                hasDraft:
                    _controller.text.trim().isNotEmpty ||
                    (_attachments.isNotEmpty && _editing == null),
                busy: _preparingAttachment,
                canAttach: attachMethods.isNotEmpty && _editing == null,
                canUseCamera:
                    _editing == null &&
                    conversation.inputMethods.contains(
                      MessageInputMethod.camera,
                    ),
                canRecord:
                    _editing == null &&
                    conversation.inputMethods.contains(
                      MessageInputMethod.voice,
                    ),
                sendIcon: _editing == null
                    ? LucideIcons.send
                    : LucideIcons.check,
                sendTooltip: _editing == null ? 'Envoyer' : 'Enregistrer',
                onChanged: () {
                  final hasText = _controller.text.trim().isNotEmpty;
                  if (hasText != _hadText) {
                    _hadText = hasText;
                    setState(() {});
                  }
                  _notifier.composerChanged(_controller.text);
                },
                onAttach: () => _showAttachSheet(conversation, inputService),
                onCamera: () =>
                    _selectInputMethod(MessageInputMethod.camera, inputService),
                onRecord: () {
                  if (_preparingAttachment) return;
                  _focus.unfocus();
                  setState(() => _recordingVoice = true);
                },
                onSend: _send,
              ),
          ],
        ),
      ),
    );
  }

  /// Gallery, document, location: camera and voice have their own buttons.
  List<MessageInputMethod> _attachMethods(
    UnifiedConversationDto conversation,
  ) => [
    for (final method in conversation.inputMethods)
      if (method != MessageInputMethod.camera &&
          method != MessageInputMethod.voice)
        method,
  ];

  /// The action of a card being sent, per message.
  final Map<int, String> _cardBusy = {};

  Future<void> _answerCard(UnifiedMessageDto message, String actionId) async {
    if (_cardBusy.containsKey(message.id)) return;
    HapticFeedback.selectionClick();
    setState(() => _cardBusy[message.id] = actionId);
    await _run(() => _notifier.performCardAction(message, actionId));
    if (mounted) setState(() => _cardBusy.remove(message.id));
  }

  /// A card opens its object only at a destination the app knows: the
  /// service registry is the list (a new service needs nothing here).
  String? _cardRoute(MessageCardDto? card) =>
      messageRouteAllowed(card?.route) ? card!.route : null;

  /// Where « Voir » leads for the conversation's context.
  String? _contextRoute(UnifiedConversationDto conversation) {
    final proposed = conversation.context?.route ?? conversation.contextRoute;
    if (messageRouteAllowed(proposed) || proposed == '/driver') {
      return proposed;
    }
    return switch (conversation.service) {
      MessagingService.go => '/mobility/ride-history',
      MessagingService.shop => '/commerce',
      MessagingService.stay => '/stay',
      MessagingService.events => '/events',
      _ => null,
    };
  }

  // ─── Composer actions ──────────────────────────────────────────────

  void _startReply(UnifiedMessageDto message) {
    HapticFeedback.selectionClick();
    setState(() {
      _replyTo = message;
      if (_editing != null) {
        _editing = null;
        _controller.clear();
      }
    });
    _focus.requestFocus();
  }

  void _startEdit(UnifiedMessageDto message) {
    setState(() {
      _editing = message;
      _replyTo = null;
      _controller.text = message.content;
      _controller.selection = TextSelection.collapsed(
        offset: message.content.length,
      );
    });
    _focus.requestFocus();
  }

  void _cancelContext() {
    setState(() {
      if (_editing != null) _controller.clear();
      _editing = null;
      _replyTo = null;
    });
  }

  Future<void> _send() async {
    final text = _controller.text;
    final editing = _editing;
    if (editing != null) {
      if (text.trim().isEmpty || text.trim() == editing.content) {
        _cancelContext();
        return;
      }
      final done = await _run(() => _notifier.edit(editing, text));
      if (done && mounted) _cancelContext();
      return;
    }
    if (text.trim().isEmpty && _attachments.isEmpty) return;
    final attachments = [..._attachments];
    final replyTo = _replyTo;
    if (_postMode) {
      await _sendPost(text, attachments);
      return;
    }
    // The bubble shows at once; a failure keeps it with « Renvoyer ».
    _controller.clear();
    setState(() {
      _attachments.clear();
      _replyTo = null;
    });
    _jumpToLatest();
    await _notifier.send(text, attachments: attachments, replyTo: replyTo);
  }

  Future<void> _showAttachSheet(
    UnifiedConversationDto conversation,
    MessagingInputService service,
  ) async {
    final capabilities =
        ref.read(messagingCapabilitiesProvider).value ??
        MessagingCapabilitiesDto.none;
    final interactive =
        ref.read(messagingBridgeProvider) is MessagingInteractiveBridge;
    bool allows(MessagingFeature feature) =>
        interactive && messagingAllows(capabilities, conversation, feature);
    final choice = await showWouandaSheet<Object>(
      context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _InputToolsRail(
            methods: [
              for (final method in conversation.inputMethods)
                if (method != MessageInputMethod.voice) method,
            ],
            extras: [
              if (allows(MessagingFeature.poll)) _ExtraTool.poll,
              if (allows(MessagingFeature.post)) _ExtraTool.post,
            ],
            onSelected: (value) => Navigator.pop(sheetContext, value),
          ),
        ),
      ),
    );
    switch (choice) {
      case MessageInputMethod method:
        await _selectInputMethod(method, service);
      case _ExtraTool.poll:
        await _composePoll();
      case _ExtraTool.post:
        setState(() {
          _postMode = true;
          _replyTo = null;
        });
        _focus.requestFocus();
    }
  }

  Future<void> _composePoll() async {
    final poll = await showPollComposer(context);
    if (poll == null || !mounted) return;
    _jumpToLatest();
    final sent = await _notifier.sendPoll(poll.$1, poll.$2);
    if (!sent && mounted) _showMessage('Impossible d’envoyer ce sondage.');
  }

  Future<void> _sendPost(
    String text,
    List<MessageAttachmentDto> attachments,
  ) async {
    _controller.clear();
    setState(() {
      _attachments.clear();
      _postMode = false;
    });
    _jumpToLatest();
    final sent = await _notifier.sendPost(text, attachments: attachments);
    if (!sent && mounted) _showMessage('Impossible de publier ce Buzz.');
  }

  /// A Buzz opens full screen; its comments are its public space.
  Future<void> _openPostSpace(UnifiedMessageDto message) =>
      BuzzViewerScreen.open(
        context,
        conversation:
            ref.read(conversationMessagesProvider(_id)).conversation ??
            widget.conversation,
        post: message,
      );

  Future<void> _selectInputMethod(
    MessageInputMethod method,
    MessagingInputService service,
  ) async {
    if (_preparingAttachment) return;
    try {
      final inputs = switch (method) {
        MessageInputMethod.camera => await service.capturePhoto(),
        MessageInputMethod.gallery => await service.pickMedia(),
        MessageInputMethod.document => await service.pickDocuments(),
        MessageInputMethod.location => await service.pickCurrentLocation(),
        MessageInputMethod.voice => const <MessagingLocalInput>[],
      };
      if (inputs.isEmpty || !mounted) return;
      setState(() => _preparingAttachment = true);
      final bridge = ref.read(messagingBridgeProvider);
      final prepared = <MessageAttachmentDto>[];
      for (final input in inputs) {
        prepared.add(
          await bridge.prepareAttachment(
            conversationId: _id,
            sourceUri: input.sourceUri,
            type: input.type,
            label: input.label,
            mimeType: input.mimeType,
            sizeBytes: input.sizeBytes,
            durationMs: input.durationMs,
            waveform: input.waveform,
          ),
        );
      }
      if (!mounted) return;
      setState(() => _attachments.addAll(prepared));
    } on MessagingInputException catch (error) {
      if (!mounted) return;
      _showMessage(
        error.code == 'LOCATION_SERVICE_DISABLED'
            ? 'Activez la localisation pour partager votre position.'
            : 'Cette autorisation est nécessaire pour continuer.',
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      _showMessage(
        error.code == 'MESSAGING_ATTACHMENT_TOO_LARGE'
            ? 'Ce fichier est trop volumineux.'
            : 'Impossible d’ajouter ce contenu.',
      );
    } on Object {
      if (!mounted) return;
      _showMessage('Impossible d’ajouter ce contenu.');
    } finally {
      if (mounted) setState(() => _preparingAttachment = false);
    }
  }

  /// The arrow of the recorder: prepare the voice note and send it at once.
  Future<void> _sendVoice(MessagingLocalInput input) async {
    final replyTo = _replyTo;
    // The text and media of the draft leave with the voice note, in one
    // message (as in the native app).
    final text = _controller.text;
    final drafts = [..._attachments];
    final postMode = _postMode;
    setState(() {
      _recordingVoice = false;
      _replyTo = null;
    });
    try {
      final voice = await ref
          .read(messagingBridgeProvider)
          .prepareAttachment(
            conversationId: _id,
            sourceUri: input.sourceUri,
            type: input.type,
            label: input.label,
            mimeType: input.mimeType,
            sizeBytes: input.sizeBytes,
            durationMs: input.durationMs,
            waveform: input.waveform,
          );
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _attachments.clear();
        _postMode = false;
      });
      _jumpToLatest();
      if (postMode) {
        await _notifier.sendPost(text, attachments: [...drafts, voice]);
      } else {
        await _notifier.send(
          text,
          attachments: [...drafts, voice],
          replyTo: replyTo,
        );
      }
    } on PlatformException catch (error) {
      if (!mounted) return;
      _showMessage(
        error.code == 'MESSAGING_ATTACHMENT_TOO_LARGE'
            ? 'Ce vocal est trop volumineux.'
            : 'Impossible d’envoyer ce vocal.',
      );
    } on Object {
      if (mounted) _showMessage('Impossible d’envoyer ce vocal.');
    }
  }

  Future<void> _discardAttachment(MessageAttachmentDto attachment) async {
    setState(() => _attachments.remove(attachment));
    try {
      await ref
          .read(messagingBridgeProvider)
          .discardAttachment(_id, attachment.id);
    } on Object {
      if (mounted) _showMessage('Impossible de retirer ce contenu.');
    }
  }

  // ─── Message actions ───────────────────────────────────────────────

  Future<void> _openActions(
    UnifiedMessageDto message,
    List<MessageAction> actions,
    bool canReact,
  ) async {
    if (actions.isEmpty && !canReact) return;
    HapticFeedback.mediumImpact();
    final choice = await showMessageActions(
      context,
      message: message,
      actions: actions,
      canReact: canReact,
    );
    if (choice == null || !mounted) return;
    if (choice.reaction != null) {
      await _run(() => _notifier.react(message, choice.reaction!));
      return;
    }
    switch (choice.action!) {
      case MessageAction.reply:
        _startReply(message);
      case MessageAction.copy:
        await Clipboard.setData(ClipboardData(text: message.content));
        if (mounted) _showMessage('Message copié');
      case MessageAction.edit:
        _startEdit(message);
      case MessageAction.forward:
        final targets = await showForwardSheet(context, excludeId: _id);
        if (targets == null || targets.isEmpty || !mounted) return;
        final done = await _run(() => _notifier.forward(message, targets));
        if (done && mounted) {
          _showMessage(
            targets.length == 1
                ? 'Message transféré'
                : 'Message transféré à ${targets.length} conversations',
          );
        }
      case MessageAction.report:
        final reason = await showReportSheet(context, message: true);
        if (reason == null || !mounted) return;
        final done = await _run(
          () => _notifier.report(reason, message: message),
        );
        if (done && mounted) _showMessage('Signalement envoyé. Merci.');
      case MessageAction.deleteForMe:
      case MessageAction.deleteForEveryone:
        final everyone = choice.action == MessageAction.deleteForEveryone;
        final confirmed = await _confirm(
          title: everyone ? 'Supprimer pour tous ?' : 'Supprimer pour vous ?',
          message: everyone
              ? 'Le message sera remplacé par « Message supprimé » '
                    'chez tous les participants.'
              : 'Le message disparaîtra seulement de votre appareil.',
          action: 'Supprimer',
        );
        if (confirmed != true || !mounted) return;
        await _run(() => _notifier.delete(message, forEveryone: everyone));
      case MessageAction.retry:
        await _run(() => _notifier.retry(message));
      case MessageAction.discard:
        _notifier.discardFailed(message);
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String action,
  }) => showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          key: const ValueKey('messaging-confirm'),
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(foregroundColor: WouandaColors.negative),
          child: Text(action),
        ),
      ],
    ),
  );

  /// Runs a bridge call and explains a refusal; true when it succeeded.
  Future<bool> _run(Future<Object?> Function() call) async {
    try {
      await call();
      return true;
    } on PlatformException catch (error) {
      if (!mounted) return false;
      if (error.code == 'MESSAGING_FEATURE_DISABLED') {
        ref.invalidate(messagingCapabilitiesProvider);
      }
      _showMessage(switch (error.code) {
        'MESSAGING_FEATURE_DISABLED' => 'Cette fonction n’est plus disponible.',
        'MESSAGING_EDIT_WINDOW_EXPIRED' =>
          'Le délai pour modifier ce message est dépassé.',
        'MESSAGING_BLOCKED' => 'Cette conversation est bloquée.',
        'MESSAGING_SEND_FORBIDDEN' =>
          'Vous ne pouvez pas écrire dans cette conversation.',
        _ => 'L’action n’a pas abouti. Réessayez.',
      });
      return false;
    } on Object {
      if (mounted) _showMessage('L’action n’a pas abouti. Réessayez.');
      return false;
    }
  }

  // ─── Navigation in the history ─────────────────────────────────────

  void _jumpToLatest() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: WouandaMotion.duration(context, WouandaMotion.standard),
      curve: WouandaMotion.enterCurve,
    );
  }

  /// Scrolls to [messageId], loading older pages if needed, then flashes it.
  Future<void> _jumpTo(int messageId) async {
    for (var page = 0; page < 10; page++) {
      final loaded = ref
          .read(conversationMessagesProvider(_id))
          .messages
          .any((item) => item.id == messageId);
      if (loaded) break;
      if (!ref.read(conversationMessagesProvider(_id)).hasOlder) break;
      await _notifier.loadOlder();
    }
    if (!mounted) return;
    final motion = WouandaMotion.duration(context, WouandaMotion.standard);
    await WidgetsBinding.instance.endOfFrame;
    var target = _keys[messageId]?.currentContext;
    if (target == null && _scroll.hasClients) {
      // Off-screen in the lazy list: approach it, then align precisely.
      final messages = ref.read(conversationMessagesProvider(_id)).messages;
      final index = messages.indexWhere((item) => item.id == messageId);
      if (index < 0) {
        if (mounted) _showMessage('Ce message n’est plus disponible.');
        return;
      }
      final ratio = 1 - index / messages.length;
      await _scroll.animateTo(
        _scroll.position.maxScrollExtent * ratio,
        duration: motion,
        curve: WouandaMotion.enterCurve,
      );
      await WidgetsBinding.instance.endOfFrame;
      target = _keys[messageId]?.currentContext;
    }
    if (target != null && target.mounted) {
      await Scrollable.ensureVisible(target, alignment: .5, duration: motion);
    }
    if (!mounted) return;
    setState(() => _highlightId = messageId);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _highlightId = null);
    });
  }

  // ─── Conversation details ──────────────────────────────────────────

  Future<void> _openDetails(
    UnifiedConversationDto conversation,
    bool Function(MessagingFeature) allows,
    MessagingPeerStatusDto status,
  ) async {
    final action = await showConversationDetails(
      context,
      conversation: conversation,
      allows: allows,
      status: allows(MessagingFeature.presence)
          ? status
          : MessagingPeerStatusDto.unknown,
      serviceColor: messagingConversationColor(conversation),
      serviceIcon: messagingConversationIcon(conversation),
      canOpenContext: _contextRoute(conversation) != null,
    );
    if (action == null || !mounted) return;
    switch (action) {
      case ConversationDetailAction.search:
        final found = await showConversationSearch(
          context,
          search: _notifier.search,
        );
        if (found != null && mounted) await _jumpTo(found.id);
      case ConversationDetailAction.mute:
      case ConversationDetailAction.unmute:
        final mute = action == ConversationDetailAction.mute;
        if (await _run(() => _notifier.setMuted(mute)) && mounted) {
          _showMessage(
            mute ? 'Conversation en sourdine' : 'Notifications réactivées',
          );
        }
      case ConversationDetailAction.pin:
      case ConversationDetailAction.unpin:
        await _run(
          () => _notifier.setPinned(action == ConversationDetailAction.pin),
        );
      case ConversationDetailAction.archive:
        if (await _run(() => _notifier.setArchived(true)) && mounted) {
          _showMessage('Conversation archivée');
          Navigator.of(context).maybePop();
        }
      case ConversationDetailAction.unarchive:
        await _run(() => _notifier.setArchived(false));
      case ConversationDetailAction.block:
        final confirmed = await _confirm(
          title: 'Bloquer ${conversation.title} ?',
          message:
              'Vous ne recevrez plus ses messages ni ses appels. '
              'Vous pourrez débloquer à tout moment.',
          action: 'Bloquer',
        );
        if (confirmed == true && mounted) {
          await _run(() => _notifier.setBlocked(true));
        }
      case ConversationDetailAction.unblock:
        await _run(() => _notifier.setBlocked(false));
      case ConversationDetailAction.report:
        final reason = await showReportSheet(context);
        if (reason == null || !mounted) return;
        if (await _run(() => _notifier.report(reason)) && mounted) {
          _showMessage('Signalement envoyé. Merci.');
        }
      case ConversationDetailAction.openContext:
        final route = _contextRoute(conversation);
        if (route != null) context.push(route);
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _startCall(
    UnifiedConversationDto conversation,
    MessagingCallKind kind,
  ) async {
    try {
      final call = await ref
          .read(messagingBridgeProvider)
          .startCall(conversation.id, kind);
      if (!mounted) return;
      await MessagingCallScreen.open(
        context,
        call: call,
        title: conversation.title,
      );
    } on Object {
      if (!mounted) return;
      _showMessage('Impossible de démarrer cet appel.');
    }
  }
}

/// Shown instead of the composer when the bridge says one cannot write:
/// a channel, a closed context, or a contact I blocked.
class _ReadOnlyFooter extends StatelessWidget {
  const _ReadOnlyFooter({required this.conversation, this.onUnblock});
  final UnifiedConversationDto conversation;
  final VoidCallback? onUnblock;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final blocked = conversation.isBlocked;
    final closed = messageClosedReasonText(conversation.closedReason);
    final (icon, text) = blocked
        ? (LucideIcons.ban, 'Vous avez bloqué ce contact.')
        : closed != null
        ? (LucideIcons.lock, closed)
        : conversation.kind == ConversationKind.channel
        ? (LucideIcons.megaphone, 'Seuls les administrateurs publient ici.')
        : (LucideIcons.lock, 'Vous ne pouvez pas répondre ici.');
    return SafeArea(
      top: false,
      child: Container(
        key: ValueKey(blocked ? 'messaging-blocked' : 'messaging-read-only'),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
        decoration: BoxDecoration(
          color: WouandaColors.surface(brightness),
          border: Border(
            top: BorderSide(color: WouandaColors.border(brightness)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: blocked
                  ? WouandaColors.negative
                  : WouandaColors.textSecondary(brightness),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                style: AppTheme.bodySm(
                  color: WouandaColors.textSecondary(brightness),
                ),
              ),
            ),
            if (onUnblock != null) ...[
              const SizedBox(width: 8),
              TextButton(onPressed: onUnblock, child: const Text('Débloquer')),
            ],
          ],
        ),
      ),
    );
  }
}

/// What to attach, as in the native messengers: one round, coloured icon per
/// kind, the name small underneath, all in one glance.
class _InputToolsRail extends StatelessWidget {
  const _InputToolsRail({
    required this.methods,
    required this.onSelected,
    this.extras = const [],
  });

  final List<MessageInputMethod> methods;

  /// v5: what else a message can be (poll, Buzz), after the media.
  final List<_ExtraTool> extras;

  /// A [MessageInputMethod] or an [_ExtraTool].
  final ValueChanged<Object> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Wrap(
      alignment: WrapAlignment.spaceEvenly,
      runSpacing: 18,
      spacing: 8,
      children: [
        for (final method in methods)
          _InputTool(method: method, onTap: () => onSelected(method)),
        for (final extra in extras)
          _ToolButton(
            id: extra.name,
            label: extra.label,
            shortLabel: extra.label,
            icon: extra.icon,
            color: extra.color,
            onTap: () => onSelected(extra),
          ),
      ],
    ),
  );
}

/// v5: message kinds offered next to the media, when the conversation
/// allows them.
enum _ExtraTool {
  poll('Sondage', LucideIcons.listChecks, AppTheme.wouandaStay),
  post('Buzz', LucideIcons.flame, AppTheme.wouandaEvents);

  const _ExtraTool(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

/// The banner of a Buzz being written.
class _PostModeBanner extends StatelessWidget {
  const _PostModeBanner({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return Container(
      key: const ValueKey('messaging-post-mode'),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(WouandaSpacing.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.flame, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Buzz : votre texte et vos médias ouvriront un espace de '
              'réactions et de commentaires.',
              style: AppTheme.caption(color: context.palette.textSecondary),
            ),
          ),
          IconButton(
            tooltip: 'Annuler le Buzz',
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: const Icon(LucideIcons.x, size: 18),
          ),
        ],
      ),
    );
  }
}

class _InputTool extends StatelessWidget {
  const _InputTool({required this.method, required this.onTap});
  final MessageInputMethod method;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _ToolButton(
    id: method.name,
    label: _inputMethodLabel(method),
    shortLabel: _inputMethodShortLabel(method),
    icon: _inputMethodIcon(method),
    color: _inputMethodColor(method),
    onTap: onTap,
  );
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String id;
  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        key: ValueKey('messaging-attach-$id'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(WouandaSpacing.radiusLarge),
        child: SizedBox(
          width: 78,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: color),
              ),
              const SizedBox(height: 7),
              Text(
                shortLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.caption(color: context.palette.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Each kind has its own colour, so the eye finds it before reading.
Color _inputMethodColor(MessageInputMethod method) => switch (method) {
  MessageInputMethod.camera => AppTheme.wouandaShop,
  MessageInputMethod.gallery => AppTheme.wouandaLove,
  MessageInputMethod.document => AppTheme.wouandaGo,
  MessageInputMethod.location => AppTheme.success,
  MessageInputMethod.voice => AppTheme.wouandaEvents,
};

class _DraftAttachmentPreview extends StatelessWidget {
  const _DraftAttachmentPreview({
    required this.attachment,
    required this.onDelete,
    this.onOpen,
  });

  final MessageAttachmentDto attachment;
  final VoidCallback onDelete;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final visual = isVisualAttachment(attachment);
    return Container(
      width: visual ? 112 : 172,
      decoration: BoxDecoration(
        color: WouandaColors.surface(brightness),
        borderRadius: BorderRadius.circular(WouandaSpacing.radiusMedium),
        border: Border.all(color: WouandaColors.border(brightness)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (visual)
            MessagingAttachmentPreview(attachment: attachment, onTap: onOpen)
          else
            _AttachmentLabel(attachment: attachment),
          Positioned(
            top: 3,
            right: 3,
            child: IconButton.filled(
              tooltip: 'Retirer',
              onPressed: onDelete,
              icon: const Icon(LucideIcons.x, size: 14),
              style: IconButton.styleFrom(
                minimumSize: const Size.square(28),
                padding: EdgeInsets.zero,
                backgroundColor: context.palette.media.withValues(alpha: .62),
                foregroundColor: context.palette.onAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentLabel extends StatelessWidget {
  const _AttachmentLabel({required this.attachment});
  final MessageAttachmentDto attachment;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 32, 10),
      child: Row(
        children: [
          Icon(
            _attachmentIcon(attachment.type),
            size: 20,
            color: context.palette.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              attachment.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.caption(
                color: WouandaColors.textPrimary(brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _attachmentIcon(String type) => switch (type) {
  'camera' || 'gallery' || 'image' => LucideIcons.image,
  'voice' || 'audio' => LucideIcons.mic,
  'video' => LucideIcons.video,
  _ => LucideIcons.file,
};

IconData _inputMethodIcon(MessageInputMethod method) => switch (method) {
  MessageInputMethod.camera => LucideIcons.camera,
  MessageInputMethod.gallery => LucideIcons.images,
  MessageInputMethod.document => LucideIcons.fileText,
  MessageInputMethod.voice => LucideIcons.mic,
  MessageInputMethod.location => LucideIcons.mapPin,
};

String _inputMethodLabel(MessageInputMethod method) => switch (method) {
  MessageInputMethod.camera => 'Prendre une photo',
  MessageInputMethod.gallery => 'Photos et vidéos',
  MessageInputMethod.document => 'Document',
  MessageInputMethod.voice => 'Message vocal',
  MessageInputMethod.location => 'Position',
};

String _inputMethodShortLabel(MessageInputMethod method) => switch (method) {
  MessageInputMethod.camera => 'Caméra',
  MessageInputMethod.gallery => 'Galerie',
  MessageInputMethod.document => 'Document',
  MessageInputMethod.voice => 'Vocal',
  MessageInputMethod.location => 'Position',
};
