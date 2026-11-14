import 'package:flutter/material.dart';

/// Design System & Visual Identity for PantryKos.
/// Implements the "Elegant Midnight Navy Dark Theme" with Electric Sapphire
/// & Cyan gradients, Translucent Royal Blue active chip states, and
/// Neon Emerald / Warm Amber semantic status badges.
class AppTheme {
  AppTheme._();

  // Core Midnight Navy Palette
  static const Color midnightNavyScaffold = Color(0xFF0A0F1D);
  static const Color elevatedSlateSurface = Color(0xFF131C31);
  static const Color elevatedSlateVariant = Color(0xFF1A2642);
  static const Color slateBorder = Color(0xFF263554);

  // Electric Sapphire & Cyan Accents
  static const Color primarySapphire = Color(0xFF3B82F6);
  static const Color gradientBlueStart = Color(0xFF2563EB);
  static const Color gradientCyanEnd = Color(0xFF06B6D4);

  // Active Chip Styling: Translucent Royal Blue (#1E3A8A at 60%) + Glowing #60A5FA Border
  static const Color royalBlueBase = Color(0xFF1E3A8A);
  static Color get activeChipSurface => royalBlueBase.withValues(alpha: 0.60);
  static const Color glowingSkyBorder = Color(0xFF60A5FA);

  // Status Badges
  static const Color emeraldReady = Color(0xFF10B981);
  static const Color emeraldReadySoft = Color(0xFF064E3B);
  static const Color amberAlmost = Color(0xFFF59E0B);
  static const Color amberAlmostSoft = Color(0xFF78350F);

  // Typography Hierarchy
  static const Color iceWhiteTitle = Color(0xFFF8FAFC);
  static const Color mutedSteelSubtitle = Color(0xFF94A3B8);

  // Backwards-compatible semantic aliases used across screens/widgets
  static const Color primaryAccent = primarySapphire;
  static const Color darkBackground = midnightNavyScaffold;
  static const Color darkSurface = elevatedSlateSurface;
  static const Color darkSurfaceVariant = elevatedSlateVariant;
  static const Color darkBorder = slateBorder;
  static const Color darkTextPrimary = iceWhiteTitle;
  static const Color darkTextSecondary = mutedSteelSubtitle;

  static const double cardRadius = 20.0;
  static const double pillRadius = 999.0;

  /// Primary LinearGradient (#2563EB to #06B6D4) for primary buttons & active states
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientBlueStart, gradientCyanEnd],
  );

  /// Subtle surface gradient for elevated cards
  static const LinearGradient cardSurfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF16213A),
      Color(0xFF131C31),
    ],
  );

  /// Soft diffused elevation shadow for Midnight Navy cards
  static List<BoxShadow> softShadow([BuildContext? context]) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.42),
        blurRadius: 22,
        spreadRadius: 0,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: primarySapphire.withValues(alpha: 0.05),
        blurRadius: 12,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Glowing accent shadow for CTAs, active chips & FAB
  static List<BoxShadow> glowShadow(Color color, {double intensity = 0.35}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: intensity),
        blurRadius: 18,
        spreadRadius: 1,
        offset: const Offset(0, 5),
      ),
    ];
  }

  /// Unified Elegant Midnight Navy Dark Theme
  static ThemeData get midnightNavyTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySapphire,
      brightness: Brightness.dark,
      primary: primarySapphire,
      onPrimary: iceWhiteTitle,
      secondary: emeraldReady,
      onSecondary: iceWhiteTitle,
      tertiary: amberAlmost,
      onTertiary: midnightNavyScaffold,
      surface: elevatedSlateSurface,
      onSurface: iceWhiteTitle,
      surfaceContainerHighest: elevatedSlateVariant,
      outline: slateBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: midnightNavyScaffold,
      textTheme: _buildTextTheme(iceWhiteTitle, mutedSteelSubtitle),
      appBarTheme: const AppBarTheme(
        backgroundColor: midnightNavyScaffold,
        foregroundColor: iceWhiteTitle,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: elevatedSlateSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: slateBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevatedSlateSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: slateBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: slateBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: glowingSkyBorder, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primarySapphire,
          foregroundColor: iceWhiteTitle,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme => midnightNavyTheme;
  static ThemeData get darkTheme => midnightNavyTheme;

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: primary,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: primary,
        letterSpacing: -0.4,
        height: 1.25,
      ),
      headlineSmall: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontSize: 16.5,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: secondary,
      ),
      bodyLarge: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: secondary,
        height: 1.45,
      ),
      labelLarge: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: secondary,
        letterSpacing: 0.2,
      ),
    );
  }
}
