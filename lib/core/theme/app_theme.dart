import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors — Worqly by xoviq Labs
  static const Color emeraldGreen = Color(0xFF0D1B2E); // Worqly Navy
  static const Color emeraldLight = Color(0xFFEEF2F7); // Light navy tint
  
  static const Color accentGold = Color(0xFFD4AF37); // Premium Gold
  static const Color accentGoldLight = Color(0xFFFEF9C3);
  
  static const Color darkBlue = Color(0xFF1E293B); // Dark slate for text/icons
  
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF3F4F6); // Very light grey background
  
  static const Color errorRed = Color(0xFFEF4444);
  static const Color errorRedLight = Color(0xFFFEE2E2);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Color Scheme
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
      
      // Typography
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: darkBlue,
        displayColor: emeraldGreen,
      ).copyWith(
        headlineMedium: GoogleFonts.outfit(
          color: darkBlue,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: GoogleFonts.outfit(
          color: darkBlue,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.outfit(
          color: darkBlue,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: emeraldGreen,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: emeraldGreen),
      ),
      
      // Card Theme (Rounded & Soft Shadow)
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0, // Using manual shadows usually, but default 0 for flat look
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // More rounded as per design
          side: BorderSide.none,
        ),
      ),
      
      // Chip Theme
      chipTheme: const ChipThemeData(
        backgroundColor: emeraldLight,
        labelStyle: TextStyle(color: emeraldGreen, fontWeight: FontWeight.w600),
        shape: StadiumBorder(),
        side: BorderSide.none,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      
      // FAB Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: emeraldGreen,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      // Input Text Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none, // cleanly flat usually
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: emeraldGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emeraldGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600, 
            fontSize: 16
          ),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: emeraldGreen,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: emeraldGreen,
        size: 24,
      ),
      
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkSurface = Color(0xFF1E2530);
    const darkBackground = Color(0xFF141920);
    const darkCard = Color(0xFF252D3A);
    const darkBorder = Color(0xFF2E3847);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: accentGold,
        secondary: accentGold,
        surface: darkCard,
        onPrimary: Colors.black,
        onSurface: Colors.white,
        error: errorRed,
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white,
        displayColor: accentGold,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: accentGold,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: accentGold),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 1),
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentGold, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        hintStyle: const TextStyle(color: Colors.grey),
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
        unselectedItemColor: Colors.grey,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: accentGold,
        unselectedLabelColor: Colors.grey,
        indicatorColor: accentGold,
      ),
    );
  }
}
