import 'package:flutter/material.dart';
import 'ngoma_feedback.dart';

import '../foundations/ngoma_colors.dart';
import '../foundations/ngoma_spacing.dart';

/// Canonical opaque surface used by every NGoma service.
///
/// This deliberately has no blur, translucent fill or decorative gradient.
/// A theme token change here propagates to cards, panels and sheets.
class NgomaSurface extends StatelessWidget {
  const NgomaSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.radius,
    this.showBorder = false,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? radius;
  final bool showBorder;
  final Color? color;

  @override
  Widget build(BuildContext context) => NgomaPressScale(
    enabled: onTap != null,
    scale: .985,
    child: _content(context),
  );

  Widget _content(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final base = radius == null
        ? Theme.of(context).cardTheme.shape ??
              const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(NgomaSpacing.radiusLarge),
                ),
              )
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius!));
    final shape = showBorder && base is OutlinedBorder
        ? base.copyWith(
            side: BorderSide(color: NgomaColors.border(brightness)),
          )
        : base;
    final content = Padding(padding: padding ?? EdgeInsets.zero, child: child);

    // Direction « Apple moderne »: white on #F5F5F7 with a soft shadow.
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          shadows: color == null ? NgomaElevation.card(brightness) : const [],
        ),
        child: Material(
          color: color ?? NgomaColors.surface(brightness),
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: onTap == null
              ? content
              : InkWell(onTap: onTap, customBorder: shape, child: content),
        ),
      ),
    );
  }
}

/// Canonical bottom-sheet shell. The child owns its header and content.
class NgomaSheetSurface extends StatelessWidget {
  const NgomaSheetSurface({
    super.key,
    required this.child,
    this.bottomPadding = 16,
    this.respectBottomSafeArea = true,
  });

  final Widget child;
  final double bottomPadding;

  /// Set false when the parent sheet measures and draws its own system inset.
  final bool respectBottomSafeArea;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: NgomaColors.surface(brightness),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(NgomaSpacing.radiusSheet),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        bottom: respectBottomSafeArea,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: child,
        ),
      ),
    );
  }
}
