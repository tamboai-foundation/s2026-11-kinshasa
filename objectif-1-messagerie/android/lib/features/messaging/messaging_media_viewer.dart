import 'dart:async';
import 'package:ngoma/core/widgets/wouanda_loading_state.dart';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:ngoma/core/widgets/wouanda_tappable.dart';
import 'package:ngoma/core/widgets/wouanda_image.dart';
import 'package:ngoma/core/formatting/duration_format.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:ngoma/core/platform/messaging/messaging_models.dart';
import 'package:ngoma/core/theme.dart';
import 'package:wouanda_design/wouanda_design.dart';

bool isVisualAttachment(MessageAttachmentDto attachment) =>
    attachment.type == 'image' || attachment.type == 'video';

String? attachmentSource(MessageAttachmentDto attachment) {
  final source = attachment.mediaUrl ?? attachment.previewUrl;
  return source == null || source.trim().isEmpty ? null : source;
}

bool _isRemote(String source) {
  final uri = Uri.tryParse(source);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

/// Shared visual renderer for drafts, bubbles and the full-screen viewer.
/// It deliberately supports both local paths and remote URLs returned by the
/// messaging bridge.
class MessagingAttachmentPreview extends StatelessWidget {
  const MessagingAttachmentPreview({
    super.key,
    required this.attachment,
    this.onTap,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  final MessageAttachmentDto attachment;
  final VoidCallback? onTap;
  final BoxFit fit;

  /// Decode size for thumbnails; null in the viewer, which must stay sharp.
  final int? cacheWidth;

  /// The thumbnail of a video when the bridge provides one.
  Widget _poster(Widget fallback) {
    final poster = attachment.previewUrl;
    if (poster == null || poster.trim().isEmpty) return fallback;
    return WouandaImage(
      poster,
      fit: fit,
      cacheWidth: cacheWidth,
      fallback: fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = attachmentSource(attachment);
    final fallback = ColoredBox(
      color: context.palette.media,
      child: Center(
        child: Icon(
          attachment.type == 'video' ? LucideIcons.video : LucideIcons.image,
          color: context.palette.onMedia,
          size: 30,
        ),
      ),
    );
    final visual = attachment.type == 'video'
        ? Stack(
            fit: StackFit.expand,
            children: [
              _poster(fallback),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    attachment.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.caption(color: context.palette.onMedia),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.palette.media.withValues(alpha: .62),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.play,
                    color: context.palette.onMedia,
                    size: 24,
                  ),
                ),
              ),
            ],
          )
        : source == null
        ? fallback
        : WouandaImage(
            source,
            fit: fit,
            cacheWidth: cacheWidth,
            fallback: fallback,
          );
    return Semantics(
      button: onTap != null,
      label: attachment.type == 'video'
          ? 'Lire la vidéo ${attachment.label}'
          : 'Voir l’image ${attachment.label}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: visual),
      ),
    );
  }
}

class MessagingMediaViewerScreen extends StatefulWidget {
  const MessagingMediaViewerScreen({
    super.key,
    required this.attachments,
    required this.initialIndex,
    this.caption,
  });

  final List<MessageAttachmentDto> attachments;
  final int initialIndex;
  final String? caption;

  static Future<void> open(
    BuildContext context, {
    required List<MessageAttachmentDto> attachments,
    required MessageAttachmentDto initial,
    String? caption,
  }) {
    final visual = attachments.where(isVisualAttachment).toList();
    final initialIndex = visual.indexWhere((item) => item.id == initial.id);
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => MessagingMediaViewerScreen(
          attachments: visual,
          initialIndex: initialIndex < 0 ? 0 : initialIndex,
          caption: caption,
        ),
      ),
    );
  }

  @override
  State<MessagingMediaViewerScreen> createState() =>
      _MessagingMediaViewerScreenState();
}

