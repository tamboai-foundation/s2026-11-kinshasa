import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:ngoma_design/ngoma_design.dart';

/// NGoma theme — built only from the design tokens of `ngoma_design`
/// (charte « moderne chaleureux africain », docs/design/CHARTE_NGOMA.md).
///
/// The names below are kept for the existing screens; their values now all
/// come from the tokens, so every screen follows the same charter.
class AppTheme {
  // ─── Shape ──────────────────────────────────────────────────────────────
  static const double radiusSmall = NgomaSpacing.radiusSmall;
  static const double radiusMedium = NgomaSpacing.radiusMedium;
  static const double radiusLarge = NgomaSpacing.radiusLarge;
  static const double radiusSheet = NgomaSpacing.radiusSheet;

  // ─── Surfaces ───────────────────────────────────────────────────────────
  static const Color darkBackground = NgomaColors.backgroundDark;
  static const Color darkSurface = NgomaColors.surfaceDark;
  static const Color darkCard = NgomaColors.surfaceDark;
  static const Color darkBorder = NgomaColors.borderDark;

  static const Color lightBackground = NgomaColors.backgroundLight;
  static const Color lightSurface = NgomaColors.surfaceLight;
  static const Color lightCard = NgomaColors.surfaceLight;
  static const Color lightBorder = NgomaColors.borderLight;

  // Legacy "obsidian" names, now mapped to the dark tokens.
  static const Color obsidianBlack = NgomaColors.backgroundDark;
  static const Color obsidianSurface = NgomaColors.surfaceDark;
  static const Color obsidianCard = NgomaColors.elevatedDark;
  static const Color obsidianBorder = NgomaColors.borderDark;

  // ─── Brand ──────────────────────────────────────────────────────────────
  static const Color primary = NgomaColors.brand;
  static const Color darkPrimary = NgomaColors.brand400;
  static const Color secondary = NgomaColors.textSecondaryLight;
  static const Color accent = NgomaColors.ochre;

  // ─── Services (icon and thin accent only) ───────────────────────────────
  static const Color ngomaGo = NgomaColors.go;
  static const Color ngomaGoLight = NgomaColors.goContainer;
  static const Color ngomaShop = NgomaColors.shop;
  static const Color ngomaShopLight = NgomaColors.shopContainer;
  static const Color ngomaEvents = NgomaColors.events;
  static const Color ngomaEventsLight = NgomaColors.eventsContainer;
  static const Color ngomaLove = NgomaColors.love;
  static const Color ngomaLoveLight = NgomaColors.loveContainer;
  static const Color ngomaStay = NgomaColors.stay;
  static const Color ngomaStayLight = NgomaColors.stayContainer;

