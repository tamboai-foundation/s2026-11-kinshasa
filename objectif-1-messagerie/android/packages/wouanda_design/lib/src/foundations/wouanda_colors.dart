import 'package:flutter/material.dart';

/// Wouanda colour tokens — direction « Apple moderne » chosen on 2026-09-27
/// (docs/design/CHARTE_WOUANDA.md): clean, premium, timeless.
///
/// The four colours of the palette:
/// - `#F5F5F7` background, `#1D1D1F` ink, `#AAAAAA` grey, `#E0262D` accent.
/// Every other value derives from them only where legibility requires it
/// (secondary text `#6E6E73`, hairlines `#E5E5EA`, dark-mode accent
/// `#FF5A5F`). `#AAAAAA` is too light for text on a light background: it
/// marks placeholders, inactive icons, and secondary text in dark mode.
///
/// Services use Apple's system hues, on their icon tile and nowhere else.
abstract final class WouandaColors {
  // ─── Palette ────────────────────────────────────────────────────────────
  static const paletteBackground = Color(0xFFF5F5F7);
  static const paletteInk = Color(0xFF1D1D1F);
  static const paletteGrey = Color(0xFFAAAAAA);
  static const paletteAccent = Color(0xFFE0262D);

  // ─── Brand — accent `#E0262D` and its scale ─────────────────────────────
  static const brand50 = Color(0xFFFDECEC);
  static const brand100 = Color(0xFFFAD3D4);
  static const brand200 = Color(0xFFF5A3A6);
  static const brand400 = Color(0xFFFF5A5F); // accent on dark backgrounds
  static const brand = paletteAccent;
  static const brand700 = Color(0xFFB71C22); // small links on light
  static const brand800 = Color(0xFF8F161B);
  static const brand900 = Color(0xFF5E0F12);

  // ─── Warm highlights (rewards, promotions) ─────────────────────────────
  static const ochre = Color(0xFFFF9500);
  static const ochreContainer = Color(0xFFFFF1DC);
  static const earth = Color(0xFFFF3B30);
  static const earthContainer = Color(0xFFFFE5E3);

  // ─── Neutrals — light ───────────────────────────────────────────────────
  static const backgroundLight = paletteBackground;
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceMutedLight = Color(0xFFEEEEF0); // fills on white
  static const borderLight = Color(0xFFE5E5EA); // hairlines
  static const textPrimaryLight = paletteInk;
  static const textSecondaryLight = Color(0xFF6E6E73);
  static const textTertiaryLight = paletteGrey;

  // ─── Neutrals — dark ────────────────────────────────────────────────────
  // Dark grey, not pure black: no smearing on OLED, depth still readable.
  static const backgroundDark = Color(0xFF121214);
  static const surfaceDark = Color(0xFF1C1C1E);
  static const elevatedDark = Color(0xFF2C2C2E);
  static const surfaceMutedDark = Color(0xFF2C2C2E);
  static const borderDark = Color(0xFF38383A);
  static const textPrimaryDark = paletteBackground;
  static const textSecondaryDark = paletteGrey;
  static const textTertiaryDark = Color(0xFF8E8E93);

  // ─── Service hues ─────────────────────────────────────────────────────────
  // Service identity hues: use for service marks and restrained decorative
  // details. Interactive controls always use the shared Wouanda accent.
  // Dark variants stay readable on the dark grey.
  static const go = Color(0xFFE0262D);
  static const goDark = Color(0xFFFF5A5F);
  static const goContainer = Color(0xFFFDECEC);
  static const shop = Color(0xFFFF9500);
  static const shopDark = Color(0xFFFFA733);
  static const shopContainer = Color(0xFFFFF1DC);
  static const events = Color(0xFF8A2E65); // prune
  static const eventsDark = Color(0xFFD06FA5);
  static const eventsContainer = Color(0xFFF6E3EE);
  static const love = Color(0xFFFF2D55);
  static const loveDark = Color(0xFFFF4F71);
  static const loveContainer = Color(0xFFFFE4EA);
  static const stay = Color(0xFF0F8A7A); // sarcelle
  static const stayDark = Color(0xFF3CC0AE);
  static const stayContainer = Color(0xFFDDF3EF);
  static const pay = Color(0xFF34C759);
  static const payContainer = Color(0xFFE3F7E8);

  // ─── Status (text-safe shades) ──────────────────────────────────────────
  static const positive = Color(0xFF218039);
  static const positiveContainer = Color(0xFFE3F7E8);
  static const warning = Color(0xFFB25000);
  static const warningDark = Color(0xFFFFB340);
  static const warningContainer = Color(0xFFFFF1DC);
  static const warningContainerDark = Color(0xFF3A2A10);
  static const negative = Color(0xFFD70015);
  static const negativeContainer = Color(0xFFFFE5E3);
  static const information = brand;
  static const informationContainer = brand50;

  static Color background(Brightness brightness) =>
      brightness == Brightness.dark ? backgroundDark : backgroundLight;
  static Color surface(Brightness brightness) =>
      brightness == Brightness.dark ? surfaceDark : surfaceLight;
  static Color surfaceMuted(Brightness brightness) =>
      brightness == Brightness.dark ? surfaceMutedDark : surfaceMutedLight;
  static Color border(Brightness brightness) =>
      brightness == Brightness.dark ? borderDark : borderLight;
  static Color textPrimary(Brightness brightness) =>
      brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;
  static Color textSecondary(Brightness brightness) =>
      brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;
  static Color textTertiary(Brightness brightness) =>
      brightness == Brightness.dark ? textTertiaryDark : textTertiaryLight;

  /// Accent readable on the current background.
  static Color primary(Brightness brightness) =>
      brightness == Brightness.dark ? brand400 : brand;
  static Color warningFor(Brightness brightness) =>
      brightness == Brightness.dark ? warningDark : warning;
  static Color warningContainerFor(Brightness brightness) =>
      brightness == Brightness.dark ? warningContainerDark : warningContainer;
}

/// Soft shadows replace borders: white cards float on `#F5F5F7`.
abstract final class WouandaElevation {
  /// Cards, tiles, grouped lists.
  static List<BoxShadow> card(Brightness brightness) =>
      brightness == Brightness.dark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            spreadRadius: -6,
            offset: Offset(0, 6),
          ),
        ];

  /// Hero blocks (the wallet card, a featured banner).
  static List<BoxShadow> raised(Brightness brightness) =>
      brightness == Brightness.dark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x338F161B),
            blurRadius: 30,
            spreadRadius: -12,
            offset: Offset(0, 12),
          ),
        ];
}
