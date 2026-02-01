import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors matching the uploaded design
  static const Color emeraldGreen = Color(0xFF0E693F); // Deep Saudi Green
  static const Color emeraldLight = Color(0xFFE6F4EA); // Light green for backgrounds
  
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
        background: backgroundLight,
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
      chipTheme: ChipThemeData(
        backgroundColor: emeraldLight,
        labelStyle: const TextStyle(color: emeraldGreen, fontWeight: FontWeight.w600),
        shape: const StadiumBorder(),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
}