  // ─── Gradients — only the brand one is used for heroes ──────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [NgomaColors.brand, NgomaColors.brand800],
  );
  static const LinearGradient goGradient = brandGradient;
  static const LinearGradient shopGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [NgomaColors.shop, NgomaColors.earth],
  );
  static const LinearGradient obsidianGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [NgomaColors.brand800, NgomaColors.brand900],
  );
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white10, Colors.transparent],
  );
  static const LinearGradient stayGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [NgomaColors.stay, Color(0xFF0B6B5F)],
  );

  // ─── Typography — one family, one scale (NgomaType) ───────────────────
  static String globalFontFamily = NgomaType.fontFamily;

  /// « Apple moderne » type rules, applied to EVERY text of the app because
  /// every style goes through [font] (docs/design/CHARTE_NGOMA.md):
  /// - nothing under 12 px;
  /// - every size snaps to [typeScale] (12 … 30);
  ///   so no screen invents its own size;
  /// - weights stop at extra-bold: 900 becomes 800.
  /// The ONE type scale of NGoma (charter §16). Any size written in a
  /// screen lands on the nearest step: the whole app shares the same
  /// typographic rhythm, whatever the screen asked for.
  static const typeScale = <double>[12, 13, 14, 16, 19, 22, 24, 30];

  static double _quietSize(double size) {
    var best = typeScale.first;
    for (final step in typeScale) {
      if ((step - size).abs() < (best - size).abs()) best = step;
    }
    return best;
  }

  static FontWeight? _quietWeight(FontWeight? weight) {
    if (weight == null) return null;
    return weight.value > FontWeight.w800.value ? FontWeight.w800 : weight;
  }

  static TextStyle font({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    FontStyle? fontStyle,
    List<Shadow>? shadows,
    Color? backgroundColor,
    TextOverflow? overflow,
  }) {
    final size = fontSize == null ? null : _quietSize(fontSize);
    return GoogleFonts.getFont(
      globalFontFamily,
      fontSize: size,
      fontWeight: _quietWeight(fontWeight),
      color: color,
      // Titles are set tight, as in Apple's display type.
      // No wide tracking anywhere (no spaced-out capitals): at most 0.2.
      letterSpacing:
          (letterSpacing?.clamp(-1.0, 0.2)) ??
          (size == null
              ? null
              : size >= 20
              ? -0.6
              : size >= 16
              ? -0.2
              : null),
      height: height,
      decoration: decoration,
      fontStyle: fontStyle,
      shadows: shadows,
      backgroundColor: backgroundColor,
    ).copyWith(overflow: overflow);
  }

  static TextStyle _token(
    NgomaTextToken token, {
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) => font(
    fontSize: token.size,
    fontWeight: fontWeight ?? token.weight,
    height: height ?? token.height,
    color: color,
  );

  static TextStyle displayXL({Color? color}) =>
      _token(NgomaType.display, color: color);
  static TextStyle displayLg({Color? color}) =>
      _token(NgomaType.headline, color: color);

  static TextStyle h1({Color? color, FontWeight? fontWeight}) =>
      _token(NgomaType.title, color: color, fontWeight: fontWeight);
  static TextStyle h2({Color? color, FontWeight? fontWeight}) =>
      _token(NgomaType.title, color: color, fontWeight: fontWeight);
  static TextStyle h3({Color? color, FontWeight? fontWeight}) =>
      _token(NgomaType.subtitle, color: color, fontWeight: fontWeight);

  static TextStyle titleLg({Color? color, FontWeight? fontWeight}) =>
      _token(NgomaType.subtitle, color: color, fontWeight: fontWeight);
  static TextStyle titleMd({Color? color, FontWeight? fontWeight}) =>
      _token(NgomaType.label, color: color, fontWeight: fontWeight);

  static TextStyle bodyLg({
    Color? color,
    double? height,
    FontWeight? fontWeight,
  }) => _token(
    NgomaType.body,
    color: color,
    height: height,
    fontWeight: fontWeight,
  );
  static TextStyle bodyMd({
    Color? color,
    double? height,
    FontWeight? fontWeight,
  }) => _token(
    NgomaType.body,
    color: color,
    height: height,
    fontWeight: fontWeight,
  );
  static TextStyle bodySm({
    Color? color,
    double? height,
    FontWeight? fontWeight,
  }) => _token(
    NgomaType.bodySmall,
    color: color,
    height: height,
    fontWeight: fontWeight,
  );

  static TextStyle labelLg({Color? color, FontWeight? fontWeight}) =>
      _token(NgomaType.bodySmall, color: color, fontWeight: fontWeight);
  static TextStyle labelMd({Color? color, FontWeight? fontWeight}) =>
      _token(NgomaType.caption, color: color, fontWeight: fontWeight);

  static TextStyle btnLg({Color? color, FontWeight? fontWeight}) =>
      _token(NgomaType.label, color: color, fontWeight: fontWeight);
  static TextStyle btnMd({Color? color, FontWeight? fontWeight}) => _token(
    NgomaType.bodySmall,
    color: color,
    fontWeight: fontWeight ?? FontWeight.w700,
  );
  static TextStyle btnSm({Color? color, FontWeight? fontWeight}) => _token(
    NgomaType.caption,
    color: color,
    fontWeight: fontWeight ?? FontWeight.w700,
  );

  static TextStyle caption({Color? color, FontWeight? fontWeight}) =>
      _token(NgomaType.caption, color: color, fontWeight: fontWeight);

  /// Amounts and times use tabular figures so columns line up.
  static TextStyle amount({Color? color, FontWeight? fontWeight}) => _token(
    NgomaType.amount,
    color: color,
    fontWeight: fontWeight,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle amountSm({Color? color, FontWeight? fontWeight}) => _token(
    NgomaType.subtitle,
    color: color,
    fontWeight: fontWeight,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Height of every primary action button (charter « Finition » §6).
  static const double primaryActionHeight = 56;

  static TextStyle overline({Color? color, FontWeight? fontWeight}) => font(
    fontSize: NgomaType.caption.size,
    fontWeight: fontWeight ?? FontWeight.w800,
    letterSpacing: 0.8,
    color: color,
  );

  static TextTheme textTheme(TextTheme base) =>
      NgomaType.applyTo(GoogleFonts.getTextTheme(globalFontFamily, base));

  // ─── Status ─────────────────────────────────────────────────────────────
  static const Color success = NgomaColors.positive;
  static const Color successLight = NgomaColors.positiveContainer;
  static const Color warning = NgomaColors.warning;
  static const Color warningLight = NgomaColors.warningContainer;
  static Color warningFor(bool isDark) =>
      NgomaColors.warningFor(isDark ? Brightness.dark : Brightness.light);
  static Color warningContainerFor(bool isDark) =>
      NgomaColors.warningContainerFor(
        isDark ? Brightness.dark : Brightness.light,
      );
  static const Color error = NgomaColors.negative;
  static const Color errorLight = NgomaColors.negativeContainer;
  static const Color info = NgomaColors.information;
  static const Color infoLight = NgomaColors.informationContainer;

  // ─── Text ───────────────────────────────────────────────────────────────
  static const Color textPrimary = NgomaColors.textPrimaryLight;
  static const Color textSecondary = NgomaColors.textSecondaryLight;
  static const Color textTertiary = NgomaColors.textTertiaryLight;
  static const Color textDarkPrimary = NgomaColors.textPrimaryDark;
  static const Color textDarkSecondary = NgomaColors.textSecondaryDark;
  static const Color textDarkTertiary = NgomaColors.textTertiaryDark;

  static ThemeData get darkTheme => _build(Brightness.dark);
  static ThemeData get lightTheme => _build(Brightness.light);

  /// One theme recipe for both modes: only the tokens change.
  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final brand = NgomaColors.primary(brightness);
    final background = NgomaColors.background(brightness);
    final surface = NgomaColors.surface(brightness);
    final border = NgomaColors.border(brightness);
    final ink = NgomaColors.textPrimary(brightness);
    final inkSoft = NgomaColors.textSecondary(brightness);
    final inkFaint = NgomaColors.textTertiary(brightness);
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    final medium = BorderRadius.circular(radiusMedium);

    return ThemeData(
      brightness: brightness,
      fontFamily: globalFontFamily,
    ).copyWith(
      // The central theme: every screen reads context.palette.
      extensions: [NgomaPalette.of(brightness)],
      scaffoldBackgroundColor: background,
      primaryColor: brand,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: brand,
        onPrimary: Colors.white,
        primaryContainer: Color.alphaBlend(
          brand.withValues(alpha: isDark ? 0.28 : 0.12),
          surface,
        ),
        onPrimaryContainer: isDark ? Colors.white : brand,
        secondary: NgomaColors.ochre,
        onSecondary: Colors.white,
        secondaryContainer: NgomaColors.ochreContainer,
        onSecondaryContainer: NgomaColors.textPrimaryLight,
        tertiary: NgomaColors.earth,
        onTertiary: Colors.white,
        error: NgomaColors.negative,
        onError: Colors.white,
        surface: surface,
        onSurface: ink,
        onSurfaceVariant: inkSoft,
        surfaceContainerHighest: NgomaColors.surfaceMuted(brightness),
        // Every Material surface tone is one of ours: left unset, Flutter
        // derives them from a default lilac seed (menus, pickers, chips).
        surfaceContainerLowest: surface,
        surfaceContainerLow: surface,
        surfaceContainer: surface,
        surfaceContainerHigh: surface,
        surfaceTint: Colors.transparent,
        outline: border,
        outlineVariant: border,
      ),
      textTheme: textTheme(base.textTheme)
          .apply(bodyColor: ink, displayColor: ink)
          .copyWith(
            headlineLarge: displayLg(color: ink),
            headlineMedium: h1(color: ink),
            headlineSmall: h2(color: ink),
            titleLarge: h3(color: ink),
            titleMedium: titleLg(color: ink),
            titleSmall: titleMd(color: ink),
            bodyLarge: bodyLg(color: ink),
            // Default text is ink: secondary text states its grey explicitly.
            bodyMedium: bodyMd(color: ink),
            bodySmall: bodySm(color: inkSoft),
            labelLarge: btnLg(color: ink),
            labelMedium: labelMd(color: inkSoft),
            labelSmall: caption(color: inkFaint),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: ink),
        titleTextStyle: h2(color: ink),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      // White cards float on #F5F5F7: a soft shadow, never a border.
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.10),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 10,
        horizontalTitleGap: 14,
        iconColor: ink,
        titleTextStyle: font(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        subtitleTextStyle: font(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: inkSoft,
        ),
        shape: RoundedRectangleBorder(borderRadius: medium),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, primaryActionHeight),
          shape: RoundedRectangleBorder(borderRadius: medium),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 0,
          textStyle: btnLg(),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, primaryActionHeight),
          shape: RoundedRectangleBorder(borderRadius: medium),
          textStyle: btnLg(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brand,
          minimumSize: const Size(64, NgomaSpacing.minimumTouchTarget),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: medium),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: btnLg(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          textStyle: btnLg(),
          // Thumb zone: no link or text action under 48 dp, anywhere.
          minimumSize: const Size(64, NgomaSpacing.minimumTouchTarget),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(NgomaSpacing.minimumTouchTarget),
        ),
      ),
      // Mobile ergonomics for the whole app (DESIGN_WORKFLOW « Règles
      // d'ergonomie mobile »): padded touch targets, standard density, and
      // one transition between screens (no hard cut): a fade-and-rise on
      // Android, the native swipe-back on iOS.
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: medium),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: NgomaColors.surfaceMuted(brightness),
        selectedColor: Color.alphaBlend(
          brand.withValues(alpha: isDark ? 0.28 : 0.12),
          surface,
        ),
        labelStyle: bodySm(color: ink),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NgomaSpacing.radiusPill),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? brand : null,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: brand),
      // Pickers and menus Flutter still draws (dates, hours, the capsule
      // menu) wear the NGoma surface, shape and accent. Lists of choices
      // themselves use showNgomaChoices, never a Material menu.
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: surface,
        headerForegroundColor: ink,
        dividerColor: border,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        rangeSelectionBackgroundColor: brand.withValues(alpha: 0.14),
        todayBorder: BorderSide(color: brand),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        dialBackgroundColor: NgomaColors.surfaceMuted(brightness),
        hourMinuteColor: NgomaColors.surfaceMuted(brightness),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: BorderSide(color: border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        elevation: 8,
        modalElevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusSheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSheet),
        ),
        titleTextStyle: h3(color: ink),
        contentTextStyle: bodyMd(color: inkSoft),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? NgomaColors.elevatedDark
            : NgomaColors.textPrimaryLight,
        contentTextStyle: bodyMd(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: medium),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        // Apple tab bar: no pill, accent for the current tab, grey otherwise.
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: brand, size: 24);
          }
          return IconThemeData(color: inkFaint, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return caption(
            color: selected ? brand : inkFaint,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: medium,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: medium,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: medium,
          borderSide: BorderSide(color: brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: medium,
          borderSide: const BorderSide(color: error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: bodyMd(color: inkFaint),
      ),
    );
  }

  // Helper methods for consistent theming
  static Color getBackground(bool isDark) =>
      isDark ? darkBackground : lightBackground;
  static Color getSurface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color getCard(bool isDark) => isDark ? darkCard : lightCard;
  static Color getBorder(bool isDark) => isDark ? darkBorder : lightBorder;

  /// Quiet fill on a card or a page (chips, fields, icon wells).
  static Color getMuted(bool isDark) =>
      isDark ? NgomaColors.surfaceMutedDark : NgomaColors.surfaceMutedLight;
  static Color getTextPrimary(bool isDark) =>
      isDark ? textDarkPrimary : textPrimary;
  static Color getTextSecondary(bool isDark) =>
      isDark ? textDarkSecondary : textSecondary;
  static Color getTextTertiary(bool isDark) =>
      isDark ? textDarkTertiary : textTertiary;

  // Service color helpers with light variants
  static Color getServiceColor(String service) {
    switch (service.toLowerCase()) {
      case 'go':
        return ngomaGo;
      case 'shop':
        return ngomaShop;
      case 'events':
        return ngomaEvents;
      case 'love':
        return ngomaLove;
      default:
        return ngomaGo;
    }
  }

  static Color getServiceLightColor(String service) {
    switch (service.toLowerCase()) {
      case 'go':
        return ngomaGoLight;
      case 'shop':
        return ngomaShopLight;
      case 'events':
        return ngomaEventsLight;
      case 'love':
        return ngomaLoveLight;
      default:
        return ngomaGoLight;
    }
  }

  // Status color helpers
  static Color getStatusColor(String status, {bool isDark = false}) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'terminé':
        return success;
      case 'warning':
      case 'scheduled':
      case 'planifié':
        return warningFor(isDark);
      case 'error':
      case 'cancelled':
      case 'annulé':
        return error;
      case 'info':
      case 'en cours':
        return info;
      default:
        return info;
    }
  }

  static Color getStatusLightColor(String status, {bool isDark = false}) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'terminé':
        return successLight;
      case 'warning':
      case 'scheduled':
      case 'planifié':
        return warningContainerFor(isDark);
      case 'error':
      case 'cancelled':
      case 'annulé':
        return errorLight;
      case 'info':
      case 'en cours':
        return infoLight;
      default:
        return infoLight;
    }
  }

  // --- Standardized Form Field Builder ---
  static Widget buildTextField({
    required BuildContext context,
    required String label,
    required bool isDark,
    TextEditingController? controller,
    String? hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    FocusNode? focusNode,
    String? helperText,
    String? errorText,
    TextCapitalization textCapitalization = TextCapitalization.none,

    /// The key at the bottom right of the keyboard: « Suivant » between fields,
    /// « OK » on the last one.
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 0,
            bottom: 4,
          ), // Properly flushed to the left
          child: Text(
            label,
            style: font(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: getTextSecondary(isDark),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          onChanged: onChanged,
          validator: validator,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          focusNode: focusNode,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onFieldSubmitted: onSubmitted,
          style: font(fontSize: 15, color: getTextPrimary(isDark)),
          // Borders, fill and padding come from the theme's
          // inputDecorationTheme: one source for every field.
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            helperText: helperText,
            errorText: errorText,
          ),
        ),
      ],
    );
  }

  static Widget buildPatternDivider(bool isDark) {
    final color = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Divider(color: color, height: 1, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(
                4,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Transform.rotate(
                    angle: 0.785, // 45 degrees in radians
                    child: Container(
                      width: 5,
                      height: 5,
                      color: isDark
                          ? const Color(0xFFC5A059)
                          : const Color(0xFFB38F4D),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: color, height: 1, thickness: 1)),
        ],
      ),
    );
  }
}
