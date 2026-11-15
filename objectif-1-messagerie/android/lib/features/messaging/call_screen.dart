import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ngoma/core/formatting/duration_format.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ngoma/core/platform/messaging/messaging_bridge.dart';
import 'package:ngoma/core/platform/messaging/messaging_bridge_provider.dart';
import 'package:ngoma/core/platform/messaging/messaging_models.dart';
import 'package:ngoma/core/theme.dart';
import 'package:wouanda_design/wouanda_design.dart';

bool _isOver(MessagingCallState state) =>
    state == MessagingCallState.ended ||
    state == MessagingCallState.declined ||
    state == MessagingCallState.failed ||
    state == MessagingCallState.missed;

/// Audio and video call. Flutter shows the session and sends the user's
/// intentions; the native side owns media, permissions and routing.
///
/// Outgoing and incoming calls share this screen: an incoming call rings with
/// « Répondre » and « Refuser », then becomes the call in progress.
class MessagingCallScreen extends ConsumerStatefulWidget {
  const MessagingCallScreen({
    super.key,
    required this.call,
    required this.title,
  });
  final MessagingCallSessionDto call;
  final String title;

  /// Opens the call full screen.
  static Future<void> open(
    BuildContext context, {
    required MessagingCallSessionDto call,
    required String title,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => MessagingCallScreen(call: call, title: title),
    ),
  );

  @override
  ConsumerState<MessagingCallScreen> createState() =>
      _MessagingCallScreenState();
}

class _MessagingCallScreenState extends ConsumerState<MessagingCallScreen> {
  late MessagingCallSessionDto call = widget.call;
  StreamSubscription<String>? _signals;
  Timer? _clock;
  bool _acting = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _signals = ref.read(messagingBridgeProvider).eventsStream.listen((signal) {
      if (signal == 'call:${call.id}') _reload();
    });
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && call.state == MessagingCallState.active) setState(() {});
    });
  }

  @override
  void dispose() {
    _signals?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    final next = await ref.read(messagingBridgeProvider).loadActiveCall();
    if (!mounted || next?.id != call.id) return;
    _apply(next!);
  }

  void _apply(MessagingCallSessionDto next) {
    setState(() => call = next);
    if (_isOver(next.state)) _close();
  }

  /// Leaves a moment to read « Appel terminé » before closing.
  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _act(
    Future<MessagingCallSessionDto> Function() action, {
    bool haptic = false,
  }) async {
    if (_acting) return;
    _acting = true;
    if (haptic) HapticFeedback.mediumImpact();
    try {
      final next = await action();
      if (mounted) _apply(next);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cette action n’a pas abouti.')),
        );
      }
    } finally {
      _acting = false;
    }
  }

  MessagingBridge get _bridge => ref.read(messagingBridgeProvider);

  String get _status => switch (call.state) {
    MessagingCallState.ringing =>
      call.kind == MessagingCallKind.video
          ? 'Appel vidéo entrant'
          : 'Appel entrant',
    MessagingCallState.connecting => 'Appel en cours…',
    MessagingCallState.active => _elapsed(),
    MessagingCallState.reconnecting => 'Reconnexion…',
    MessagingCallState.ended => 'Appel terminé',
    MessagingCallState.declined => 'Appel refusé',
    MessagingCallState.missed => 'Appel manqué',
    MessagingCallState.failed => 'Échec de l’appel',
  };

  String _elapsed() {
    final started = call.connectedAt ?? call.startedAt;
    if (started == null) return 'En communication';
    return formatClock(DateTime.now().difference(started));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final video = call.kind == MessagingCallKind.video;
    final remoteRenderer = call.remoteRendererIds.firstOrNull;
    final ringing = call.state == MessagingCallState.ringing;
    final incoming = ringing && call.isIncoming;
    return PopScope(
      canPop: _isOver(call.state),
      child: Scaffold(
        backgroundColor: palette.media,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (video && remoteRenderer != null && !ringing)
              _NativeCallRenderer(rendererId: remoteRenderer)
            else
              _CallBackdrop(title: widget.title),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Text(
                    widget.title,
                    style: AppTheme.h2(color: palette.onMedia),
                  ),
                  const SizedBox(height: 4),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _status,
                      style: AppTheme.bodySm(
                        color: palette.onMedia.withValues(alpha: .78),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (video && call.localRendererId != null && !ringing)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20, bottom: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            WouandaSpacing.radiusLarge,
                          ),
                          child: SizedBox(
                            width: 104,
                            height: 148,
                            child: call.isCameraEnabled
                                ? _NativeCallRenderer(
                                    rendererId: call.localRendererId!,
                                    mirror: true,
                                  )
                                : ColoredBox(
                                    color: palette.onMedia.withValues(
                                      alpha: .12,
                                    ),
                                    child: Icon(
                                      LucideIcons.videoOff,
                                      color: palette.onMedia,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    decoration: BoxDecoration(
                      color: palette.media.withValues(alpha: .76),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(WouandaSpacing.radiusSheet),
                      ),
                    ),
                    child: incoming ? _incomingActions() : _liveActions(video),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _incomingActions() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _CallAction(
        key: const ValueKey('call-decline'),
        icon: LucideIcons.phoneOff,
        label: 'Refuser',
        destructive: true,
        onPressed: () => _act(() => _bridge.declineCall(call.id), haptic: true),
      ),
      _CallAction(
        key: const ValueKey('call-accept'),
        icon: call.kind == MessagingCallKind.video
            ? LucideIcons.video
            : LucideIcons.phone,
        label: 'Répondre',
        positive: true,
        onPressed: () => _act(() => _bridge.acceptCall(call.id), haptic: true),
      ),
    ],
  );

  Widget _liveActions(bool video) {
    final over = _isOver(call.state);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CallAction(
          icon: call.isMuted ? LucideIcons.micOff : LucideIcons.mic,
          label: call.isMuted ? 'Micro coupé' : 'Micro',
          selected: call.isMuted,
          onPressed: over
              ? null
              : () => _act(() => _bridge.setCallMuted(call.id, !call.isMuted)),
        ),
        if (video)
          _CallAction(
            icon: call.isCameraEnabled
                ? LucideIcons.video
                : LucideIcons.videoOff,
            label: call.isCameraEnabled ? 'Caméra' : 'Coupée',
            selected: !call.isCameraEnabled,
            onPressed: over
                ? null
                : () => _act(
                    () => _bridge.setCallCameraEnabled(
                      call.id,
                      !call.isCameraEnabled,
                    ),
                  ),
          ),
        _CallAction(
          icon: LucideIcons.volume2,
          label: 'Haut-parleur',
          selected: call.isSpeakerEnabled,
          onPressed: over
              ? null
              : () => _act(
                  () => _bridge.setCallSpeakerEnabled(
                    call.id,
                    !call.isSpeakerEnabled,
                  ),
                ),
        ),
        _CallAction(
          key: const ValueKey('call-end'),
          icon: LucideIcons.phoneOff,
          label: 'Raccrocher',
          destructive: true,
          onPressed: over
              ? null
              : () => _act(() => _bridge.endCall(call.id), haptic: true),
        ),
      ],
    );
  }
}

