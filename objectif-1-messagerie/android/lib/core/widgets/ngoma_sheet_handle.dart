import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:ngoma_design/ngoma_design.dart';

/// Shared snap gesture: a slow deliberate drag works as well as a fling.
/// The parent owns the state and animates its measured sheet height.
class NgomaSheetHandle extends StatefulWidget {
  const NgomaSheetHandle({
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
  State<NgomaSheetHandle> createState() => _NgomaSheetHandleState();
}

class _NgomaSheetHandleState extends State<NgomaSheetHandle> {
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
          borderRadius: BorderRadius.circular(NgomaSpacing.radiusPill),
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
