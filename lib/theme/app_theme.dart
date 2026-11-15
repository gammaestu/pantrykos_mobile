import 'package:flutter/material.dart';

class AppTheme {
  // === Layout Radii ===
  static const double cardRadius = 22.0;
  static const double pillRadius = 999.0;

  // === Primary Dark Green (Hijau Tua) ===
  static const Color forestEmerald = Color(0xFF14532D);
  static const Color botanicalGreen = Color(0xFF166534);

  // === Secondary Light Green (Hijau Muda) ===
  static const Color mintLeaf = Color(0xFF22C55E);
  static const Color brightMint = Color(0xFF4ADE80);
  static const Color laserGreenEnd = Color(0xFF16A34A);
  static const Color sageMint = Color(0xFFDCFCE7);
  static const Color softMintTint = Color(0xFFF0FDF4);
  static const Color shimmerBase = Color(0xFFE8F3EC);

  // === Clean White & Soft Off-White Surfaces ===
  static const Color scaffoldMintWhite = Color(0xFFF6FAF7);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color borderMint = Color(0xFFDCFCE7);
  static const Color borderNeutral = Color(0xFFE2E8F0);
  static const Color borderSlateLight = Color(0xFFCBD5E1);

  // === Typography Colors ===
  static const Color textForestCharcoal = Color(0xFF0F291E);
  static const Color textSageGrey = Color(0xFF526D61);

  // === Match Status Badge Colors ===
  static const Color readyText = forestEmerald;
  static const Color readyPill = sageMint;
  static const Color readyBorder = mintLeaf;

  static const Color almostText = Color(0xFF92400E);
  static const Color almostPill = Color(0xFFFEF3C7);
  static const Color almostBorder = Color(0xFFFDE68A);

  // === Gradients ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [forestEmerald, botanicalGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient scanFabGradient = LinearGradient(
    colors: [botanicalGreen, mintLeaf],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient scannerLaserGradient = LinearGradient(
    colors: [brightMint, laserGreenEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardSurfaceGradient = LinearGradient(
    colors: [pureWhite, softMintTint],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // === Shadows ===
  static List<BoxShadow> softShadow(BuildContext context) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];
  }

  static List<BoxShadow> glowShadow(Color color, {double alpha = 0.22}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: 16,
        spreadRadius: 1,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // === Light Culinary Theme (Default Material 3) ===
  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    const colorScheme = ColorScheme.light(
      primary: forestEmerald,
      onPrimary: pureWhite,
      primaryContainer: sageMint,
      onPrimaryContainer: forestEmerald,
      secondary: mintLeaf,
      onSecondary: pureWhite,
      secondaryContainer: softMintTint,
      onSecondaryContainer: botanicalGreen,
      tertiary: botanicalGreen,
      onTertiary: pureWhite,
      surface: pureWhite,
      onSurface: textForestCharcoal,
      onSurfaceVariant: textSageGrey,
      outline: borderNeutral,
      outlineVariant: borderMint,
      error: Color(0xFFDC2626),
      onError: pureWhite,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldMintWhite,
      canvasColor: pureWhite,
      textTheme: _buildTextTheme(baseTextTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldMintWhite,
        foregroundColor: textForestCharcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textForestCharcoal,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: forestEmerald),
      ),
      cardTheme: CardThemeData(
        color: pureWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderNeutral, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forestEmerald,
          foregroundColor: pureWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: forestEmerald,
          foregroundColor: pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: forestEmerald,
          side: const BorderSide(color: borderMint, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: scaffoldMintWhite,
        selectedColor: sageMint,
        disabledColor: borderNeutral,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textForestCharcoal,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: forestEmerald,
        ),
        side: BorderSide(color: borderNeutral),
        shape: StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pureWhite,
        hintStyle: const TextStyle(
          color: textSageGrey,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderMint, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderMint, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: mintLeaf, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderNeutral,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: forestEmerald,
        contentTextStyle: const TextStyle(
          color: pureWhite,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: pureWhite,
        modalBackgroundColor: pureWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: textForestCharcoal,
        letterSpacing: -0.8,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: textForestCharcoal,
        letterSpacing: -0.6,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: textForestCharcoal,
        letterSpacing: -0.3,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: textForestCharcoal,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: textForestCharcoal,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: textSageGrey,
        height: 1.45,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
    );
  }
}
