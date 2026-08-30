import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

bool get isAndroidPlatform => !kIsWeb && Platform.isAndroid;

Color _resolveThemeColor() => isAndroidPlatform
    ? const Color(0xFF0A0F0B) // Spotify deep forest black
    : const Color(0xFF0D0D12);

Color _resolvePrimaryColor1() => isAndroidPlatform
    ? const Color(0xFFFFFFFF) // Pure white
    : const Color(0xFFE8E6F0);

Color _resolvePrimaryColor2() => isAndroidPlatform
    ? const Color(0xFFB3B3B3) // Spotify muted grey
    : const Color.fromARGB(255, 210, 200, 230);

Color _resolveAccentColor1() => isAndroidPlatform
    ? const Color(0xFF1DB954) // Spotify green
    : const Color(0xFF00D4AA);

Color _resolveAccentColor1light() => isAndroidPlatform
    ? const Color(0xFF1ED760) // Spotify bright green
    : const Color(0xFF33EEBB);

Color _resolveAccentColor2() => isAndroidPlatform
    ? const Color(0xFF1DB954) // Spotify green (primary accent)
    : const Color(0xFF8B5CF6);

Color _resolveCardColor() => isAndroidPlatform
    ? const Color(0xFF121212) // Spotify card black
    : const Color(0xFF16161E);

Color _resolveMutedColor() => isAndroidPlatform
    ? const Color(0xFF535353) // Spotify muted
    : const Color(0xFF6B7280);

// Spotify-specific extra colors
Color _resolveSpotifyGreenDark() => const Color(0xFF158A3E);
Color _resolveSpotifyChipBg() => isAndroidPlatform
    ? const Color(0xFF1A2C20) // Pill chip background
    : const Color(0xFF1E1E2A);

String? _resolvePrimaryFont() => isAndroidPlatform ? "Unageo" : "Fjalla";
String? _resolveSecondaryFont() => isAndroidPlatform ? "ReThink-Sans" : "Gilroy";
String? _resolveTertiaryFont() => isAndroidPlatform ? "Unageo" : "CodePro";

class DynamicColor extends Color {
  final Color Function() resolver;
  const DynamicColor(this.resolver) : super(0);

  @override
  int get value => resolver().value;

  @override
  int get red => resolver().red;

  @override
  int get green => resolver().green;

  @override
  int get blue => resolver().blue;

  @override
  int get alpha => resolver().alpha;

  @override
  double get r => resolver().r;

  @override
  double get g => resolver().g;

  @override
  double get b => resolver().b;

  @override
  double get a => resolver().a;

  @override
  double get opacity => resolver().opacity;

  @override
  Color withOpacity(double opacity) => resolver().withOpacity(opacity);

  @override
  Color withAlpha(int a) => resolver().withAlpha(a);

  @override
  Color withRed(int r) => resolver().withRed(r);

  @override
  Color withGreen(int g) => resolver().withGreen(g);

  @override
  Color withBlue(int b) => resolver().withBlue(b);

  @override
  Color withValues({
    double? alpha,
    double? red,
    double? green,
    double? blue,
    dynamic colorSpace,
  }) {
    return resolver().withValues(
      alpha: alpha,
      red: red,
      green: green,
      blue: blue,
      colorSpace: colorSpace,
    );
  }

  @override
  double computeLuminance() => resolver().computeLuminance();

  @override
  String toString() => resolver().toString();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Color && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

class DynamicTextStyle extends TextStyle {
  final String? Function() fontFamilyResolver;

  const DynamicTextStyle({
    super.inherit,
    super.color,
    super.backgroundColor,
    super.fontSize,
    super.fontWeight,
    super.fontStyle,
    super.letterSpacing,
    super.wordSpacing,
    super.textBaseline,
    super.height,
    super.leadingDistribution,
    super.locale,
    super.foreground,
    super.background,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.debugLabel,
    super.fontFamilyFallback,
    super.package,
    super.overflow,
    required this.fontFamilyResolver,
  });

  @override
  String? get fontFamily => fontFamilyResolver();
}

/// Canonical app theme.
///
/// Use [AppTheme] in new code. The [Default_Theme] typedef at the bottom of
/// this file provides backward-compatible access for existing callers while
/// imports are being migrated.
class AppTheme {
  // ── Text Styles ─────────────────────────────────────────────────────────────
  static const primaryTextStyle = DynamicTextStyle(fontFamilyResolver: _resolvePrimaryFont);
  static const secondoryTextStyle = DynamicTextStyle(fontFamilyResolver: _resolveSecondaryFont);
  static const secondoryTextStyleMedium =
      DynamicTextStyle(fontFamilyResolver: _resolveSecondaryFont, fontWeight: FontWeight.w700);
  static const tertiaryTextStyle = DynamicTextStyle(fontFamilyResolver: _resolveTertiaryFont);
  
