/// Spacing, shape and touch-target foundations (4-point grid).
abstract final class WouandaSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;

  /// Horizontal margin of every page.
  static const double pageGutter = 16;

  // The ONLY radii of Wouanda (charter §16). Screens never write a number.
  static const double radiusXs = 4; // handles, progress bars, dots
  static const double radiusSmall = 8; // chips, badges, inputs
  static const double radiusMedium = 14; // cards, tiles, buttons
  static const double radiusLarge = 20; // hero cards, grouped lists
  static const double radiusSheet = 28; // bottom sheets, dialogs
  static const double radiusPill = 999;

  static const double minimumTouchTarget = 48;
}
