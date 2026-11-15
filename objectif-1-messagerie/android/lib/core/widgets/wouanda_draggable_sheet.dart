import 'package:ngoma/core/widgets/wouanda_fold_panel.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:ngoma/core/widgets/wouanda_tappable.dart';
import 'package:wouanda_design/wouanda_design.dart';

/// The sheets of the whole app follow the finger. Two shapes, one behaviour
/// (charter §20 « Feuilles ») :
///
/// * [showWouandaSheet] — a sheet opened over a screen. It is as high as its
///   content, up to [maxHeightFactor] of the screen. A drag anywhere on it,
///   in its list included, moves it: down it follows the finger and closes,
///   its content only scrolls once it is open in full.
/// * [WouandaSnapSheet] — the permanent panel of a map screen. It rests on
///   heights marked in its content by [WouandaSnapStop], follows the finger
///   between them and snaps to the nearest; its content scrolls only at the
///   top height.
///
/// Both are built on [DraggableScrollableSheet]: the drag and the scroll are
/// one gesture, never two that fight.

/// Opens a sheet that follows the finger. [builder] returns the sheet as
/// before (a [WouandaSheetSurface], a column…); a scroll view inside it with no
/// controller of its own is driven by the sheet, so a drag down from the top of
/// the list closes the sheet instead of bouncing.
Future<T?> showWouandaSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double maxHeightFactor = .92,
  double minHeightFactor = 0,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool? enableDrag,
  bool? showDragHandle,
  Color? backgroundColor,
  RouteSettings? routeSettings,
}) {
  wouandaOpenSheets.value++;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    showDragHandle: showDragHandle,
    // False for a sheet whose content takes the drags itself (a map).
    enableDrag: enableDrag ?? isDismissible,
    backgroundColor: backgroundColor,
    routeSettings: routeSettings,
    builder: (context) => WouandaKeyboardLift(
      child: WouandaDraggableSheet(
        maxHeightFactor: maxHeightFactor,
        minHeightFactor: minHeightFactor,
        closable: enableDrag ?? isDismissible,
        child: Builder(builder: builder),
      ),
    ),
  ).whenComplete(() => wouandaOpenSheets.value--);
}

/// How many sheets are open now: what floats over every screen (the ride
/// follow-up) steps aside while one is up.
final wouandaOpenSheets = ValueNotifier<int>(0);

/// Keeps what is typed in sight: the sheet rises with the keyboard and
/// shrinks to the room left above it, for every sheet of the app. The
/// keyboard is taken into account here, once: inside, the keyboard height
/// reads zero, so a sheet that still pads for it by itself gets no
/// double gap.
class WouandaKeyboardLift extends StatelessWidget {
  const WouandaKeyboardLift({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: child,
    ),
  );
}

/// The body of [showWouandaSheet], usable on its own inside any modal route.
class WouandaDraggableSheet extends StatefulWidget {
  const WouandaDraggableSheet({
    super.key,
    required this.child,
    this.maxHeightFactor = .92,
    this.minHeightFactor = 0,
    this.closable = true,
  });

  final Widget child;
  final double maxHeightFactor;

  /// A floor for sheets whose content changes height (tabs): they keep one
  /// height from tab to tab.
  final double minHeightFactor;
  final bool closable;

  @override
  State<WouandaDraggableSheet> createState() => _WouandaDraggableSheetState();
}

class _WouandaDraggableSheetState extends State<WouandaDraggableSheet> {
  final _controller = DraggableScrollableController();

  /// Share of the available height the content needs; null until measured.
  double? _fit;
  double _available = 0;
  double _content = 0;

  /// The content's own list is longer than its window (its outer list only:
  /// a short list nested in the content does not count).
  bool _listOverflows = false;
  bool _pending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _measured(Size size) {
    _content = size.height;
    _refit();
  }

  bool _scrolled(ScrollMetricsNotification notification) {
    if (notification.depth == 0 && notification.metrics.axis == Axis.vertical) {
      final overflows = notification.metrics.maxScrollExtent > .5;
      if (overflows != _listOverflows) {
        _listOverflows = overflows;
        _refit();
      }
    }
    return false;
  }

