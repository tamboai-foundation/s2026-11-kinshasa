import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ngoma/core/formatting/duration_format.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ngoma/core/theme.dart';
import 'package:ngoma/features/messaging/messaging_input_service.dart';
import 'package:wouanda_design/wouanda_design.dart';

/// Voice message recorded where the text field was, as in WhatsApp: one tap
/// on the microphone starts recording, the bin throws it away, the arrow
/// sends it. No intermediate sheet.
///
/// The recording is only ever sent by that explicit arrow.
class VoiceRecorderBar extends StatefulWidget {
  const VoiceRecorderBar({
    super.key,
    required this.service,
    required this.onCancel,
    required this.onSend,
    required this.onDenied,
  });

  final MessagingInputService service;

  /// The bin, or a recording too short to keep.
  final VoidCallback onCancel;

  /// The arrow: the finished recording, ready to prepare and send.
  final ValueChanged<MessagingLocalInput> onSend;

  /// The microphone was refused or could not start.
  final VoidCallback onDenied;

  /// Under this, a recording is a slip of the finger, not a message.
  static const minimum = Duration(milliseconds: 700);

  @override
  State<VoiceRecorderBar> createState() => _VoiceRecorderBarState();
}

class _VoiceRecorderBarState extends State<VoiceRecorderBar> {
  static const _bars = 36;

  StreamSubscription<double>? _levels;
  Timer? _ticker;
  final _started = Stopwatch();
  final _history = <double>[];
  bool _finished = false;
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    _begin();
  }

  Future<void> _begin() async {
    try {
      final allowed = await widget.service.startVoiceRecording();
      if (!mounted) {
        if (allowed) unawaited(widget.service.cancelVoiceRecording());
        return;
      }
      if (!allowed) {
        _finished = true;
        widget.onDenied();
        return;
      }
    } on Object {
      if (!mounted) return;
      _finished = true;
      widget.onDenied();
      return;
    }
    HapticFeedback.mediumImpact();
    _started.start();
    _levels = widget.service.voiceAmplitude.listen((level) {
      if (!mounted) return;
      setState(() {
        _history.add(level);
        if (_history.length > _bars) _history.removeAt(0);
      });
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  Future<void> _cancel() async {
    if (_finished) return;
    _finished = true;
    await widget.service.cancelVoiceRecording();
    if (mounted) widget.onCancel();
  }

  Future<void> _send() async {
    if (_finished || _stopping || !_started.isRunning) return;
    if (_started.elapsed < VoiceRecorderBar.minimum) {
      await _cancel();
      return;
    }
    setState(() => _stopping = true);
    final input = await widget.service.stopVoiceRecording();
    _finished = true;
    if (!mounted) return;
    if (input == null) {
      widget.onCancel();
    } else {
      widget.onSend(input);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _levels?.cancel();
    if (!_finished) unawaited(widget.service.cancelVoiceRecording());
    super.dispose();
  }

  String get _clock => formatClock(_started.elapsed);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            key: const ValueKey('messaging-voice-recorder'),
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.only(left: 4, right: 14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(WouandaSpacing.radiusLarge),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('messaging-voice-cancel'),
                  tooltip: 'Supprimer l’enregistrement',
                  onPressed: _cancel,
                  icon: Icon(
                    LucideIcons.trash2,
                    size: 20,
                    color: palette.negative,
                  ),
                ),
                _RecordingDot(color: palette.negative),
                const SizedBox(width: 8),
                // Always one line: the clock takes the width it needs (a fixed
                // 40 px box broke « 0:05 » in two at large text sizes), with
                // figures of one width so the bar does not jump each second.
                Text(
                  _clock,
                  maxLines: 1,
                  softWrap: false,
                  style: AppTheme.amountSm(color: palette.textPrimary).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: CustomPaint(
                      painter: _LevelsPainter(
                        levels: _history,
                        bars: _bars,
                        color: palette.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox.square(
          dimension: 48,
          child: IconButton.filled(
            key: const ValueKey('messaging-voice-send'),
            tooltip: 'Envoyer le message vocal',
            onPressed: _stopping ? null : _send,
            style: IconButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.onAccent,
            ),
            icon: const Icon(LucideIcons.send, size: 20),
          ),
        ),
      ],
    );
  }
}

class _RecordingDot extends StatefulWidget {
  const _RecordingDot({required this.color});
  final Color color;

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: WouandaMotion.activity,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WouandaMotion.isReduced(context)
        ? _controller.value = 1
        : _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: .35, end: 1).animate(_controller),
    child: Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}

/// The last moments of the sound, newest on the right.
class _LevelsPainter extends CustomPainter {
  _LevelsPainter({
    required this.levels,
    required this.bars,
    required this.color,
  });
  final List<double> levels;
  final int bars;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final slot = size.width / bars;
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (slot * .5).clamp(2.0, 3.5);
    final offset = bars - levels.length;
    for (var i = 0; i < bars; i++) {
      final index = i - offset;
      final level = index < 0 ? 0.0 : levels[index].clamp(0.0, 1.0);
      final half = 2 + level * (size.height / 2 - 2);
      final x = slot * i + slot / 2;
      paint.color = color.withValues(alpha: index < 0 ? .25 : .9);
      canvas.drawLine(
        Offset(x, size.height / 2 - half),
        Offset(x, size.height / 2 + half),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LevelsPainter old) => true;
}
