import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ngoma/core/widgets/wouanda_sheet_handle.dart';
import 'package:ngoma/core/widgets/wouanda_tappable.dart';
import 'package:wouanda_design/wouanda_design.dart';

/// The panels of a map screen, the Google Maps / Uber way (charter §20):
///
/// * folded by default — the state and the one decision stay in view, the
///   details wait under the handle;
/// * a finger that travels over the map folds them, so the map is free;
/// * the handle opens and closes them (a tap, or a drag up / down).
///
/// The map and its markers follow by themselves: the panel's height is
/// measured by its host (`WouandaSheetMeasure`, `WouandaSnapSheet.onHeight`).
///
/// Three pieces:
/// * [WouandaMapPan] above the map and the panels, with
///   [WouandaMapPanDetector] around the map — « the map is being handled »;
/// * [WouandaFoldScope] above a panel: its folded state;
/// * inside the panel, [WouandaFoldGrip] (the handle) and [WouandaFoldable]
///   around what folds away. What decides (the main button, a code to give,
///   accept / decline) is never inside a [WouandaFoldable].

/// « The map was handled »: a counter every panel of the screen listens to.
class WouandaMapPan extends InheritedNotifier<ValueNotifier<int>> {
  const WouandaMapPan({
    super.key,
    required ValueNotifier<int> super.notifier,
    required super.child,
  });

  static ValueNotifier<int>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WouandaMapPan>()?.notifier;
}

/// Around the map: a finger that travels more than [slop] over it is
/// handling the map (a tap on a marker is not). Told once per gesture, to
/// [onPan] and to the [WouandaMapPan] of the screen.
class WouandaMapPanDetector extends StatefulWidget {
  const WouandaMapPanDetector({
    super.key,
    required this.child,
    this.onPan,
    this.slop = 16,
  });

  final Widget child;
  final VoidCallback? onPan;
  final double slop;

  @override
  State<WouandaMapPanDetector> createState() => _WouandaMapPanDetectorState();
}

class _WouandaMapPanDetectorState extends State<WouandaMapPanDetector> {
  Offset? _down;
  bool _told = false;

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) {
      _down = e.position;
      _told = false;
    },
    onPointerMove: (e) {
      final down = _down;
      if (_told || down == null || (e.position - down).distance < widget.slop) {
        return;
      }
      _told = true;
      widget.onPan?.call();
      final pan = WouandaMapPan.maybeOf(context);
      if (pan != null) pan.value++;
    },
    child: widget.child,
  );
}

/// The folded state of one panel, given to what is inside it.
class WouandaFoldScope extends InheritedWidget {
  const WouandaFoldScope({
    super.key,
    required this.folded,
    required this.onFoldedChanged,
    this.foldable = true,
    required super.child,
  });

  final bool folded;

  /// False when nothing may fold (a decision on screen, nothing under the
  /// handle): the handle is then only the grip.
  final bool foldable;
  final ValueChanged<bool> onFoldedChanged;

  static WouandaFoldScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WouandaFoldScope>();

  @override
  bool updateShouldNotify(WouandaFoldScope old) =>
      folded != old.folded || foldable != old.foldable;
}

/// What a panel folds away: it closes to nothing with a short slide and
/// opens again where it was (its state is kept). Folded, it is neither
/// touched nor read aloud. Without a [WouandaFoldScope] above it, it is
/// simply there.
class WouandaFoldable extends StatelessWidget {
  const WouandaFoldable({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final folded = WouandaFoldScope.maybeOf(context)?.folded ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: folded ? 0 : 1),
      duration: WouandaMotion.duration(context, WouandaMotion.standard),
      curve: WouandaMotion.enterCurve,
      builder: (context, open, child) => ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: open,
          child: Opacity(opacity: open.clamp(0, 1), child: child),
        ),
      ),
      child: IgnorePointer(
        ignoring: folded,
        child: ExcludeSemantics(
          excluding: folded,
          child: ExcludeFocus(excluding: folded, child: child),
        ),
      ),
    );
  }
}

/// The handle of a folding panel: 36 × 4 in a 48 dp target. A tap opens or
/// closes it, a drag up opens it, a drag down folds it. Without a
/// [WouandaFoldScope], it is the plain handle.
class WouandaFoldGrip extends StatelessWidget {
  const WouandaFoldGrip({super.key, this.label = 'Panneau', this.header});

  /// What the panel is, for a screen reader (« Panneau de course »).
  final String label;