  static const fontAwesomeRegularFont =
      TextStyle(fontFamily: "FontAwesome-Regular");
  static const fontAwesomeSolidFont =
      TextStyle(fontFamily: "FontAwesome-Solids");

  // ── Colors ──────────────────────────────────────────────────────────────────
  static const themeColor = DynamicColor(_resolveThemeColor);
  static const primaryColor1 = DynamicColor(_resolvePrimaryColor1);
  static const primaryColor2 = DynamicColor(_resolvePrimaryColor2);
  static const accentColor1 = DynamicColor(_resolveAccentColor1);
  static const accentColor1light = DynamicColor(_resolveAccentColor1light);
  static const accentColor2 = DynamicColor(_resolveAccentColor2);
  static const successColor = Color(0xFF22C55E);
  static const cardColor = DynamicColor(_resolveCardColor);
  static const mutedColor = DynamicColor(_resolveMutedColor);
  // Spotify-specific extras
  static const spotifyGreenDark = DynamicColor(_resolveSpotifyGreenDark);
  static const spotifyChipBg = DynamicColor(_resolveSpotifyChipBg);

  // ── Theme Data ───────────────────────────────────────────────────────────────
  ThemeData get defaultThemeData {
    const darkScheme = ColorScheme.dark(
      primary: accentColor2,
      secondary: accentColor1,
      surface: themeColor,
      surfaceContainerHighest: cardColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: primaryColor1,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: themeColor,
      dialogBackgroundColor: cardColor,
      primaryColorDark: accentColor2,
      fontFamily: isAndroidPlatform ? 'ReThink-Sans' : 'Gilroy',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: primaryColor1),
        bodyMedium: TextStyle(color: primaryColor1),
        bodySmall: TextStyle(color: primaryColor2),
        titleLarge: TextStyle(color: primaryColor1),
        titleMedium: TextStyle(color: primaryColor1),
        titleSmall: TextStyle(color: primaryColor1),
        displayLarge: TextStyle(color: primaryColor1),
        displayMedium: TextStyle(color: primaryColor1),
        displaySmall: TextStyle(color: primaryColor1),
        headlineLarge: TextStyle(color: primaryColor1),
        headlineMedium: TextStyle(color: primaryColor1),
        headlineSmall: TextStyle(color: primaryColor1),
        labelLarge: TextStyle(color: primaryColor1),
        labelMedium: TextStyle(color: primaryColor1),
        labelSmall: TextStyle(color: primaryColor2),
      ),
      primarySwatch: MaterialColor(
        accentColor2.value,
        {
          50: accentColor2.withValues(alpha: 0.1),
          100: accentColor2.withValues(alpha: 0.2),
          200: accentColor2.withValues(alpha: 0.3),
          300: accentColor2.withValues(alpha: 0.4),
          400: accentColor2.withValues(alpha: 0.5),
          500: accentColor2.withValues(alpha: 0.6),
          600: accentColor2.withValues(alpha: 0.7),
          700: accentColor2.withValues(alpha: 0.8),
          800: accentColor2.withValues(alpha: 0.9),
          900: accentColor2,
        },
      ),
      colorScheme: darkScheme.copyWith(
        primary: accentColor2,
        secondary: accentColor1,
      ),
      iconTheme: const IconThemeData(color: primaryColor1),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(accentColor2.withValues(alpha: 0.5)),
        interactive: true,
        radius: const Radius.circular(10),
        thickness: WidgetStateProperty.all(4),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: themeColor,
        foregroundColor: primaryColor1,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: primaryColor1),
        elevation: 0,
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: accentColor2),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: accentColor2,
        selectionColor: accentColor2,
        selectionHandleColor: accentColor2,
      ),
      brightness: Brightness.dark,
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(primaryColor1),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? accentColor1
                : accentColor2.withValues(alpha: 0.4)),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? accentColor1
                : Colors.transparent),
      ),
      searchBarTheme: const SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(cardColor),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: cardColor,
        textStyle: TextStyle(color: primaryColor1),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(cardColor),
        ),
        textStyle: TextStyle(color: primaryColor1),
      ),
      menuTheme: const MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(cardColor),
        ),
      ),
      cardTheme: const CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1E1E2A),
        thickness: 1,
        space: 1,
      ),
    );
  }
}

/// Backward-compat alias for [AppTheme].
/// Prefer importing from [core/theme/app_theme.dart] and using [AppTheme] directly.
// ignore: camel_case_types
typedef Default_Theme = AppTheme;