class _MessagingMediaViewerScreenState
    extends State<MessagingMediaViewerScreen> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final attachment = widget.attachments[_index];
    final source = attachmentSource(attachment);
    if (source == null) return;
    if (_isRemote(source)) {
      await SharePlus.instance.share(
        ShareParams(text: source, subject: attachment.label),
      );
    } else {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(source)], subject: attachment.label),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachments.isEmpty) {
      return const Scaffold(body: Center(child: Text('Média indisponible')));
    }
    final palette = context.palette;
    final current = widget.attachments[_index];
    return Scaffold(
      backgroundColor: palette.media,
      appBar: AppBar(
        backgroundColor: palette.media,
        foregroundColor: palette.onMedia,
        title: Text('${_index + 1} / ${widget.attachments.length}'),
        actions: [
          IconButton(
            tooltip: 'Partager',
            onPressed: _share,
            icon: const Icon(LucideIcons.share2),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.attachments.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (_, index) {
                  final attachment = widget.attachments[index];
                  return attachment.type == 'video'
                      ? _VideoPage(attachment: attachment)
                      : InteractiveViewer(
                          minScale: .8,
                          maxScale: 5,
                          child: Center(
                            child: MessagingAttachmentPreview(
                              attachment: attachment,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                },
              ),
            ),
            if ((widget.caption ?? '').isNotEmpty || current.label.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                color: palette.media,
                child: Text(
                  (widget.caption ?? '').isNotEmpty
                      ? widget.caption!
                      : current.label,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyMd(color: palette.onMedia),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoPage extends StatefulWidget {
  const _VideoPage({required this.attachment});
  final MessageAttachmentDto attachment;

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  VideoPlayerController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final source = attachmentSource(widget.attachment);
    if (source == null) {
      setState(() => _error = StateError('missing source'));
      return;
    }
    final controller = _isRemote(source)
        ? VideoPlayerController.networkUrl(Uri.parse(source))
        : VideoPlayerController.file(File(source));
    try {
      await controller.initialize();
      await controller.setLooping(false);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      // A video opened to be watched starts at once, as in WhatsApp.
      await controller.play();
    } on Object catch (error) {
      await controller.dispose();
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final palette = context.palette;
    if (_error != null) {
      return Center(
        child: Text(
          'Cette vidéo ne peut pas être lue.',
          style: AppTheme.font(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.palette.onMedia,
          ),
        ),
      );
    }
    if (controller == null) {
      return const WouandaLoadingState();
    }
    return Center(
      child: WouandaTappable(
        onTap: () => setState(() {
          controller.value.isPlaying ? controller.pause() : controller.play();
        }),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
            if (!controller.value.isPlaying)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: palette.scrim,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.play, color: palette.onMedia, size: 30),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 10,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: palette.onMedia,
                  bufferedColor: palette.onMediaMuted.withValues(alpha: 0.54),
                  backgroundColor: palette.onMediaMuted.withValues(alpha: 0.32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A voice note or audio file in a bubble: play, seek on the waveform,
/// speed 1x / 1,5x / 2x. The native player is created on the first play,
/// not when the bubble scrolls into view, so a long history stays light.
class MessagingAudioAttachmentPlayer extends StatefulWidget {
  const MessagingAudioAttachmentPlayer({
    super.key,
    required this.attachment,
    required this.color,
  });

  final MessageAttachmentDto attachment;
  final Color color;

  @override
  State<MessagingAudioAttachmentPlayer> createState() =>
      _MessagingAudioAttachmentPlayerState();
}

class _MessagingAudioAttachmentPlayerState
    extends State<MessagingAudioAttachmentPlayer> {
  static const _speeds = [1.0, 1.5, 2.0];
  static const _speedLabels = ['1x', '1,5x', '2x'];

  AudioPlayer? _player;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _playing = false;
  bool _failed = false;
  bool _loading = false;
  int _speed = 0;
  late Duration _total = Duration(
    milliseconds: widget.attachment.durationMs ?? 0,
  );
  Duration _position = Duration.zero;

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    _player = player;
    _subscriptions
      ..add(
        player.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _playing = false;
              _position = Duration.zero;
            });
          }
        }),
      )
      ..add(
        player.onPositionChanged.listen((value) {
          if (mounted) {
            setState(() {
              _position = value;
              _loading = false;
            });
          }
        }),
      )
      ..add(
        player.onDurationChanged.listen((value) {
          if (mounted && value > Duration.zero) {
            setState(() {
              _total = value;
              _loading = false;
            });
          }
        }),
      );
    return player;
  }

  Future<void> _toggle() async {
    final source = attachmentSource(widget.attachment);
    if (source == null) return;
    try {
      final player = _ensurePlayer();
      if (_playing) {
        await player.pause();
        if (mounted) setState(() => _playing = false);
        return;
      }
      if (_position > Duration.zero && _position < _total) {
        await player.resume();
      } else {
        if (_isRemote(source) && _total == Duration.zero) {
          setState(() => _loading = true);
        }
        await player.play(
          _isRemote(source) ? UrlSource(source) : DeviceFileSource(source),
        );
      }
      await player.setPlaybackRate(_speeds[_speed]);
      if (mounted) setState(() => _playing = true);
    } on Object {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _seek(double fraction) async {
    if (_total == Duration.zero) return;
    final target = _total * fraction.clamp(0.0, 1.0);
    setState(() => _position = target);
    await _player?.seek(target);
  }

  Future<void> _cycleSpeed() async {
    setState(() => _speed = (_speed + 1) % _speeds.length);
    await _player?.setPlaybackRate(_speeds[_speed]);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player?.dispose();
    super.dispose();
  }

  static String _clock(Duration value) => formatClock(value);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final started = _playing || _position > Duration.zero;
    final progress = _total == Duration.zero
        ? 0.0
        : (_position.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 40,
          child: IconButton.filled(
            tooltip: _playing ? 'Pause' : 'Lire le vocal',
            onPressed: _failed ? null : _toggle,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.onAccent,
            ),
            icon: _loading
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.onAccent,
                    ),
                  )
                : Icon(
                    _failed
                        ? LucideIcons.circleAlert
                        : _playing
                        ? LucideIcons.pause
                        : LucideIcons.play,
                    size: 18,
                  ),
          ),
        ),
        const SizedBox(width: 8),
        _SeekableWaveform(
          values: widget.attachment.waveform,
          progress: progress,
          played: palette.accent,
          rest: widget.color.withValues(alpha: .35),
          onSeek: _seek,
        ),
        const SizedBox(width: 8),
        Text(
          _loading
              ? 'Chargement…'
              : (started || _total > Duration.zero)
              ? _clock(started ? _position : _total)
              : 'Prêt à lire',
          style: AppTheme.caption(color: widget.color),
        ),
        if (started) ...[
          const SizedBox(width: 6),
          Semantics(
            button: true,
            label: 'Vitesse de lecture',
            child: InkWell(
              onTap: _cycleSpeed,
              borderRadius: BorderRadius.circular(WouandaSpacing.radiusPill),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  _speedLabels[_speed],
                  style: AppTheme.caption(color: palette.accent),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SeekableWaveform extends StatelessWidget {
  const _SeekableWaveform({
    required this.values,
    required this.progress,
    required this.played,
    required this.rest,
    required this.onSeek,
  });

  final List<double> values;
  final double progress;
  final Color played;
  final Color rest;
  final ValueChanged<double> onSeek;

  static const _width = 132.0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (details) => onSeek(details.localPosition.dx / _width),
    onHorizontalDragUpdate: (details) =>
        onSeek(details.localPosition.dx / _width),
    child: SizedBox(
      width: _width,
      height: 32,
      child: CustomPaint(
        painter: _WaveformPainter(
          values: values,
          progress: progress,
          played: played,
          rest: rest,
        ),
      ),
    ),
  );
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.values,
    required this.progress,
    required this.played,
    required this.rest,
  });

  final List<double> values;
  final double progress;
  final Color played;
  final Color rest;

  static const _bars = 32;

  @override
  void paint(Canvas canvas, Size size) {
    final slot = size.width / _bars;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (slot * .55).clamp(2.0, 3.5);
    for (var i = 0; i < _bars; i++) {
      // A recording without waveform still shows a calm, even rhythm.
      final level = values.isEmpty
          ? .25 + .25 * ((i * 7) % 5) / 4
          : values[(i * values.length / _bars).floor().clamp(
                  0,
                  values.length - 1,
                )]
                .clamp(0.0, 1.0);
      final half = 2 + level * (size.height / 2 - 2);
      final x = slot * i + slot / 2;
      paint.color = (i + .5) / _bars <= progress ? played : rest;
      canvas.drawLine(
        Offset(x, size.height / 2 - half),
        Offset(x, size.height / 2 + half),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress || old.values != values;
}
