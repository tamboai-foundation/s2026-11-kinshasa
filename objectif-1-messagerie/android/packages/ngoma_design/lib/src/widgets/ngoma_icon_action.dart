import 'package:flutter/material.dart';
import 'ngoma_feedback.dart';

import '../foundations/ngoma_colors.dart';
import '../foundations/ngoma_spacing.dart';

/// Consistent 48dp icon action used on maps, sheets and application bars.
class NgomaIconAction extends StatelessWidget {
  const NgomaIconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.tonal = false,
    this.overMap = false,
  }) : iconChild = null;

  const NgomaIconAction.custom({
    super.key,
    required this.iconChild,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.tonal = false,
    this.overMap = false,
  }) : icon = null;

  final IconData? icon;
  final Widget? iconChild;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final bool tonal;

  /// On a map: white disc with the soft shadow (Uber, Google Maps), so the
  /// button reads over any tile; a hairline replaces the shadow in dark mode.
  final bool overMap;

  @override
  Widget build(BuildContext context) => NgomaPressScale(
    enabled: onPressed != null,
    scale: .92,
    child: _content(context),
  );

  Widget _content(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = color ?? NgomaColors.textPrimary(brightness);

    final button = Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: tonal
            ? NgomaColors.surfaceMuted(brightness)
            : NgomaColors.surface(brightness),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: iconChild ?? Icon(icon, color: foreground),
          constraints: const BoxConstraints.tightFor(
            width: NgomaSpacing.minimumTouchTarget,
            height: NgomaSpacing.minimumTouchTarget,
          ),
          style: IconButton.styleFrom(
            shape: const CircleBorder(),
            // Over a map the shadow outlines the disc; in dark mode, where
            // shadows vanish, a hairline keeps the button visible.
            side: tonal || (overMap && brightness == Brightness.light)
                ? BorderSide.none
                : BorderSide(color: NgomaColors.border(brightness)),
          ),
        ),
      ),
    );
    if (!overMap) return button;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: NgomaElevation.raised(brightness),
      ),
      child: button,
    );
  }
}
