import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wouanda_design/wouanda_design.dart';

import 'package:ngoma/core/theme.dart';

/// One choice of a [WouandaChipRail].
class WouandaChip<T> {
  final T? value;
  final String label;
  final IconData? icon;

  const WouandaChip({required this.value, required this.label, this.icon});
}

/// The ONE category/filter rail of the app (docs/design/CHARTE_WOUANDA.md §7):
/// a horizontal row of text pills — full label, sentence case, the selected
/// one filled in ink — as in Airbnb and the best-rated event apps on
/// Dribbble. Never icon circles with truncated uppercase captions.
class WouandaChipRail<T> extends StatelessWidget {
  final List<WouandaChip<T>> chips;
  final T? selected;
  final ValueChanged<T?> onSelected;
  final Widget? leading;

  /// Side margin of the first and last chip: the page gutter on a full-width
  /// rail, zero inside a surface that already has its own (a sheet).
  final double horizontalPadding;

  const WouandaChipRail({
    super.key,
    required this.chips,
    required this.selected,
    required this.onSelected,
    this.leading,
    this.horizontalPadding = WouandaSpacing.pageGutter,
  });

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final ink = WouandaColors.textPrimary(brightness);
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          // 56 - 2 x 4 = 48 dp tall chips: the minimum tap area.
          vertical: 4,
        ),
        itemCount: chips.length + (leading == null ? 0 : 1),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          if (leading != null && index == 0) return leading!;
          final chip = chips[index - (leading == null ? 0 : 1)];
          final active = chip.value == selected;
          final foreground = active
              ? WouandaColors.background(brightness)
              : ink;
          return Semantics(
            selected: active,
            button: true,
            child: Material(
              // Apple: the chosen pill in ink, the others on a quiet fill.
              color: active ? ink : WouandaColors.surfaceMuted(brightness),
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(chip.value);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (chip.icon != null) ...[
                        Icon(chip.icon, size: 16, color: foreground),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        chip.label,
                        style: AppTheme.font(
                          fontSize: WouandaType.bodySmall.size,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One pill that is on or off, with an optional icon before and after the
/// label (« Filtrer ▾ »). For filters that combine, where a rail (one choice
/// among many) does not fit. Switched on, it is outlined in the accent rather
/// than filled in ink: next to a rail, a toggle and the chosen chip of the
/// rail never look alike (« Gratuit » and « Tout » both black read as one
/// choice).
class WouandaToggleChip extends StatelessWidget {
  const WouandaToggleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.trailingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final ink = WouandaColors.textPrimary(brightness);
    final accent = context.palette.accent;
    final foreground = selected ? accent : ink;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? accent.withValues(alpha: .10)
            : WouandaColors.surfaceMuted(brightness),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: WouandaSpacing.minimumTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: foreground),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        label,
                        style: AppTheme.font(
                          fontSize: WouandaType.bodySmall.size,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: foreground,
                        ),
                      ),
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 4),
                    Icon(trailingIcon, size: 16, color: foreground),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pinned version of [WouandaChipRail], placed right under a [MiniAppHeader].
class WouandaChipRailHeader<T> extends SliverPersistentHeaderDelegate {
  final List<WouandaChip<T>> chips;
  final T? selected;
  final ValueChanged<T?> onSelected;
  final Widget? leading;

  const WouandaChipRailHeader({
    required this.chips,
    required this.selected,
    required this.onSelected,
    this.leading,
  });

  @override
  double get minExtent => WouandaChipRail.height;

  @override
  double get maxExtent => WouandaChipRail.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final brightness = Theme.of(context).brightness;
    return ColoredBox(
      color: WouandaColors.background(brightness),
      child: WouandaChipRail<T>(
        chips: chips,
        selected: selected,
        onSelected: onSelected,
        leading: leading,
      ),
    );
  }

  @override
  bool shouldRebuild(WouandaChipRailHeader<T> old) =>
      leading != old.leading ||
      selected != old.selected ||
      chips.length != old.chips.length ||
      onSelected != old.onSelected;
}
