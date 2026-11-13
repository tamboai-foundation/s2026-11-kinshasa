import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Gives a small child a larger box: at least [minWidth] × [minHeight], the
/// child centred inside. A child that is already big enough is untouched (it
/// gets the very same constraints and keeps its place), which is what makes
/// it safe around anything, unlike a `ConstrainedBox` + `Align`, which hands
/// the child looser constraints than it was given.
///
/// This is how a 30 dp icon gets a 48 dp tap area without moving a pixel of
/// the drawing.
class WouandaMinSize extends SingleChildRenderObjectWidget {
  const WouandaMinSize({
    super.key,
    this.minWidth = 48,
    this.minHeight = 48,
    super.child,
  });

  final double minWidth;
  final double minHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMinSize(minWidth, minHeight);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderMinSize)
      ..minWidth = minWidth
      ..minHeight = minHeight;
  }
}

class _RenderMinSize extends RenderShiftedBox {
  _RenderMinSize(this._minWidth, this._minHeight) : super(null);

  double _minWidth;
  double _minHeight;

  set minWidth(double value) {
    if (_minWidth == value) return;
    _minWidth = value;
    markNeedsLayout();
  }

  set minHeight(double value) {
    if (_minHeight == value) return;
    _minHeight = value;
    markNeedsLayout();
  }

  Size _grow(BoxConstraints constraints, Size inner) => constraints.constrain(
    Size(math.max(inner.width, _minWidth), math.max(inner.height, _minHeight)),
  );

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(_minWidth, super.computeMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(_minWidth, super.computeMaxIntrinsicWidth(height));

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(_minHeight, super.computeMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(_minHeight, super.computeMaxIntrinsicHeight(width));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return _grow(constraints, Size.zero);
    return _grow(constraints, child.getDryLayout(constraints));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = _grow(constraints, Size.zero);
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = _grow(constraints, child.size);
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(
      Offset(size.width - child.size.width, size.height - child.size.height),
    );
  }
}
