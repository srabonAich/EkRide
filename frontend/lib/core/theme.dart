import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Dark Palette
  static const Color darkBackground = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkSurfaceLight = Color(0xFF1E293B);
  static const Color darkCardColor = Color(0xFF131D31);
  static const Color darkCardHover = Color(0xFF1B2844);
  static const Color darkBorder = Color(0xFF22314E);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light Palette
  static const Color lightBackground = Color(0xFFF1F5F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLight = Color(0xFFE2E8F0);
  static const Color lightCardColor = Color(0xFFFFFFFF);
  static const Color lightCardHover = Color(0xFFF8FAFC);
  static const Color lightBorder = Color(0xFFCBD5E1);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF64748B);

  // Backward compatibility static constants (default dark mode)
  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color surfaceLight = darkSurfaceLight;
  static const Color cardColor = darkCardColor;
  static const Color cardHover = darkCardHover;
  static const Color border = darkBorder;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = darkTextMuted;

  // Vibrant Accents (Shared)
  static const Color primary = Color(0xFF10B981); // Emerald
  static const Color primaryGlow = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF34D399);

  static const Color secondary = Color(0xFF06B6D4); // Electric Cyan
  static const Color secondaryLight = Color(0xFF38BDF8);

  static const Color accent = Color(0xFFF59E0B); // Amber / Savings
  static const Color accentLight = Color(0xFFFBBF24);

  static const Color violet = Color(0xFF8B5CF6); // Campus Network Badge
  static const Color violetLight = Color(0xFFA78BFA);

  static const Color danger = Color(0xFFEF4444); // Error / Red

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient violetGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF131D31), Color(0xFF172239)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bestRouteGradient = LinearGradient(
    colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF10B981)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Dynamic Getters
  static Color getBackground(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color getSurface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color getSurfaceLight(bool isDark) => isDark ? darkSurfaceLight : lightSurfaceLight;
  static Color getCardColor(bool isDark) => isDark ? darkCardColor : lightCardColor;
  static Color getCardHover(bool isDark) => isDark ? darkCardHover : lightCardHover;
  static Color getBorder(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color getTextPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color getTextSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color getTextMuted(bool isDark) => isDark ? darkTextMuted : lightTextMuted;

  static ThemeData get darkTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primary,
      cardColor: darkCardColor,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: darkSurface,
        error: danger,
      ),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(color: darkTextPrimary, fontWeight: FontWeight.w900),
        displayMedium: GoogleFonts.plusJakartaSans(color: darkTextPrimary, fontWeight: FontWeight.w800),
        titleLarge: GoogleFonts.plusJakartaSans(color: darkTextPrimary, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.plusJakartaSans(color: darkTextPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.plusJakartaSans(color: darkTextPrimary),
        bodyMedium: GoogleFonts.plusJakartaSans(color: darkTextSecondary),
        bodySmall: GoogleFonts.plusJakartaSans(color: darkTextMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: darkCardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: primaryGlow,
      cardColor: lightCardColor,
      colorScheme: const ColorScheme.light(
        primary: primaryGlow,
        secondary: secondary,
        surface: lightSurface,
        error: danger,
      ),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(color: lightTextPrimary, fontWeight: FontWeight.w900),
        displayMedium: GoogleFonts.plusJakartaSans(color: lightTextPrimary, fontWeight: FontWeight.w800),
        titleLarge: GoogleFonts.plusJakartaSans(color: lightTextPrimary, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.plusJakartaSans(color: lightTextPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.plusJakartaSans(color: lightTextPrimary),
        bodyMedium: GoogleFonts.plusJakartaSans(color: lightTextSecondary),
        bodySmall: GoogleFonts.plusJakartaSans(color: lightTextMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: lightCardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
    );
  }
}
