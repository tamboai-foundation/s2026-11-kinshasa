import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:wouanda_design/wouanda_design.dart';

/// Shared snap gesture: a slow deliberate drag works as well as a fling.
/// The parent owns the state and animates its measured sheet height.
class WouandaSheetHandle extends StatefulWidget {
  const WouandaSheetHandle({
    super.key,
    this.expanded = true,
    this.onToggle,
    this.label,
  });
  final bool expanded;
  final VoidCallback? onToggle;

  /// What the panel is, for a screen reader (« Disponibilité »); the ride
  /// panel wording otherwise.
  final String? label;
  @override
  State<WouandaSheetHandle> createState() => _WouandaSheetHandleState();
}

class _WouandaSheetHandleState extends State<WouandaSheetHandle> {
  double _distance = 0;
  void _toggle() {
    HapticFeedback.selectionClick();
    widget.onToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    final grip = Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: context.palette.border,
          borderRadius: BorderRadius.circular(WouandaSpacing.radiusPill),
        ),
      ),
    );
    if (widget.onToggle == null) {
      return SizedBox(height: 20, child: grip);
    }
    return GestureDetector(
      dragStartBehavior: DragStartBehavior.down,
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => _distance = 0,
      onVerticalDragUpdate: (details) => _distance += details.delta.dy,
      onVerticalDragCancel: () => _distance = 0,
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        final direction = velocity.abs() > 150 ? velocity : _distance;
        if ((velocity.abs() > 150 || _distance.abs() >= 24) &&
            ((direction < 0 && !widget.expanded) ||
                (direction > 0 && widget.expanded))) {
          _toggle();
        }
        _distance = 0;
      },
      child: Semantics(
        button: true,
        label: widget.label != null
            ? '${widget.label}, ${widget.expanded ? 'réduire' : 'afficher plus'}'
            : widget.expanded
            ? 'Réduire le panneau de course'
            : 'Afficher les détails de la course',
        child: InkWell(
          onTap: _toggle,
          child: SizedBox(height: 48, child: grip),
        ),
      ),
    );
  }
}
