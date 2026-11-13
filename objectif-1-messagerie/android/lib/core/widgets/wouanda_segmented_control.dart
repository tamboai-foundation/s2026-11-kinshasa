import 'package:flutter/material.dart';
import 'package:ngoma/core/widgets/wouanda_tappable.dart';
import 'package:flutter/services.dart';
import 'package:wouanda_design/wouanda_design.dart';

import 'package:ngoma/core/theme.dart';

/// The ONE segmented control of the app (docs/design/CHARTE_WOUANDA.md §7):
/// a muted pill track, the selected segment raised in white with the brand
/// label. Used to switch views of the same list (« À venir / Passés /
/// Favoris »), never for navigation between screens.
class WouandaSegmentedControl extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// What waits in each segment (unread messages…): a count beside its
  /// label, so a view not shown still says it has news. Null or 0: nothing.
  final List<int>? badges;

  const WouandaSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
    this.badges,
  }) : assert(segments.length >= 2 && segments.length <= 4),
       assert(badges == null || badges.length == segments.length);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final primary = context.palette.accent;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        var segmentWidth = 48.0;
        var trackHeight = 48.0;
        for (var i = 0; i < segments.length; i++) {
          final painter = TextPainter(
            text: TextSpan(
              text: segments[i],
              style: AppTheme.font(
                fontSize: WouandaType.bodySmall.size + 1,
                fontWeight: FontWeight.w700,
              ),
            ),
            textDirection: Directionality.of(context),
            textScaler: scaler,
          )..layout();
          final badgeWidth = (badges?[i] ?? 0) > 0 ? scaler.scale(32) + 6 : 0;
          final neededWidth = painter.width + 24 + badgeWidth;
          if (neededWidth > segmentWidth) segmentWidth = neededWidth;
          if (painter.height + 24 > trackHeight) {
            trackHeight = painter.height + 24;
          }
          painter.dispose();
        }
        final needed = segmentWidth * segments.length + 8;
        final width =
            constraints.hasBoundedWidth && constraints.maxWidth > needed
            ? constraints.maxWidth
            : needed;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Container(
              height: trackHeight,
              // Each segment is a full 48 dp tall tap area; the pill inside keeps its
              // 4 dp margin so the drawing is unchanged.
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: WouandaColors.surfaceMuted(brightness),
                borderRadius: BorderRadius.circular(WouandaSpacing.radiusPill),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < segments.length; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == selectedIndex,
                        value: (badges?[i] ?? 0) > 0
                            ? '${badges![i]} non lus'
                            : null,
                        child: WouandaTappable(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (i == selectedIndex) return;
                            HapticFeedback.selectionClick();
                            onChanged(i);
                          },
                          child: AnimatedContainer(
                            duration: WouandaMotion.duration(
                              context,
                              WouandaMotion.standard,
                            ),
                            curve: Curves.easeOut,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: i == selectedIndex
                                  ? WouandaColors.surface(brightness)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                WouandaSpacing.radiusPill,
                              ),
                              boxShadow: i == selectedIndex
                                  ? WouandaElevation.card(
                                      Theme.of(context).brightness,
                                    )
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    segments[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.font(
                                      fontSize: WouandaType.bodySmall.size + 1,
                                      fontWeight: i == selectedIndex
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: i == selectedIndex
                                          ? primary
                                          : WouandaColors.textSecondary(
                                              brightness,
                                            ),
                                    ),
                                  ),
                                ),
                                if ((badges?[i] ?? 0) > 0) ...[
                                  const SizedBox(width: 6),
                                  ExcludeSemantics(
                                    child: Container(
                                      key: ValueKey('segment-badge-$i'),
                                      constraints: const BoxConstraints(
                                        minWidth: 20,
                                      ),
                                      height: scaler.scale(20),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: primary,
                                        borderRadius: BorderRadius.circular(
                                          WouandaSpacing.radiusPill,
                                        ),
                                      ),
                                      child: Text(
                                        badges![i] > 99
                                            ? '99+'
                                            : '${badges![i]}',
                                        style: AppTheme.font(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: context.palette.onAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
