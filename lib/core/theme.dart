import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Official balmi 앱 목업 v2 tokens. Do not invent a second palette.
abstract final class BalmiColors {
  static const paper = Color(0xFFFAF6EF);
  static const ink = Color(0xFF2E2320);
  static const plum = Color(0xFF6E3B4B);
  static const plumLt = Color(0xFFC98FA1);
  static const amber = Color(0xFFE39A3B);
  static const sage = Color(0xFF7C8F6D);
  static const line = Color(0xFFE4DCCB);
  static const sub = Color(0xFF8A7F72);
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
      primary: BalmiColors.plum,
      onPrimary: BalmiColors.paper,
      secondary: BalmiColors.sage,
      onSecondary: BalmiColors.paper,
      surface: BalmiColors.paper,
      onSurface: BalmiColors.ink,
      outline: BalmiColors.line,
      error: Color(0xFFB0442F),
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
      labelMedium: tracked(size: 11.5, trackingEm: 0.14, color: BalmiColors.plum),
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: BalmiColors.paper,
      canvasColor: BalmiColors.paper,
      fontFamily: BalmiFonts.wordmark,
      textTheme: text,
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
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: BalmiColors.line),
        ),
      ),
      dividerColor: BalmiColors.line,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BalmiColors.plum,
          foregroundColor: BalmiColors.paper,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: body(size: 16, weight: FontWeight.w800, color: BalmiColors.paper),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BalmiColors.plum,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: const BorderSide(color: BalmiColors.plum, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: body(size: 16, weight: FontWeight.w800, color: BalmiColors.plum),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BalmiColors.plum,
          textStyle: body(size: 14, weight: FontWeight.w800, color: BalmiColors.plum),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: BalmiColors.ink,
        contentTextStyle: TextStyle(
          fontFamily: BalmiFonts.wordmark,
          color: BalmiColors.paper,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
