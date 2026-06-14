import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors — Workly by xoviq Labs
  static const Color emeraldGreen = Color(0xFF0D1B2E); // Workly Navy
  static const Color emeraldLight = Color(0xFFEEF2F7); // Light navy tint

  // Navy gradient palette
  static const Color navyDark = Color(0xFF0B172A);
  static const Color navyDeep = Color(0xFF1A2E4A);
  static const Color navyMid  = Color(0xFF0F2038);

  static const Color accentGold      = Color(0xFFD4AF37);
  static const Color accentGoldLight = Color(0xFFFEF9C3);

  static const Color darkBlue = Color(0xFF1E293B);

  // Gradient helpers for card and button overlays
  static const Gradient primaryGradient = LinearGradient(
    colors: [emeraldGreen, Color(0xFF1E2A3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD4AF37)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color surfaceWhite  = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF0F4F8); // Soft blue-grey tint

  // Status colors
  static const Color successGreen      = Color(0xFF22C55E);
  static const Color successGreenLight = Color(0xFF4ADE80);
  static const Color chartTeal         = Color(0xFF34D399);

  // Semantic stat colors
  static const Color statBlue   = Color(0xFF3B82F6);
  static const Color statAmber  = Color(0xFFF59E0B);
  static const Color statPurple = Color(0xFFA855F7);

  static const Color errorRed      = Color(0xFFEF4444);
  static const Color errorRedLight = Color(0xFFFEE2E2);

  // ── Dark theme surfaces ───────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F1520);
  static const Color darkSurface    = Color(0xFF1A2332);
  static const Color darkCard       = Color(0xFF1E2A3C);
  static const Color darkCardAlt    = Color(0xFF243044);
  static const Color darkBorder     = Color(0xFF2A3A52);
  static const Color darkOnSurface  = Color(0xFFE2E8F0);
  static const Color darkSubtext    = Color(0xFF64748B);

  // ── Glassmorphism tokens ──────────────────────────────────────────
  // Light glass: near-opaque frosted white
  static const Color glassLight       = Color(0xBFFFFFFF); // 75% white
  static const Color glassBorderLight = Color(0x99FFFFFF); // 60% white border
  // Dark glass: very subtle overlay on deep background
  static const Color glassDark       = Color(0x0DFFFFFF); //  5% white on dark
  static const Color glassBorderDark = Color(0x14FFFFFF); //  8% white border

  // ── Multi-layer shadows for subtle depth ─────────────────────────
  // Light mode
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x08000000), blurRadius: 8,  offset: Offset(0, 2)),
    BoxShadow(color: Color(0x04000000), blurRadius: 2,  offset: Offset(0, 0)),
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x06000000), blurRadius: 6,  offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> shadowLg = [
    BoxShadow(color: Color(0x14000000), blurRadius: 32, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0,  3)),
    BoxShadow(color: Color(0x03000000), blurRadius: 2,  offset: Offset(0,  0)),
  ];
  // Dark mode (more pronounced)
  static const List<BoxShadow> shadowDarkMd = [
    BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 6,  offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> shadowDarkLg = [
    BoxShadow(color: Color(0x60000000), blurRadius: 32, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x28000000), blurRadius: 10, offset: Offset(0,  3)),
  ];

  // Convenience: pick shadow set by brightness
  static List<BoxShadow> cardShadow(bool isDark) =>
      isDark ? shadowDarkMd : shadowMd;

  // ── Glass BoxDecoration helper ────────────────────────────────────
  static BoxDecoration glassDecoration({
    required bool isDark,
    double borderRadius = 20,
    List<BoxShadow>? shadows,
    Gradient? gradient,
    Color? color,
  }) {
    return BoxDecoration(
      color: gradient == null ? (color ?? (isDark ? glassDark : glassLight)) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark ? glassBorderDark : glassBorderLight,
        width: 1,
      ),
      boxShadow: shadows ?? cardShadow(isDark),
    );
  }

  // ─────────────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: emeraldGreen,
        primary: emeraldGreen,
        secondary: accentGold,
        surface: surfaceWhite,
        onPrimary: Colors.white,
        onSurface: darkBlue,
        error: errorRed,
      ),
      scaffoldBackgroundColor: backgroundLight,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: darkBlue,
        displayColor: emeraldGreen,
      ).copyWith(
        headlineMedium: GoogleFonts.outfit(color: darkBlue, fontWeight: FontWeight.bold),
        headlineSmall:  GoogleFonts.outfit(color: darkBlue, fontWeight: FontWeight.bold),
        titleLarge:     GoogleFonts.outfit(color: darkBlue, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: emeraldGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: emeraldGreen),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x0D000000), width: 1),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: emeraldLight,
        labelStyle: TextStyle(color: emeraldGreen, fontWeight: FontWeight.w600),
        shape: StadiumBorder(),
        side: BorderSide.none,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: emeraldGreen,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x14000000)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x14000000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: emeraldGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emeraldGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: emeraldGreen,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: const IconThemeData(color: emeraldGreen, size: 24),
      dividerTheme: DividerThemeData(color: Colors.grey.shade200, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        indicatorColor: emeraldGreen.withValues(alpha: 0.12),
        height: 68,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: emeraldGreen, size: 22);
          }
          return const IconThemeData(color: Colors.grey, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: emeraldGreen);
          }
          return const TextStyle(fontSize: 11, color: Colors.grey);
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: accentGold,
        secondary: accentGold,
        surface: darkCard,
        surfaceContainerHighest: darkCardAlt,
        onPrimary: Colors.black,
        onSurface: darkOnSurface,
        error: errorRed,
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: darkOnSurface,
        displayColor: accentGold,
      ).copyWith(
        headlineMedium: GoogleFonts.outfit(color: darkOnSurface, fontWeight: FontWeight.bold),
        headlineSmall:  GoogleFonts.outfit(color: darkOnSurface, fontWeight: FontWeight.bold),
        titleLarge:     GoogleFonts.outfit(color: darkOnSurface, fontWeight: FontWeight.w600),
        bodyMedium:     GoogleFonts.outfit(color: darkOnSurface),
        bodySmall:      GoogleFonts.outfit(color: darkSubtext),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: accentGold),
        titleTextStyle: TextStyle(
          color: darkOnSurface,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: const CardThemeData(
        color: darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: darkBorder, width: 1),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: darkBorder,
        labelStyle: TextStyle(color: accentGold, fontWeight: FontWeight.w600),
        shape: StadiumBorder(),
        side: BorderSide.none,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentGold,
        foregroundColor: Colors.black,
        elevation: 4,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: accentGold, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        hintStyle: TextStyle(color: darkSubtext),
        labelStyle: TextStyle(color: Color(0xFF94A3B8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentGold,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: const IconThemeData(color: accentGold, size: 24),
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: accentGold,
        unselectedItemColor: darkSubtext,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: accentGold.withValues(alpha: 0.15),
        height: 68,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: accentGold, size: 22);
          }
          return const IconThemeData(color: darkSubtext, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: accentGold);
          }
          return const TextStyle(fontSize: 11, color: darkSubtext);
        }),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: accentGold,
        unselectedLabelColor: darkSubtext,
        indicatorColor: accentGold,
      ),
    );
  }
}
