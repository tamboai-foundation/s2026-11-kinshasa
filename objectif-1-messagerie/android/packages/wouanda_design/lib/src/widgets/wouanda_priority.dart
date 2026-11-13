import 'package:flutter/material.dart';

import '../foundations/wouanda_palette.dart';
import '../foundations/wouanda_spacing.dart';
import '../foundations/wouanda_typography.dart';

enum WouandaDecisionTone { accent, highlight, positive }

/// A short, non-interactive cue that helps compare options at a glance.
///
/// Its label must be supplied by the feature contract. The component keeps
/// the visual treatment consistent and intentionally limits the copy to one
/// line.
class WouandaDecisionBadge extends StatelessWidget {
  const WouandaDecisionBadge({
    super.key,
    required this.label,
    this.icon,
    this.semanticsLabel,
    this.tone = WouandaDecisionTone.accent,
  });

  final IconData? icon;
  final String label;
  final String? semanticsLabel;
  final WouandaDecisionTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = switch (tone) {
      WouandaDecisionTone.accent => palette.accent,
      WouandaDecisionTone.highlight => palette.highlight,
      WouandaDecisionTone.positive => palette.positive,
    };
    // Ochre and green on their own 11 % tint are under 3:1 on a light page:
    // the tint keeps the tone, the label is deepened toward the ink.
    final labelColor =
        Theme.of(context).brightness == Brightness.light &&
            tone != WouandaDecisionTone.accent
        ? Color.lerp(color, palette.textPrimary, .6)!
        : color;
    return Semantics(
      label: semanticsLabel ?? label,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 22),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(WouandaSpacing.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon case final icon?) ...[
              Icon(icon, size: 13, color: labelColor),
              const SizedBox(width: 3),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WouandaType.caption.toTextStyle(color: labelColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact, semantic status at the top of a live flow.
///
/// The banner answers only two questions: what is happening now, and what the
/// user needs to know next. Business decisions and formatted status labels are
/// supplied by the bridge-facing feature; this widget only renders them.
class WouandaStatusBanner extends StatelessWidget {
  const WouandaStatusBanner({
    super.key,
    required this.title,
    this.supportingText,
    this.progress,
    this.showProgress = false,
    this.leading,
    this.trailing,
    this.margin,
    this.filled = true,
  });

  /// False inside a sheet: no tinted box (a card in a card), the title grows
  /// instead (charter §17, « un groupe = une tâche »).
  final bool filled;

  final String title;
  final String? supportingText;
  final double? progress;
  final bool showProgress;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: margin,
      padding: filled
          ? const EdgeInsets.symmetric(
              horizontal: WouandaSpacing.sm,
              vertical: WouandaSpacing.xs,
            )
          : const EdgeInsets.symmetric(vertical: WouandaSpacing.xxs),
      decoration: filled
          ? BoxDecoration(
              color: palette.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(WouandaSpacing.radiusMedium),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: WouandaSpacing.xs),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      // The current state must stay readable with large
                      // text: two lines before any ellipsis.
                      maxLines: filled ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: filled
                          ? WouandaType.label.toTextStyle(
                              color: palette.textPrimary,
                            )
                          : WouandaType.title.toTextStyle(
                              color: palette.textPrimary,
                            ),
                    ),
                    if (supportingText case final text?) ...[
                      const SizedBox(height: WouandaSpacing.xxs / 2),
                      Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            (filled
                                    ? WouandaType.caption
                                    : WouandaType.bodySmall)
                                .toTextStyle(color: palette.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: WouandaSpacing.xs),
                trailing!,
              ],
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: WouandaSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(WouandaSpacing.radiusXs),
              child: LinearProgressIndicator(
                minHeight: WouandaSpacing.xxs - 1,
                value: progress,
                color: palette.accent,
                backgroundColor: palette.accent.withValues(alpha: 0.16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Secondary action that stays compact without shrinking its touch target.
class WouandaCompactAction extends StatelessWidget {
  const WouandaCompactAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.danger = false,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool danger;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = danger
        ? palette.negative
        : active
        ? palette.accent
        : palette.textPrimary;
    return SizedBox(
      height: WouandaSpacing.minimumTouchTarget,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: palette.border),
          padding: const EdgeInsets.symmetric(horizontal: WouandaSpacing.xs),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: WouandaType.caption.toTextStyle(color: color),
        ),
      ),
    );
  }
}
