import 'package:flutter/material.dart';

/// The single type scale of NGoma. Nothing smaller than 12 px is allowed:
/// the app is used outdoors, on mid-range phones, by every generation.
///
/// The font family is resolved by the app (Manrope through
/// google_fonts); this package only fixes sizes, weights and line heights.
abstract final class NgomaType {
  static const fontFamily = 'Manrope';

  // « Apple moderne » scale: large, very bold titles over calm body text.
  static const display = NgomaTextToken(30, FontWeight.w800, 1.1);
  static const headline = NgomaTextToken(24, FontWeight.w800, 1.15);
  static const title = NgomaTextToken(19, FontWeight.w700, 1.25);
  static const subtitle = NgomaTextToken(16, FontWeight.w700, 1.3);
  static const label = NgomaTextToken(14, FontWeight.w600, 1.35);
  static const body = NgomaTextToken(14, FontWeight.w500, 1.5);
  static const bodySmall = NgomaTextToken(13, FontWeight.w500, 1.45);
  static const caption = NgomaTextToken(12, FontWeight.w600, 1.35);
  static const amount = NgomaTextToken(22, FontWeight.w800, 1.1);

  /// Applies the NGoma scale to Material's semantic text roles while
  /// preserving the base theme's colors and other accessibility properties.
  static TextTheme applyTo(TextTheme base) => base.copyWith(
    displayLarge: _apply(base.displayLarge, display),
    displayMedium: _apply(base.displayMedium, display),
    displaySmall: _apply(base.displaySmall, headline),
    headlineLarge: _apply(base.headlineLarge, headline),
    headlineMedium: _apply(base.headlineMedium, title),
    headlineSmall: _apply(base.headlineSmall, subtitle),
    titleLarge: _apply(base.titleLarge, title),
    titleMedium: _apply(base.titleMedium, label),
    titleSmall: _apply(base.titleSmall, bodySmall),
    bodyLarge: _apply(base.bodyLarge, body),
    bodyMedium: _apply(base.bodyMedium, body),
    bodySmall: _apply(base.bodySmall, bodySmall),
    labelLarge: _apply(base.labelLarge, label),
    labelMedium: _apply(base.labelMedium, caption),
    labelSmall: _apply(base.labelSmall, caption),
  );

  static TextStyle? _apply(TextStyle? base, NgomaTextToken token) =>
      base?.copyWith(
        fontFamily: fontFamily,
        fontSize: token.size,
        fontWeight: token.weight,
        height: token.height,
      );
}

class NgomaTextToken {
  final double size;
  final FontWeight weight;
  final double height;

  const NgomaTextToken(this.size, this.weight, this.height);
}

extension NgomaTypeStyle on NgomaTextToken {
  TextStyle toTextStyle({Color? color}) => TextStyle(
    fontFamily: NgomaType.fontFamily,
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
  );
}
