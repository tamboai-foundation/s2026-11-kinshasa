import 'package:flutter/material.dart';
import 'wouanda_text_scale.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:wouanda_design/wouanda_design.dart';

import 'package:ngoma/core/theme.dart';

/// Shared building blocks of lists and sheets (docs/design/CHARTE_WOUANDA.md,
/// « Finition »). Every service composes its screens from these, so the
/// finish — hierarchy, spacing, selection — is the same everywhere.
///
/// Rules they carry:
/// - no box around every row, only the selected one is framed;
/// - three text levels: 16/700 name, 13/500 grey detail, 12/700 pill;
/// - figures (prices, times) are tabular and right-aligned.

TextStyle _style(
  double size,
  FontWeight weight,
  Color color, {
  bool tabular = false,
}) => AppTheme.font(fontSize: size, fontWeight: weight, color: color).copyWith(
  height: 1.25,
  fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
);

/// Header of a bottom sheet: centred title, one line of context under it,
/// optional back arrow, hairline underneath (Uber, Bolt).
class WouandaSheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  const WouandaSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final ink = WouandaColors.textPrimary(brightness);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: WouandaColors.border(brightness),
            borderRadius: BorderRadius.circular(WouandaSpacing.radiusXs),
          ),
        ),
        SizedBox(
          // Full width: without it the stack shrank to the title, and the
          // back arrow and the trailing action floated next to the text
          // instead of sitting at the sheet's edges.
          width: double.infinity,
          // Grows with the text size: a fixed height cut the title and its
          // subtitle when the phone's text was set large.
          height: wouandaScaledExtent(
            context,
            subtitle == null ? 52 : 60,
            textShare: .6,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (onBack != null)
                Positioned(
                  left: 4,
                  child: IconButton(
                    tooltip: 'Retour',
                    onPressed: onBack,
                    icon: Icon(LucideIcons.arrowLeft, color: ink, size: 22),
                  ),
                ),
              Padding(
                // Room for the back arrow only when there is one.
                padding: EdgeInsets.symmetric(
                  horizontal: onBack == null && trailing == null ? 16 : 56,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _style(16, FontWeight.w600, ink),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _style(
                          13,
                          FontWeight.w400,
                          WouandaColors.textSecondary(brightness),
                          tabular: true,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) Positioned(right: 4, child: trailing!),
            ],
          ),
        ),
        Divider(height: 1, color: WouandaColors.border(brightness)),
      ],
    );
  }
}

/// Section title of a list: 14/700 ink, generous space above.
class WouandaSectionTitle extends StatelessWidget {
  final String text;
  final Widget? action;

  /// Figure at the right end of the title (the total of the day), tabular.
  final String? detail;

  const WouandaSectionTitle(this.text, {super.key, this.action, this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(WouandaSpacing.pageGutter, 20, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: _style(
                14,
                FontWeight.w600,
                WouandaColors.textPrimary(Theme.of(context).brightness),
              ),
            ),
          ),
          if (detail != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                detail!,
                style: _style(
                  13,
                  FontWeight.w600,
                  WouandaColors.textSecondary(Theme.of(context).brightness),
                  tabular: true,
                ),
              ),
            ),
          ?action,
        ],
      ),
    );
  }
}

/// Section header of a feed (Accueil, Artisanat, Événements, Séjour…):
/// a bold title, an optional one-line detail, « Voir tout » in the accent.
/// The ONE way a content section opens (charter §12).
class WouandaSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onAction;
  final String actionLabel;
  final Widget? trailing;

  const WouandaSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onAction,
    this.actionLabel = 'Voir tout',
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WouandaSpacing.pageGutter,
        WouandaSpacing.lg,
        WouandaSpacing.xs,
        WouandaSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _style(
                    WouandaType.subtitle.size,
                    WouandaType.subtitle.weight,
                    WouandaColors.textPrimary(brightness),
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _style(
                        13,
                        FontWeight.w500,
                        WouandaColors.textSecondary(brightness),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: context.palette.accent,
              ),
              child: Text(
                actionLabel,
                style: _style(15, FontWeight.w600, context.palette.accent),
              ),
            ),
        ],
      ),
    );
  }
}

/// A list row: leading visual, title, optional detail, trailing value.
/// Rows are never boxed; pass [selected] to frame the chosen one.
class WouandaListRow extends StatelessWidget {
  final Widget? leading;