  /// Fits the sheet to its content, once per frame.
  void _refit() {
    if (_pending) return;
    _pending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pending = false;
      if (!mounted || _available <= 0) return;
      // Content that overflows its own list asks for the whole height.
      final double want = _listOverflows
          ? widget.maxHeightFactor
          : (_content / _available)
                .clamp(
                  math.min(widget.minHeightFactor, widget.maxHeightFactor),
                  widget.maxHeightFactor,
                )
                .toDouble();
      if (_fit != null && (want - _fit!).abs() < .002) return;
      final grew = _fit != null && want > _fit!;
      setState(() => _fit = want);
      // The sheet was moved already: it follows its content to the new height.
      if (grew && _controller.isAttached) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _controller.isAttached) {
            unawaited(_slide(_controller, want, context));
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The room changes (the keyboard opens or closes): the sheet keeps
        // its height in pixels, so its content is never squeezed under it.
        final room = constraints.maxHeight;
        final fitted = _fit;
        if (_available > 0 &&
            room > 0 &&
            (_available - room).abs() > .5 &&
            fitted != null &&
            !_listOverflows) {
          final kept = (fitted * _available / room)
              .clamp(
                math.min(widget.minHeightFactor, widget.maxHeightFactor),
                widget.maxHeightFactor,
              )
              .toDouble();
          _fit = kept;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                _controller.isAttached &&
                (_controller.size - kept).abs() > .002) {
              _controller.jumpTo(kept);
            }
          });
        }
        _available = room;
        final fit = _fit ?? widget.maxHeightFactor;
        return DraggableScrollableSheet(
          controller: _controller,
          expand: false,
          initialChildSize: fit,
          maxChildSize: fit,
          minChildSize: widget.closable ? 0 : fit,
          snap: true,
          shouldCloseOnMinExtent: widget.closable,
          builder: (context, scroll) => _SheetWindow(
            // The content is laid out with all the room it may take, then
            // the sheet fits it: a list that grows (suggestions under a
            // field) is never handed zero pixels.
            restingHeight: widget.maxHeightFactor * _available,
            scroll: scroll,
            onSize: _measured,
            onScroll: _scrolled,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// The content keeps the layout of the resting height while the sheet moves:
/// it slides out of view with its edge, it is never squeezed.
class _SheetWindow extends StatelessWidget {
  const _SheetWindow({
    required this.restingHeight,
    required this.scroll,
    required this.onSize,
    required this.onScroll,
    required this.child,
  });

  final double restingHeight;
  final ScrollController scroll;
  final ValueChanged<Size> onSize;
  final NotificationListenerCallback<ScrollMetricsNotification> onScroll;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => ClipRect(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: 0,
        maxHeight: math.max(box.maxHeight, restingHeight),
        child: PrimaryScrollController(
          controller: scroll,
          // Any list inside the sheet now moves the sheet first.
          automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
          // Content without a list is dragged by the sheet route itself.
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: onScroll,
            child: _SizeReporter(onSize: onSize, child: child),
          ),
        ),
      ),
    ),
  );
}

class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, super.child});
  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderSizeReporter renderObject,
  ) => renderObject.onSize = onSize;
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);
  ValueChanged<Size> onSize;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (_last != size) {
      _last = size;
      onSize(size);
    }
  }
}

/// Moves a sheet to a height; with reduced motion it is there at once.
Future<void> _slide(
  DraggableScrollableController sheet,
  double to,
  BuildContext context,
) {
  final duration = WouandaMotion.duration(context, WouandaMotion.standard);
  if (duration == Duration.zero) {
    sheet.jumpTo(to);
    return Future.value();
  }
  return sheet.animateTo(
    to,
    duration: duration,
    curve: WouandaMotion.enterCurve,
  );
}

// ─── The permanent panel of a map screen ─────────────────────────────────

