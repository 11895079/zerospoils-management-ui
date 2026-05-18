library;

/// Color tokens extracted from prototype
/// Primary: Green tones for success/freshness
/// Secondary: Warning/danger states
/// Neutral: Backgrounds, text, borders

import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors (green = freshness, zero waste)
  static const Color primary = Color(0xFF2F9E44);
  static const Color primaryDark = Color(0xFF1F6F30);
  static const Color primaryLight = Color(0xFF51CF66);

  // Accent/Secondary
  static const Color accent = Color(0xFF667EEA);
  static const Color accentDark = Color(0xFF764BA2);

  // Status colors
  static const Color success = Color(0xFF2F9E44);
  static const Color warning = Color(0xFFFFA94D);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF339AF0);

  // Neutral palette
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF8F9FA);
  static const Color cardBackground = Color(0xFFF8F9FA);
  static const Color surface = cardBackground;
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);

  // Dark mode semantic palette (M4/296 baseline)
  static const Color textPrimaryDark = Color(0xFFF2F6F2);
  static const Color textSecondaryDark = Color(0xFFC8CED8);
  static const Color textTertiaryDark = Color(0xFF98A2B3);
  static const Color backgroundDark = Color(0xFF101513);
  static const Color backgroundSecondaryDark = Color(0xFF151C19);
  static const Color cardBackgroundDark = Color(0xFF1A201D);
  static const Color surfaceDark = cardBackgroundDark;
  static const Color borderDark = Color(0xFF2C3631);
  static const Color borderLightDark = Color(0xFF3A4540);

  // Dark mode state overlays
  static const Color overlayDarkMode = Color(0x8F000000);
  static const Color overlayLightDarkMode = Color(0x14FFFFFF);

  // Overlay colors
  static const Color overlayDark = Color(0x59000000); // rgba(0,0,0,0.35)
  static const Color overlayLight = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)

  // Card shadows
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x1A000000);

  // Gradient (for background if needed)
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
  );
}