/// Watches the messaging bridge for an incoming call and rings the screen
/// above whatever the user is doing, whichever page is open.
class IncomingCallHost extends ConsumerStatefulWidget {
  const IncomingCallHost({
    super.key,
    required this.navigatorKey,
    required this.child,
  });
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  ConsumerState<IncomingCallHost> createState() => _IncomingCallHostState();
}

class _IncomingCallHostState extends ConsumerState<IncomingCallHost> {
  StreamSubscription<String>? _signals;
  int? _shown;

  @override
  void initState() {
    super.initState();
    _signals = ref.read(messagingBridgeProvider).eventsStream.listen((signal) {
      if (signal == 'calls') _check();
    });
  }

  @override
  void dispose() {
    _signals?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    final bridge = ref.read(messagingBridgeProvider);
    final call = await bridge.loadActiveCall();
    if (call == null ||
        !call.isIncoming ||
        call.state != MessagingCallState.ringing ||
        call.id == _shown) {
      return;
    }
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null || !mounted) return;
    _shown = call.id;
    var title = 'Appel entrant';
    try {
      title = (await bridge.openConversation(call.conversationId)).title;
    } on Object {
      // The call still rings without the contact's name.
    }
    if (!mounted) return;
    unawaited(
      navigator.push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => MessagingCallScreen(call: call, title: title),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _CallBackdrop extends StatelessWidget {
  const _CallBackdrop({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          context.palette.accent.withValues(alpha: .55),
          context.palette.media,
        ],
      ),
    ),
    child: Center(
      child: CircleAvatar(
        radius: 58,
        backgroundColor: context.palette.onMedia.withValues(alpha: .14),
        child: Text(
          title.isEmpty ? '?' : title[0].toUpperCase(),
          style: AppTheme.h1(color: context.palette.onMedia),
        ),
      ),
    ),
  );
}

class _NativeCallRenderer extends StatelessWidget {
  const _NativeCallRenderer({required this.rendererId, this.mirror = false});
  final String rendererId;
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return ColoredBox(
        color: context.palette.media,
        child: Center(
          child: Icon(
            LucideIcons.video,
            color: context.palette.onMedia,
            size: 36,
          ),
        ),
      );
    }
    return AndroidView(
      viewType: 'com.wouanda/messaging/call_renderer',
      creationParams: {'rendererId': rendererId, 'mirror': mirror},
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

class _CallAction extends StatelessWidget {
  const _CallAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.destructive = false,
    this.positive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final bool destructive;
  final bool positive;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton.filled(
        tooltip: label,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          minimumSize: const Size.square(56),
          backgroundColor: destructive
              ? WouandaColors.negative
              : positive
              ? context.palette.positive
              : selected
              ? context.palette.onMedia
              : context.palette.onMedia.withValues(alpha: .15),
          foregroundColor: selected && !destructive && !positive
              ? context.palette.media
              : context.palette.onMedia,
        ),
        icon: Icon(icon),
      ),
      const SizedBox(height: 6),
      Text(label, style: AppTheme.caption(color: context.palette.onMedia)),
    ],
  );
}
