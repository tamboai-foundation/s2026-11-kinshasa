import 'package:flutter/material.dart';

import '../foundations/wouanda_palette.dart';
import '../foundations/wouanda_spacing.dart';
import 'wouanda_motion.dart';

/// Touch feedback of the whole app: the element sinks a little under the
/// thumb and springs back, confirming the touch before anything else happens.
///
/// It listens to the pointer without taking part in the gesture, so it wraps
/// a button, a tile or a card without changing how they react. The shared
/// building blocks (lists, tiles, buttons, chips, tabs, icon actions) already
/// carry it: a screen never adds it by hand to those.
class WouandaPressScale extends StatefulWidget {
  const WouandaPressScale({
    super.key,
    required this.child,
    this.scale = .97,
    this.enabled = true,
  });

  final Widget child;
  final double scale;
  final bool enabled;

  @override
  State<WouandaPressScale> createState() => _WouandaPressScaleState();
}

class _WouandaPressScaleState extends State<WouandaPressScale> {
  bool _down = false;

  void _set(bool value) {
    if (!widget.enabled || _down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down && !WouandaMotion.isReduced(context) ? widget.scale : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// The loading placeholder of the whole app: grey blocks with the shape of
/// what is coming, a light sweeping across them. The screen keeps its layout
/// and the eye keeps its place; no spinner over an empty page.
class WouandaSkeleton extends StatefulWidget {
  const WouandaSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = WouandaSpacing.radiusSmall,
    this.circle = false,
    this.color,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  /// Base of the block; the palette's quiet fill when null. Over a coloured
  /// surface (a button) pass the colour of its label.
  final Color? color;

  @override
  State<WouandaSkeleton> createState() => _WouandaSkeletonState();
}

class _WouandaSkeletonState extends State<WouandaSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WouandaMotion.isReduced(context) ? _sweep.stop() : _sweep.repeat();
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final block = Container(
      width: widget.circle ? widget.height : widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.color ?? palette.border,
        shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.circle
            ? null
            : BorderRadius.circular(widget.radius),
      ),
    );
    if (WouandaMotion.isReduced(context)) return block;
    return AnimatedBuilder(
      animation: _sweep,
      child: block,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          final t = _sweep.value * 2 - .5;
          // The light and its two clear edges share one hue: fading through
          // black (Colors.transparent) would leave grey fringes.
          final light = widget.color == null ? palette.surface : palette.onMedia;
          return LinearGradient(
            begin: Alignment(-1 + t * 2, 0),
            end: Alignment(t * 2, 0),
            colors: [
              light.withValues(alpha: 0),
              light.withValues(alpha: widget.color == null ? .75 : .55),
              light.withValues(alpha: 0),
            ],
          ).createShader(bounds);
        },
        child: child,
      ),
    );
  }
}

/// Rows of a list while it loads: a round visual, two lines, a value.
class WouandaSkeletonRows extends StatelessWidget {
  const WouandaSkeletonRows({super.key, this.rows = 3, this.label});

  final int rows;

  /// Read out by screen readers; the blocks themselves stay silent.
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label ?? 'Chargement en cours',
    liveRegion: true,
    child: ExcludeSemantics(
      child: Column(
        children: [
          for (var i = 0; i < rows; i++)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  WouandaSkeleton(height: 40, circle: true),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WouandaSkeleton(width: 150, height: 14),
                        SizedBox(height: 8),
                        WouandaSkeleton(width: 96, height: 11),
                      ],
                    ),
                  ),
                  WouandaSkeleton(width: 56, height: 14),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

/// The inline « working » mark of the whole app: where a spinner used to sit
/// (in a button, beside a field, in a corner), a short rounded bar shimmers
/// instead. [size] is the height of the space it takes, as the old wheel's
/// diameter; [color] is the colour of the label it replaces.
class WouandaBusyBar extends StatelessWidget {
  const WouandaBusyBar({super.key, this.size = 20, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Chargement en cours',
    liveRegion: true,
    child: ExcludeSemantics(
      child: SizedBox(
        width: size * 2.4,
        height: size,
        child: Center(
          child: WouandaSkeleton(
            width: size * 2.4,
            height: (size * .38).clamp(6, 12),
            radius: 99,
            color: color?.withValues(alpha: .55),
          ),
        ),
      ),
    ),
  );
}