/// A height the panel can rest on: everything above the mark is in view.
class WouandaSnapStop extends StatelessWidget {
  const WouandaSnapStop({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Moves a [WouandaSnapSheet] from the code (its handle, « Détails »).
class WouandaSnapSheetController extends ChangeNotifier {
  _WouandaSnapSheetState? _state;

  /// Index of the height the panel rests on (0 = lowest).
  int get level => _state?._level ?? 0;
  int get levels => _state?._sizes.length ?? 0;
  bool get isOpen => levels > 0 && level == levels - 1;

  void goTo(int level) => _state?._goTo(level);
  void _changed() => notifyListeners();
  void open() => goTo(levels - 1);

  /// The usual height: the first stop above the lowest, when there is one.
  void rest() => _state?._goTo(_state!._restLevel);
}

class WouandaSnapSheet extends StatefulWidget {
  const WouandaSnapSheet({
    super.key,
    required this.children,
    this.controller,
    this.maxHeightFactor = .66,
    this.restStop = 0,
    this.lowestStop = 0,
    this.bottomPadding = 0,
    this.onHeight,
    this.handleLabel = 'Panneau',
    this.handleKey = const ValueKey('wouanda-snap-sheet-grip'),
  });

  /// The content, top to bottom, with [WouandaSnapStop] marks.
  final List<Widget> children;
  final WouandaSnapSheetController? controller;

  /// The panel never covers more of the screen (charter: two thirds).
  final double maxHeightFactor;

  /// Which stop the panel opens on and comes back to: the lowest by default
  /// (charter §20, « réduit par défaut » — the map first, details under the
  /// handle). A decision on screen raises [lowestStop] instead.
  final int restStop;

  /// The lowest stop it may fold to (a decision on screen keeps it up).
  final int lowestStop;

  /// Room for the system navigation under the content.
  final double bottomPadding;

  /// The height drawn, in pixels, at every frame: what floats over the map
  /// rides on it.
  final ValueChanged<double>? onHeight;

  /// What the handle says to a screen reader.
  final String handleLabel;

  /// Lets a screen and its tests find the handle.
  final Key handleKey;

  @override
  State<WouandaSnapSheet> createState() => _WouandaSnapSheetState();
}

class _WouandaSnapSheetState extends State<WouandaSnapSheet> {
  final _sheet = DraggableScrollableController();
  final _contentKey = GlobalKey();
  final _stopKeys = <GlobalKey>[];
  double _available = 0;

  /// The map of the screen being handled folds the panel to its lowest
  /// allowed stop (`WouandaMapPan`).
  ValueNotifier<int>? _pan;

  /// Resting heights as shares of the available height, lowest first.
  List<double> _sizes = const [];
  int _level = 0;
  bool _measuring = false;

  int get _restLevel => _sizes.isEmpty
      ? 0
      : (widget.restStop - widget.lowestStop).clamp(0, _sizes.length - 1);

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _sheet.addListener(_moved);
  }

  @override
  void didUpdateWidget(covariant WouandaSnapSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pan = WouandaMapPan.maybeOf(context);
    if (pan != _pan) {
      _pan?.removeListener(_panned);
      _pan = pan?..addListener(_panned);
    }
  }

  void _panned() {
    if (mounted && _level > 0) _goTo(0);
  }

  @override
  void dispose() {
    _pan?.removeListener(_panned);
    if (widget.controller?._state == this) widget.controller?._state = null;
    _sheet.removeListener(_moved);
    _sheet.dispose();
    super.dispose();
  }

  void _moved() {
    if (!_sheet.isAttached) return;
    final pixels = _sheet.pixels;
    if (!pixels.isFinite) return;
    // Resting on a stop: that is the level now (after a drag, a snap, a fling).
    final size = _sheet.size;
    var level = _level;
    for (var i = 0; i < _sizes.length; i++) {
      if ((_sizes[i] - size).abs() < .003) {
        level = i;
        break;
      }
    }
    _tell(() {
      widget.onHeight?.call(pixels);
      if (level != _level) {
        // The grip says « réduire » or « afficher plus ».
        setState(() => _level = level);
        widget.controller?._changed();
      }
    });
  }

  /// The sheet moves during a build too (its sizes replaced): what listens is
  /// told once the frame is drawn, never in the middle of it.
  void _tell(VoidCallback tell) {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      if (mounted) tell();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) tell();
    });
  }

  void _goTo(int level) {
    if (_sizes.isEmpty || !_sheet.isAttached) return;
    final target = level.clamp(0, _sizes.length - 1);
    HapticFeedback.selectionClick();
    setState(() => _level = target);
    unawaited(_slide(_sheet, _sizes[target], context));
    widget.controller?._changed();
  }

  /// Reads the stops off the laid-out content.
  void _measure() {
    if (_measuring) return;
    _measuring = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measuring = false;
      if (!mounted || _available <= 0) return;
      final content =
          _contentKey.currentContext?.findRenderObject() as RenderBox?;
      if (content == null || !content.hasSize) return;
      final top = content.localToGlobal(Offset.zero).dy;
      // The caller may already include the system inset. Count it once,
      // both in the measured stops and in the space actually drawn below.
      final chrome = math.max(
        widget.bottomPadding,
        MediaQuery.paddingOf(context).bottom,
      );
      final max = _available * widget.maxHeightFactor;
      final heights = <double>[
        for (final key in _stopKeys)
          if (key.currentContext?.findRenderObject() case final RenderBox box
              when box.attached)
            box.localToGlobal(Offset.zero).dy - top + chrome,
        content.size.height + chrome,
      ];
      final sizes = <double>[];
      for (final h in heights.skip(widget.lowestStop)) {
        final share = (math.min(h, max) / _available).clamp(.05, 1.0);
        if (sizes.isEmpty || share - sizes.last > .01) sizes.add(share);
      }
      if (sizes.isEmpty) return;
      final changed =
          sizes.length != _sizes.length ||
          [
            for (var i = 0; i < sizes.length; i++) (sizes[i] - _sizes[i]).abs(),
          ].any((d) => d > .002);
      if (!changed) return;
      final first = _sizes.isEmpty;
      setState(() {
        _sizes = sizes;
        _level = first ? _restLevel : _level.clamp(0, sizes.length - 1);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_sheet.isAttached) return;
        // The content changed under a resting panel: it keeps its level.
        unawaited(_slide(_sheet, _sizes[_level], context));
        final pixels = _sheet.pixels;
        if (pixels.isFinite) _tell(() => widget.onHeight?.call(pixels));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var stop = 0;
    final children = <Widget>[];
    for (final child in widget.children) {
      if (child is WouandaSnapStop) {
        if (_stopKeys.length <= stop) _stopKeys.add(GlobalKey());
        children.add(SizedBox(key: _stopKeys[stop], height: 0));
        stop++;
      } else {
        children.add(child);
      }
    }
    if (_stopKeys.length > stop) _stopKeys.removeRange(stop, _stopKeys.length);
    _measure();

    return LayoutBuilder(
      builder: (context, constraints) {
        _available = constraints.maxHeight;
        final sizes = _sizes.isEmpty ? [widget.maxHeightFactor * .5] : _sizes;
        final initial = sizes[_level.clamp(0, sizes.length - 1)];
        return DraggableScrollableSheet(
          controller: _sheet,
          expand: true,
          initialChildSize: initial,
          minChildSize: sizes.first,
          maxChildSize: sizes.last,
          snap: true,
          snapSizes: sizes.length > 2
              ? sizes.sublist(1, sizes.length - 1)
              : null,
          shouldCloseOnMinExtent: false,
          builder: (context, scroll) => WouandaSheetSurface(
            bottomPadding: 0,
            respectBottomSafeArea: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: scroll,
                    physics: const ClampingScrollPhysics(),
                    // A row that grows after the first frame (a rating that loads, a
                    // line that wraps) moves the stops: the panel re-reads them, so
                    // it never rests with a row cut in half.
                    child: NotificationListener<SizeChangedLayoutNotification>(
                      onNotification: (_) {
                        _measure();
                        return false;
                      },
                      child: SizeChangedLayoutNotifier(
                        child: Column(
                          key: _contentKey,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Grip(
                              key: widget.handleKey,
                              label: widget.handleLabel,
                              open:
                                  _sizes.isNotEmpty &&
                                  _level == _sizes.length - 1,
                              onTap: () => _goTo(
                                _level == _sizes.length - 1
                                    ? _restLevel
                                    : _level + 1,
                              ),
                            ),
                            ...children,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: math.max(
                    widget.bottomPadding,
                    MediaQuery.paddingOf(context).bottom,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The handle of a snap sheet: a tap moves it a step, a drag on it moves the
/// panel with the finger (the drag belongs to the sheet, not to the handle).
class _Grip extends StatelessWidget {
  const _Grip({
    super.key,
    required this.label,
    required this.open,
    required this.onTap,
  });
  final String label;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => WouandaTappable(
    behavior: HitTestBehavior.opaque,
    haptic: false,
    semanticLabel: open ? '$label : réduire' : '$label : afficher plus',
    onTap: onTap,
    child: SizedBox(
      height: 28,
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: context.palette.border,
            borderRadius: BorderRadius.circular(WouandaSpacing.radiusPill),
          ),
        ),
      ),
    ),
  );
}