  /// The panel's title, joined to the handle: one zone, the bar close to the
  /// text (no empty band), and a tap on the title opens or folds the panel
  /// too. The zone, not the bar alone, is the 48 dp target.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final scope = WouandaFoldScope.maybeOf(context);
    final active = scope != null && scope.foldable;
    if (header == null) {
      // The app's one handle: 36 × 4 in a 48 dp target, a slow drag works
      // as well as a fling.
      return WouandaSheetHandle(
        key: const ValueKey('wouanda-fold-grip'),
        expanded: !(scope?.folded ?? false),
        label: label,
        onToggle: active ? () => scope.onFoldedChanged(!scope.folded) : null,
      );
    }
    final zone = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.palette.border,
              borderRadius: BorderRadius.circular(WouandaSpacing.radiusPill),
            ),
          ),
        ),
        const SizedBox(height: 10),
        header!,
      ],
    );
    if (!active) return zone;
    return Semantics(
      key: const ValueKey('wouanda-fold-grip'),
      button: true,
      label: '$label, ${scope.folded ? 'afficher plus' : 'réduire'}',
      onTap: () => scope.onFoldedChanged(!scope.folded),
      // The shared tap target: tick and press feedback, like every control.
      child: WouandaTappable(
        behavior: HitTestBehavior.opaque,
        scale: 1,
        onTap: () => scope.onFoldedChanged(!scope.folded),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: zone,
        ),
      ),
    );
  }
}

/// Keeps the folded state of a panel and lets the whole panel be moved by
/// the hand, like a native sheet:
///
/// * folded by default ([startFolded]), and again at each new [phase] and
///   when the map is handled;
/// * a drag down anywhere on it folds it — it follows the finger on the
///   way — a drag up opens it; in its list, pulling down from the top folds
///   it and pushing up at the end opens it.
class WouandaFoldHost extends StatefulWidget {
  const WouandaFoldHost({
    super.key,
    required this.phase,
    required this.child,
    this.foldable = true,
    this.startFolded = true,
  });

  /// A new value starts the panel again in its starting state.
  final Object? phase;

  /// False while a decision must stay open (the panel then never folds).
  final bool foldable;

  /// A panel whose content is the choice itself (the kinds of ride) opens
  /// in full; the others start folded.
  final bool startFolded;
  final Widget child;

  @override
  State<WouandaFoldHost> createState() => _WouandaFoldHostState();
}

class _WouandaFoldHostState extends State<WouandaFoldHost> {
  late bool _folded = widget.startFolded;
  ValueNotifier<int>? _pan;

  /// How far the finger has pulled the open panel down (it follows).
  double _pull = 0;
  double _drag = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pan = WouandaMapPan.maybeOf(context);
    if (pan != _pan) {
      _pan?.removeListener(_panned);
      _pan = pan?..addListener(_panned);
    }
  }

  @override
  void didUpdateWidget(covariant WouandaFoldHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase) _folded = widget.startFolded;
  }

  @override
  void dispose() {
    _pan?.removeListener(_panned);
    super.dispose();
  }

  void _panned() {
    if (mounted && !_folded) setState(() => _folded = true);
  }

  void _set(bool folded) {
    if (!widget.foldable || folded == _folded) return;
    HapticFeedback.selectionClick();
    setState(() => _folded = folded);
  }

  void _end(double velocity) {
    final direction = velocity.abs() > 150 ? velocity : _drag;
    if (velocity.abs() > 150 || _drag.abs() >= 24) _set(direction > 0);
    setState(() {
      _drag = 0;
      _pull = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = WouandaFoldScope(
      folded: widget.foldable && _folded,
      foldable: widget.foldable,
      onFoldedChanged: _set,
      child: widget.child,
    );
    if (!widget.foldable) return scope;
    return NotificationListener<OverscrollNotification>(
      // A list inside: past its top, the pull folds the panel; past its end
      // while folded, the push opens it.
      onNotification: (n) {
        if (n.dragDetails == null) return false;
        if (n.overscroll < -4 && !_folded) _set(true);
        if (n.overscroll > 4 && _folded) _set(false);
        return false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (_) => _drag = 0,
        onVerticalDragUpdate: (d) => setState(() {
          _drag += d.delta.dy;
          // Open, the panel follows the finger down (a little resistance).
          _pull = _folded ? 0 : (_drag * .6).clamp(0.0, 120.0);
        }),
        onVerticalDragCancel: () => _end(0),
        onVerticalDragEnd: (d) => _end(d.primaryVelocity ?? 0),
        child: Transform.translate(offset: Offset(0, _pull), child: scope),
      ),
    );
  }
}
