import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wouanda_design/wouanda_design.dart';

import 'wouanda_min_size.dart';

/// A custom tap target (a card, an image, a chip drawn by hand) that answers
/// the finger: it presses in slightly, gives a light tick, is at least
/// 48 × 48 dp so a thumb finds it, and is announced as a button. The
/// replacement for a bare `GestureDetector(onTap:)`, which reacts to nothing:
/// the person then wonders whether they touched it.
///
/// Rows, buttons and surfaces of the shared kit already do this themselves
/// (`WouandaListRow`, `WouandaSurface`); use this where the design is custom.
/// Screens never build a tap-only `GestureDetector` (see
/// `test/architecture/tap_feedback_test.dart`).
///
/// A target that holds only an icon or a picture needs a [semanticLabel]: it
/// is what a screen reader says.
class WouandaTappable extends StatelessWidget {
  const WouandaTappable({
    super.key,
    required this.onTap,
    required this.child,
    this.behavior,
    this.scale = .97,
    this.haptic = true,
    this.semanticLabel,
  });

  /// Null makes it inert (no press, no tick).
  final VoidCallback? onTap;
  final Widget child;
  final HitTestBehavior? behavior;
  final double scale;
  final bool haptic;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => WouandaPressScale(
    enabled: onTap != null,
    scale: scale,
    child: Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: GestureDetector(
        // A small drawing still gets a 48 dp tap area: it grows around the
        // child, and the child keeps its own size and place inside.
        behavior: behavior ?? HitTestBehavior.opaque,
        onTap: onTap == null
            ? null
            : () {
                if (haptic) HapticFeedback.selectionClick();
                onTap!();
              },
        child: WouandaMinSize(
          minWidth: WouandaSpacing.minimumTouchTarget,
          minHeight: WouandaSpacing.minimumTouchTarget,
          child: child,
        ),
      ),
    ),
  );
}
