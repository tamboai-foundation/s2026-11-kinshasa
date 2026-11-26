import 'package:flutter/material.dart';
import 'ngoma_feedback.dart';

import '../foundations/ngoma_palette.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shared motion timings. Feature screens do not invent their own durations.
abstract final class NgomaMotion {
  static const fast = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 240);
  static const emphasis = Duration(milliseconds: 420);
  static const activity = Duration(milliseconds: 1200);

  static const enterCurve = Curves.easeOutCubic;
  static const exitCurve = Curves.easeInCubic;

  static bool isReduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration duration(BuildContext context, Duration value) =>
      isReduced(context) ? Duration.zero : value;
}

/// Three softly moving dots for an active search.
///
/// Unlike a progress indicator, this does not imply that an operation is
/// blocked or failing. It communicates that the app is listening for a new
/// result and can stay active indefinitely.
class NgomaSearchingDots extends StatefulWidget {
  const NgomaSearchingDots({super.key, this.color, this.dotSize = 6});

  final Color? color;
  final double dotSize;

  @override
  State<NgomaSearchingDots> createState() => _NgomaSearchingDotsState();
}

class _NgomaSearchingDotsState extends State<NgomaSearchingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: NgomaMotion.activity,
  );
  bool? _reduced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = NgomaMotion.isReduced(context);
    if (_reduced == reduced) return;
    _reduced = reduced;
    if (reduced) {
      _controller
        ..stop()
        ..value = 0;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.palette.accent;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < 3; index++) ...[
              if (index > 0) SizedBox(width: widget.dotSize * .7),
              _SearchDot(
                progress: _reduced == true
                    ? .5
                    : (_controller.value - index * .16) % 1,
                color: color,
                size: widget.dotSize,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchDot extends StatelessWidget {
  const _SearchDot({
    required this.progress,
    required this.color,
    required this.size,
  });

  final double progress;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pulse = Curves.easeInOut.transform(
      progress < .5 ? progress * 2 : (1 - progress) * 2,
    );
    return Transform.translate(
      offset: Offset(0, -2.5 * pulse),
      child: Opacity(
        opacity: .48 + .52 * pulse,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: SizedBox.square(dimension: size * (.82 + .18 * pulse)),
        ),
      ),
    );
  }
}

enum NgomaActionState { idle, processing, success }

/// Inline state feedback for actions such as booking, paying and saving.
class NgomaActionFeedback extends StatelessWidget {
  const NgomaActionFeedback({
    super.key,
    required this.state,
    this.size = 18,
    this.color,
  });

  final NgomaActionState state;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? context.palette.onAccent;
    return AnimatedSwitcher(
      duration: NgomaMotion.duration(context, NgomaMotion.standard),
      switchInCurve: NgomaMotion.enterCurve,
      switchOutCurve: NgomaMotion.exitCurve,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: switch (state) {
        NgomaActionState.idle => SizedBox(
          key: const ValueKey('idle'),
          width: size,
          height: size,
        ),
        NgomaActionState.processing => SizedBox(
          key: const ValueKey('processing'),
          width: size,
          height: size,
          child: NgomaBusyBar(size: size, color: resolvedColor),
        ),
        NgomaActionState.success => Icon(
          LucideIcons.check,
          key: const ValueKey('success'),
          size: size,
          color: resolvedColor,
        ),
      },
    );
  }
}

/// A restrained pulse for an ongoing, indeterminate process.
class NgomaActivityPulse extends StatefulWidget {
  const NgomaActivityPulse({
    super.key,
    required this.icon,
    required this.semanticsLabel,
    this.size = 44,
    this.color,
  });

  final IconData icon;
  final String semanticsLabel;
  final double size;
  final Color? color;

  @override
  State<NgomaActivityPulse> createState() => _NgomaActivityPulseState();
}

class _NgomaActivityPulseState extends State<NgomaActivityPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: NgomaMotion.activity,
  );
  bool? _reduced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = NgomaMotion.isReduced(context);
    if (_reduced == reduced) return;
    _reduced = reduced;
    if (reduced) {
      _controller
        ..stop()
        ..value = 0;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.palette.accent;
    return Semantics(
      label: widget.semanticsLabel,
      liveRegion: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = _reduced == true ? 0.0 : _controller.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: (0.28 * (1 - progress)).clamp(0, 1),
                  child: Transform.scale(
                    scale: 0.65 + progress * 0.35,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                      child: SizedBox.square(dimension: widget.size),
                    ),
                  ),
                ),
                Container(
                  width: widget.size * 0.66,
                  height: widget.size * 0.66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.14),
                  ),
                  child: Icon(
                    widget.icon,
                    size: widget.size * 0.36,
                    color: color,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Branded, one-shot confirmation mark shared by every service.
class NgomaSuccessMark extends StatefulWidget {
  const NgomaSuccessMark({
    super.key,
    this.size = 64,
    this.semanticsLabel = 'Confirmation réussie',
  });

  final double size;
  final String semanticsLabel;

  @override
  State<NgomaSuccessMark> createState() => _NgomaSuccessMarkState();
}

class _NgomaSuccessMarkState extends State<NgomaSuccessMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: NgomaMotion.emphasis,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (NgomaMotion.isReduced(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.palette.positive;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    return Semantics(
      label: widget.semanticsLabel,
      liveRegion: true,
      child: FadeTransition(
        opacity: _controller,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.72, end: 1).animate(curved),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(
              LucideIcons.check,
              size: widget.size * 0.5,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Availability of a person or of the user's own activity: green when
/// active, a quiet grey otherwise. [pulse] adds a slow halo for a live state
/// that the user must notice (driver online); lists keep it off to stay calm
/// (charter §18). The halo stops when animations are reduced.
class NgomaPresenceDot extends StatefulWidget {
  const NgomaPresenceDot({
    super.key,
    required this.active,
    this.size = 10,
    this.pulse = false,
    this.ringColor,
  });

  final bool active;
  final double size;
  final bool pulse;

  /// Separates the dot from a photo or avatar it sits on.
  final Color? ringColor;

  @override
  State<NgomaPresenceDot> createState() => _NgomaPresenceDotState();
}

class _NgomaPresenceDotState extends State<NgomaPresenceDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: NgomaMotion.activity,
  );

  bool get _animates => widget.active && widget.pulse;

  void _sync() {
    if (_animates && !NgomaMotion.isReduced(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant NgomaPresenceDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = widget.active ? palette.positive : palette.textTertiary;
    final ring = widget.ringColor;
    final dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: ring == null ? null : Border.all(color: ring, width: 2),
      ),
    );
    if (!_animates) return ExcludeSemantics(child: dot);
    final extent = widget.size * 2.4;
    return ExcludeSemantics(
      child: SizedBox(
        width: extent,
        height: extent,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = Curves.easeOut.transform(_controller.value);
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: widget.size + (extent - widget.size) * t,
                  height: widget.size + (extent - widget.size) * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: .35 * (1 - t)),
                  ),
                ),
                child!,
              ],
            );
          },
          child: dot,
        ),
      ),
    );
  }
}
