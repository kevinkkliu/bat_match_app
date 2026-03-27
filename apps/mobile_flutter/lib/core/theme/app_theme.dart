import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const Color seed = Color(0xFF1C5E3D);
    const Color surface = Color(0xFFF4F0E7);
    const Color surfaceAlt = Color(0xFFFBF8F1);
    const Color outline = Color(0xFFD5DDCF);
    const Color textPrimary = Color(0xFF173321);
    const Color textSecondary = Color(0xFF5E6D63);
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      surface: surface,
    ).copyWith(
      primary: seed,
      secondary: const Color(0xFF8A6A2D),
      surface: surface,
      surfaceContainerLowest: surfaceAlt,
      surfaceContainerLow: surfaceAlt,
      surfaceContainer: Colors.white,
      surfaceContainerHigh: Colors.white,
      surfaceContainerHighest: Colors.white,
      outline: outline,
      outlineVariant: const Color(0xFFE3E8DE),
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      onPrimary: Colors.white,
    );

    final TextTheme baseTextTheme = ThemeData.light().textTheme.apply(
          bodyColor: textPrimary,
          displayColor: textPrimary,
        );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      textTheme: baseTextTheme.copyWith(
        displayLarge: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
          height: 1.02,
          color: textPrimary,
          fontFamily: '.SF Pro Display',
          fontFamilyFallback: _appleStyleFallbacks,
        ),
        displayMedium: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.9,
          height: 1.04,
          color: textPrimary,
          fontFamily: '.SF Pro Display',
          fontFamilyFallback: _appleStyleFallbacks,
        ),
        headlineLarge: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          height: 1.05,
          color: textPrimary,
          fontFamily: '.SF Pro Display',
          fontFamilyFallback: _appleStyleFallbacks,
        ),
        headlineMedium: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          height: 1.08,
          color: textPrimary,
          fontFamily: '.SF Pro Display',
          fontFamilyFallback: _appleStyleFallbacks,
        ),
        titleLarge: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: textPrimary,
          fontFamily: '.SF Pro Display',
          fontFamilyFallback: _appleStyleFallbacks,
        ),
        titleMedium: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: textPrimary,
          fontFamily: '.SF Pro Text',
          fontFamilyFallback: _appleStyleFallbacks,
        ),
        bodyLarge: const TextStyle(
          height: 1.5,
          color: textPrimary,
          fontFamily: '.SF Pro Text',
          fontFamilyFallback: _appleStyleFallbacks,
        ),
        bodyMedium: const TextStyle(
          height: 1.5,
          color: textPrimary,
          fontFamily: '.SF Pro Text',
          fontFamilyFallback: _appleStyleFallbacks,
        ),
        bodySmall: const TextStyle(
          height: 1.45,
          color: textSecondary,
          fontFamily: '.SF Pro Text',
          fontFamilyFallback: _appleStyleFallbacks,
        ),
        labelLarge: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          color: textPrimary,
          fontFamily: '.SF Pro Text',
          fontFamilyFallback: _appleStyleFallbacks,
        ),
        labelMedium: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05,
          color: textSecondary,
          fontFamily: '.SF Pro Text',
          fontFamilyFallback: _appleStyleFallbacks,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFFE4E8DD)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          fontFamily: '.SF Pro Display',
          fontFamilyFallback: _appleStyleFallbacks,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        elevation: 0,
        indicatorColor: const Color(0xFFE8F1E3),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (Set<WidgetState> states) => TextStyle(
            color: states.contains(WidgetState.selected) ? seed : textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
          (Set<WidgetState> states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? seed : textSecondary,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            fontFamily: '.SF Pro Text',
            fontFamilyFallback: _appleStyleFallbacks,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: seed,
          side: const BorderSide(color: outline),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            fontFamily: '.SF Pro Text',
            fontFamilyFallback: _appleStyleFallbacks,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: seed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFC95A4A)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE4E8DD),
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: seed,
      ),
    );
  }
}

const List<String> _appleStyleFallbacks = <String>[
  'PingFang TC',
  'PingFang SC',
  'Helvetica Neue',
  'Arial',
];
