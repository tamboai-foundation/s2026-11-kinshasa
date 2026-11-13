import 'package:flutter/material.dart';
import 'package:wouanda_design/wouanda_design.dart';

/// The small loading mark used inside buttons and next to fields. Not a
/// wheel: a short shimmering bar (`WouandaBusyBar`). With a [value] it draws
/// a determinate bar instead, for a download or an upload.
///
/// The old wheel parameters are kept so every caller keeps compiling; only
/// [size], [color] and [value] matter.
class WouandaLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final Animation<Color>? valueColor;
  final Color? backgroundColor;
  final double? value;
  final StrokeCap? strokeCap;

  const WouandaLoader({
    super.key,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 2.5,
    this.valueColor,
    this.backgroundColor,
    this.value,
    this.strokeCap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.palette.accent;
    return Center(
      child: value == null
          ? WouandaBusyBar(size: size, color: tint)
          : SizedBox(
              width: size * 2.4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(WouandaSpacing.radiusPill),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  color: tint,
                  backgroundColor:
                      backgroundColor ?? tint.withValues(alpha: .2),
                ),
              ),
            ),
    );
  }
}
