import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Balmi color tokens — see [docs/BRAND.md].
///
/// Hierarchy: **Sweet Potato (brand)** → **Active Orange (movement)** →
/// **Sage (GPS good)** → **Attention yellow** → **Critical red**.
///
/// Usage matrix:
/// - [potato] / [potatoDk]: logo heartbeat, GPS track / path lines, record
///   start·stop CTAs, active nav, selection, key data emphasis.
/// - [activeOrange] ([amber] alias): in-activity state, current location pin,
///   running indicator, progress accents, small status dots.
/// - [sage]: GPS good / healthy / connected.
/// - [attention]: GPS weak.
/// - [critical]: SOS / hard errors (also ColorScheme.error).
/// - [ink] / [sub] / [line]: typography and chrome — **not** GPS tracks.
abstract final class BalmiColors {
  static const paper = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const mist = Color(0xFFF3F3F3);
  static const ink = Color(0xFF1C1C1C);

  /// Balmi Sweet Potato — brand / heart / VASA heritage primary.
  static const potato = Color(0xFFD9774A);
  static const potatoDk = Color(0xFFC45E32);

  static const plum = Color(0xFF6E3B4B);
  static const plumLt = Color(0xFFC98FA1);

  /// Balmi Active Orange — movement / activity accent (not brand primary).
  static const activeOrange = Color(0xFFE39A3B);

  /// Legacy alias for [activeOrange] (farm scenes, older call sites).
  static const amber = activeOrange;

  /// GPS good / healthy / connected.
  static const sage = Color(0xFF7C8F6D);

  /// GPS weak / attention.
  static const attention = Color(0xFFE8C547);

  /// SOS / critical.
  static const critical = Color(0xFFB0442F);

  static const line = Color(0xFFE6E6E6);
  static const sub = Color(0xFF8A8A8A);

  /// Live / selected GPS track polyline (Sweet Potato).
  static const trackPath = potato;

  /// Dimmer historical traces on explore maps (still potato family).
  static const trackPathMuted = Color(0xB3D9774A);

  /// Current-location marker while moving (Active Orange).
  static const locationPin = activeOrange;
}

abstract final class BalmiFonts {
  static const wordmark = 'Baloo2';
  static const fallbacks = <String>[
    'Pretendard',
    'Noto Sans KR',
    'Malgun Gothic',
    'Apple SD Gothic Neo',
    'sans-serif',
  ];
}

abstract final class BalmiTheme {
  static const extraNavPad = 20.0;
  static const cardRadius = 22.0;

  static BoxDecoration card({Color color = BalmiColors.mist}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(cardRadius),
    );
  }

  static TextStyle tracked({
    double size = 10.5,
    Color color = BalmiColors.sub,
    double trackingEm = 0.18,
    FontWeight weight = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: BalmiFonts.wordmark,
      fontFamilyFallback: BalmiFonts.fallbacks,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color,
      letterSpacing: size * trackingEm,
    );
  }

  static TextStyle num({
    double size = 21,
    FontWeight weight = FontWeight.w800,
    Color color = BalmiColors.ink,
    double height = 1.02,
  }) {
    return TextStyle(
      fontFamily: BalmiFonts.wordmark,
      fontFamilyFallback: BalmiFonts.fallbacks,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color,
      height: height,
      letterSpacing: -0.02 * size,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color color = BalmiColors.ink,
    double height = 1.45,
  }) {
    return TextStyle(
      fontFamily: BalmiFonts.wordmark,
      fontFamilyFallback: BalmiFonts.fallbacks,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color,
      height: height,
    );
  }

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: BalmiColors.potato,
      onPrimary: Colors.white,
      secondary: BalmiColors.activeOrange,
      onSecondary: Colors.white,
      tertiary: BalmiColors.sage,
      onTertiary: Colors.white,
      surface: BalmiColors.surface,
      onSurface: BalmiColors.ink,
      outline: BalmiColors.line,
      error: BalmiColors.critical,
    );
    final text = TextTheme(
      displayLarge: num(size: 74, weight: FontWeight.w800),
      displayMedium: num(size: 44, weight: FontWeight.w800),
      headlineMedium: body(size: 24, weight: FontWeight.w800),
      titleLarge: body(size: 20, weight: FontWeight.w800),
      titleMedium: body(size: 16, weight: FontWeight.w800),
      bodyLarge: body(size: 16, weight: FontWeight.w600),
      bodyMedium: body(size: 14, weight: FontWeight.w600, color: BalmiColors.ink),
      bodySmall: body(size: 12, weight: FontWeight.w600, color: BalmiColors.sub),
      labelLarge: body(size: 15, weight: FontWeight.w800),
      labelMedium: tracked(size: 11.5, trackingEm: 0.14, color: BalmiColors.sub),
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: BalmiColors.paper,
      canvasColor: BalmiColors.paper,
      fontFamily: BalmiFonts.wordmark,
      textTheme: text,
      iconTheme: const IconThemeData(color: BalmiColors.sub),
      appBarTheme: const AppBarTheme(
        backgroundColor: BalmiColors.paper,
        foregroundColor: BalmiColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: BalmiFonts.wordmark,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: BalmiColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: BalmiColors.mist,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      dividerColor: BalmiColors.line,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BalmiColors.potato,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: body(size: 16, weight: FontWeight.w800, color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BalmiColors.potato,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: const BorderSide(color: BalmiColors.potato, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: body(size: 16, weight: FontWeight.w800, color: BalmiColors.potato),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BalmiColors.potato,
          textStyle: body(size: 14, weight: FontWeight.w800, color: BalmiColors.potato),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BalmiColors.activeOrange,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: BalmiColors.ink,
        contentTextStyle: TextStyle(
          fontFamily: BalmiFonts.wordmark,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