  /// Shortcut for the usual round icon leading.
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? badge;

  /// Right-hand value (price, time…), rendered tabular.
  final String? value;
  final String? valueDetail;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final bool subtitleIsHint;

  /// Lines before an ellipsis. One by default; raise [subtitleMaxLines] where
  /// the detail is the information itself (a landmark, an address).
  final int titleMaxLines, subtitleMaxLines;

  /// For a sheet opened while on the move (driving, riding): a taller row, a
  /// larger icon disc and a 16 title, so the thumb finds it without aiming.
  final bool roomy;

  const WouandaListRow({
    super.key,
    this.leading,
    this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.value,
    this.valueDetail,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.subtitleIsHint = false,
    this.titleMaxLines = 1,
    this.subtitleMaxLines = 1,
    this.roomy = false,
  });

  @override
  Widget build(BuildContext context) => WouandaPressScale(
    enabled: onTap != null,
    scale: .985,
    child: _content(context),
  );

  Widget _content(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final ink = WouandaColors.textPrimary(brightness);
    final muted = WouandaColors.textSecondary(brightness);
    final lead =
        leading ??
        (icon == null
            ? null
            : Container(
                width: roomy ? 44 : 40,
                height: roomy ? 44 : 40,
                decoration: BoxDecoration(
                  color: WouandaColors.surfaceMuted(brightness),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: roomy ? 22 : 20, color: ink),
              ));
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(WouandaSpacing.radiusLarge),
      side: selected ? BorderSide(color: ink, width: 2) : BorderSide.none,
    );
    return Material(
      color: selected
          ? WouandaColors.surfaceMuted(brightness)
          : Colors.transparent,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: WouandaSpacing.pageGutter,
            vertical: 16,
          ),
          child: Row(
            children: [
              if (lead != null) ...[lead, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: titleMaxLines,
                            overflow: TextOverflow.ellipsis,
                            style: _style(
                              roomy ? 16 : 15,
                              FontWeight.w600,
                              ink,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          badge!,
                        ],
                      ],
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          maxLines: subtitleMaxLines,
                          overflow: TextOverflow.ellipsis,
                          style: _style(
                            13,
                            FontWeight.w400,
                            // The light grey (2,1:1) is never text on a light
                            // page (charter §12): a hint stays readable.
                            muted,
                            tabular: true,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value!,
                      style: _style(15, FontWeight.w600, ink, tabular: true),
                    ),
                    if (valueDetail != null)
                      Text(
                        valueDetail!,
                        style: _style(
                          12,
                          FontWeight.w500,
                          muted,
                          tabular: true,
                        ),
                      ),
                  ],
                ),
              ],
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Small pill next to a title (« Populaire », « Vérifié »…).
class WouandaPill extends StatelessWidget {
  final String label;
  final Color? color;

  const WouandaPill(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final tint = color ?? WouandaColors.primary(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(WouandaSpacing.radiusSmall),
      ),
      child: Text(label, style: _style(12, FontWeight.w700, tint)),
    );
  }
}

/// The primary action of a sheet: one 56 px button, optional square
/// secondary action beside it (charter « Finition » §6).
class WouandaPrimaryAction extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? secondaryIcon;
  final String? secondaryTooltip;
  final VoidCallback? onSecondary;
  final bool destructive;

  const WouandaPrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondaryIcon,
    this.secondaryTooltip,
    this.onSecondary,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) => WouandaPressScale(
    enabled: onPressed != null,
    scale: .98,
    child: _content(context),
  );

  Widget _content(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WouandaSpacing.pageGutter,
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: AppTheme.primaryActionHeight,
              child: FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: WouandaColors.negative,
                      )
                    : null,
                onPressed: onPressed == null
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        onPressed!();
                      },
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _style(15, FontWeight.w600, context.palette.onAccent),
                ),
              ),
            ),
          ),
          if (secondaryIcon != null) ...[
            const SizedBox(width: 10),
            SizedBox.square(
              dimension: AppTheme.primaryActionHeight,
              child: IconButton(
                tooltip: secondaryTooltip,
                onPressed: onSecondary,
                style: IconButton.styleFrom(
                  backgroundColor: WouandaColors.surfaceMuted(brightness),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      WouandaSpacing.radiusMedium,
                    ),
                  ),
                ),
                icon: Icon(
                  secondaryIcon,
                  color: WouandaColors.textPrimary(brightness),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
