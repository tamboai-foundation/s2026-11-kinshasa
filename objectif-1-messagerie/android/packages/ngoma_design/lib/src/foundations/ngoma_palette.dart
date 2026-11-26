import 'package:flutter/material.dart';

import 'ngoma_colors.dart';

/// THE central theme of NGoma (charter §12).
///
/// Registered once in the app's `ThemeData` (light and dark). Every screen
/// reads its colours from here — `context.palette.surface`,
/// `context.palette.textPrimary` … — and never decides a colour itself.
/// Changing a value here changes the whole app, in both modes.
@immutable
class NgomaPalette extends ThemeExtension<NgomaPalette> {
  const NgomaPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.elevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.onAccent,
    required this.onMedia,
    required this.onMediaMuted,
    required this.media,
    required this.scrim,
    required this.positive,
    required this.negative,
    required this.warning,
    required this.highlight,
  });

  /// Page background.
  final Color background;

  /// Cards, sheets, fields.
  final Color surface;

  /// Quiet fills on a surface (chips, icon wells, search fields).
  final Color surfaceMuted;

  /// A surface above a surface (menus, dialogs in dark mode).
  final Color elevated;

  /// Hairlines and dividers.
  final Color border;

  final Color textPrimary;
  final Color textSecondary;

  /// Placeholders, inactive icons (never body text on light backgrounds).
  final Color textTertiary;

  /// Actions, links, selection.
  final Color accent;

  /// Text and icons on the accent or any saturated fill.
  final Color onAccent;

  /// Text and icons on photos and videos.
  final Color onMedia;
  final Color onMediaMuted;

  /// Behind photos and videos (players, viewers).
  final Color media;

  /// Dimming layer over content (modals, photo gradients).
  final Color scrim;

  final Color positive;
  final Color negative;
  final Color warning;

  /// Ratings, rewards, premium.
  final Color highlight;

  static const light = NgomaPalette(
    background: NgomaColors.backgroundLight,
    surface: NgomaColors.surfaceLight,
    surfaceMuted: NgomaColors.surfaceMutedLight,
    elevated: NgomaColors.surfaceLight,
    border: NgomaColors.borderLight,
    textPrimary: NgomaColors.textPrimaryLight,
    textSecondary: NgomaColors.textSecondaryLight,
    textTertiary: NgomaColors.textTertiaryLight,
    accent: NgomaColors.brand,
    onAccent: Color(0xFFFFFFFF),
    onMedia: Color(0xFFFFFFFF),
    onMediaMuted: Color(0xB3FFFFFF),
    media: Color(0xFF000000),
    scrim: Color(0x8A000000),
    positive: NgomaColors.positive,
    negative: NgomaColors.negative,
    warning: NgomaColors.warning,
    highlight: NgomaColors.ochre,
  );

  static const dark = NgomaPalette(
    background: NgomaColors.backgroundDark,
    surface: NgomaColors.surfaceDark,
    surfaceMuted: NgomaColors.surfaceMutedDark,
    elevated: NgomaColors.elevatedDark,
    border: NgomaColors.borderDark,
    textPrimary: NgomaColors.textPrimaryDark,
    textSecondary: NgomaColors.textSecondaryDark,
    textTertiary: NgomaColors.textTertiaryDark,
    accent: NgomaColors.brand400,
    onAccent: Color(0xFFFFFFFF),
    onMedia: Color(0xFFFFFFFF),
    onMediaMuted: Color(0xB3FFFFFF),
    media: Color(0xFF000000),
    scrim: Color(0xA6000000),
    positive: Color(0xFF30D158),
    negative: Color(0xFFFF453A),
    warning: NgomaColors.warningDark,
    highlight: NgomaColors.ochre,
  );

  /// Shared brand treatment for action-focused hero blocks without a photo.
  LinearGradient get accentGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color.lerp(accent, const Color(0xFF000000), 0.35)!],
  );

  static NgomaPalette of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  @override
  NgomaPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? elevated,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? onAccent,
    Color? onMedia,
    Color? onMediaMuted,
    Color? media,
    Color? scrim,
    Color? positive,
    Color? negative,
    Color? warning,
    Color? highlight,
  }) => NgomaPalette(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceMuted: surfaceMuted ?? this.surfaceMuted,
    elevated: elevated ?? this.elevated,
    border: border ?? this.border,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    onMedia: onMedia ?? this.onMedia,
    onMediaMuted: onMediaMuted ?? this.onMediaMuted,
    media: media ?? this.media,
    scrim: scrim ?? this.scrim,
    positive: positive ?? this.positive,
    negative: negative ?? this.negative,
    warning: warning ?? this.warning,
    highlight: highlight ?? this.highlight,
  );

  @override
  NgomaPalette lerp(NgomaPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return NgomaPalette(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      elevated: l(elevated, other.elevated),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      onMedia: l(onMedia, other.onMedia),
      onMediaMuted: l(onMediaMuted, other.onMediaMuted),
      media: l(media, other.media),
      scrim: l(scrim, other.scrim),
      positive: l(positive, other.positive),
      negative: l(negative, other.negative),
      warning: l(warning, other.warning),
      highlight: l(highlight, other.highlight),
    );
  }
}

/// `context.palette` — the one way a screen reads a colour.
extension NgomaPaletteContext on BuildContext {
  NgomaPalette get palette {
    final theme = Theme.of(this);
    return theme.extension<NgomaPalette>() ??
        NgomaPalette.of(theme.brightness);
  }
}
