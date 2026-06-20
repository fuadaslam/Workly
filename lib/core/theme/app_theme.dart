import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand identity (Worqly — ink-black + signal-yellow) ───────────
  // Ink scale — near-black brand ground (logo, sidebar, primary surfaces).
  static const Color ink900 = Color(0xFF0A0A0B); // logo ground / primary
  static const Color ink800 = Color(0xFF161618);
  static const Color ink700 = Color(0xFF232327);
  static const Color ink600 = Color(0xFF34343A);

  // Signal Yellow — the brand accent (the logo dot).
  static const Color brand700 = Color(0xFFA16207); // accent text on light
  static const Color brand600 = Color(0xFFCA8A04);
  static const Color brand500 = Color(0xFFEAB308); // core brand yellow
  static const Color brand400 = Color(0xFFFACC15);
  static const Color brand50  = Color(0xFFFEFCE8);

  // Legacy aliases kept for compatibility; now point at the ink+yellow brand.
  static const Color emeraldGreen = ink900;          // primary brand ground
  static const Color emeraldLight = Color(0xFFF4F4F5); // neutral zinc-100 tint

  static const Color navyDark = ink900;
  static const Color navyDeep = ink800;
  static const Color navyMid  = ink800;

  // Gold — secondary / brand accent (sidebar logo highlight, FAB)
  static const Color accentGold      = brand500;
  static const Color accentGoldLight = brand50;

  static const Color darkBlue = Color(0xFF18181B); // zinc-900 (headings)

  static const Gradient primaryGradient = LinearGradient(
    colors: [ink900, ink800],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient goldGradient = LinearGradient(
    colors: [brand400, brand600],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color surfaceWhite    = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFFAFAFA); // Sharper SaaS background

  // ── Semantic accent tokens ────────────────────────────────────────
  /// Signal Yellow — primary active / interactive accent (was Electric Blue).
  static const Color electricBlue  = brand500;
  /// Green — success / completed / on-duty / paid.
  static const Color mintGreen     = Color(0xFF16A34A);
  /// Amber — pending / warning states.
  static const Color mutedAmber    = Color(0xFFF59E0B);

  // ── Status hues (work-order domain) ───────────────────────────────
  static const Color statusCompleted = Color(0xFF16A34A); // green-500
  static const Color statusProgress  = Color(0xFF3B82F6); // blue-500
  static const Color statusPending   = Color(0xFFF59E0B); // amber-500
  static const Color statusDanger    = Color(0xFFEF4444); // red-500

  // Kept for backwards-compatibility — point at the new semantic names.
  static const Color successGreen      = mintGreen;
  static const Color successGreenLight = Color(0xFF6EE7B7);
  static const Color chartTeal         = Color(0xFF34D399);

  static const Color statBlue   = electricBlue;
  static const Color statAmber  = mutedAmber;
  static const Color statPurple = Color(0xFFA855F7);

  static const Color errorRed      = Color(0xFFEF4444);
  static const Color errorRedLight = Color(0xFFFEE2E2);

  // ── Dark-mode surfaces (Linear / Vercel aesthetic) ────────────────
  /// Root scaffold background — deepest layer (ink-900).
  static const Color darkBackground = ink900;
  /// Sidebar, top-level panels (ink-800).
  static const Color darkSurface    = ink800;
  /// Card / list-item background (ink-800).
  static const Color darkCard       = ink800;
  /// Hover / alternate card shade (ink-700).
  static const Color darkCardAlt    = ink700;
  /// Thin separator / card border (ink-700).
  static const Color darkBorder     = ink700;
  /// Primary body text on dark.
  static const Color darkOnSurface  = Color(0xFFFAFAFA);
  /// Dimmed / meta text on dark.
  static const Color darkSubtext    = Color(0xFFA1A1AA);

  // ── Glassmorphism tokens ──────────────────────────────────────────
  static const Color glassLight       = Color(0xBFFFFFFF);
  static const Color glassBorderLight = Color(0x99FFFFFF);
  static const Color glassDark        = Color(0x0DFFFFFF);
  static const Color glassBorderDark  = Color(0x14FFFFFF);

  // ── Multi-layer shadows (Flatter SaaS aesthetic) ──────────────────
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> shadowLg = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> shadowDarkMd = [
    BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 6,  offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> shadowDarkLg = [
    BoxShadow(color: Color(0x60000000), blurRadius: 32, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x28000000), blurRadius: 10, offset: Offset(0,  3)),
  ];

  static List<BoxShadow> cardShadow(bool isDark) =>
      isDark ? shadowDarkMd : shadowMd;

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

  // ── Convenience: resolve accent from brightness ───────────────────
  /// Returns the signal-yellow accent, tuned for contrast per mode:
  /// bright yellow on dark, deeper gold on light.
  static Color primaryAccent(bool isDark) =>
      isDark ? brand400 : brand700;

  // ─────────────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    final base = GoogleFonts.interTextTheme();
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
      textTheme: base.apply(
        bodyColor: darkBlue,
        displayColor: emeraldGreen,
      ).copyWith(
        headlineMedium: GoogleFonts.inter(color: darkBlue, fontWeight: FontWeight.w700, letterSpacing: -0.4),
        headlineSmall:  GoogleFonts.inter(color: darkBlue, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleLarge:     GoogleFonts.inter(color: darkBlue, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        titleMedium:    GoogleFonts.inter(color: darkBlue, fontWeight: FontWeight.w600),
        bodyLarge:      GoogleFonts.inter(color: darkBlue),
        bodyMedium:     GoogleFonts.inter(color: darkBlue),
        bodySmall:      GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
        labelSmall:     GoogleFonts.inter(letterSpacing: 0.8, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: emeraldGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: emeraldGreen),
        titleTextStyle: GoogleFonts.inter(
          color: darkBlue,
          fontWeight: FontWeight.w700,
          fontSize: 17,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFEAEAEA), width: 1), // Crisp borders
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: emeraldLight,
        labelStyle: TextStyle(color: emeraldGreen, fontWeight: FontWeight.w600, fontSize: 12),
        shape: StadiumBorder(),
        side: BorderSide.none,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x14000000)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: emeraldGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emeraldGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: emeraldGreen,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: const IconThemeData(color: emeraldGreen, size: 22),
      dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0), thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        indicatorColor: emeraldGreen.withValues(alpha: 0.10),
        height: 64,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: emeraldGreen, size: 22);
          }
          return const IconThemeData(color: Color(0xFF94A3B8), size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: emeraldGreen);
          }
          return GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8));
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        // Signal-yellow as primary interactive color in dark mode.
        primary: electricBlue,
        secondary: accentGold,
        surface: darkCard,
        surfaceContainerHighest: darkCardAlt,
        onPrimary: ink900, // ink text on yellow
        onSurface: darkOnSurface,
        error: errorRed,
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: base.apply(
        bodyColor: darkOnSurface,
        displayColor: darkOnSurface,
      ).copyWith(
        headlineMedium: GoogleFonts.inter(color: darkOnSurface, fontWeight: FontWeight.w700, letterSpacing: -0.4),
        headlineSmall:  GoogleFonts.inter(color: darkOnSurface, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleLarge:     GoogleFonts.inter(color: darkOnSurface, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        titleMedium:    GoogleFonts.inter(color: darkOnSurface, fontWeight: FontWeight.w600),
        bodyLarge:      GoogleFonts.inter(color: darkOnSurface),
        bodyMedium:     GoogleFonts.inter(color: darkOnSurface),
        bodySmall:      GoogleFonts.inter(color: darkSubtext, fontSize: 12),
        labelSmall:     GoogleFonts.inter(color: darkSubtext, letterSpacing: 0.8, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: darkOnSurface),
        titleTextStyle: GoogleFonts.inter(
          color: darkOnSurface,
          fontWeight: FontWeight.w700,
          fontSize: 17,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: const CardThemeData(
        color: darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: darkBorder, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: electricBlue.withValues(alpha: 0.1),
        labelStyle: const TextStyle(color: electricBlue, fontWeight: FontWeight.w600, fontSize: 12),
        shape: const StadiumBorder(),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: electricBlue,
        foregroundColor: ink900,
        elevation: 4,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: electricBlue, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: darkSubtext, fontSize: 14),
        labelStyle: TextStyle(color: Color(0xFF94A3B8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricBlue,
          foregroundColor: ink900,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand400,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: const IconThemeData(color: darkOnSurface, size: 22),
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: electricBlue,
        unselectedItemColor: darkSubtext,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: electricBlue.withValues(alpha: 0.12),
        height: 64,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: electricBlue, size: 22);
          }
          return const IconThemeData(color: darkSubtext, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: electricBlue);
          }
          return GoogleFonts.inter(fontSize: 11, color: darkSubtext);
        }),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: electricBlue,
        unselectedLabelColor: darkSubtext,
        indicatorColor: electricBlue,
        dividerColor: darkBorder,
      ),
    );
  }
}
