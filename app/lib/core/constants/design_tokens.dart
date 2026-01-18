// Design tokens from planning/docs/design-tokens.md
// Standardized spacing, typography, colors, and accessibility constants
import 'package:flutter/material.dart';

/// Spacing scale (8pt base)
abstract class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Typography scale
abstract class AppTypography {
  // Font sizes
  static const double captionSize = 12.0;
  static const double bodySize = 14.0;
  static const double subtitleSize = 16.0;
  static const double titleSize = 18.0;
  static const double headingSize = 20.0;
  static const double largeHeadingSize = 24.0;
  static const double displaySize = 32.0;

  // Line heights
  static const double tightLineHeight = 1.2;
  static const double normalLineHeight = 1.5;
  static const double relaxedLineHeight = 1.75;
}

/// Color palette
abstract class AppColors {
  // Primary
  static const Color primary = Color(0xff1b5e20); // Green
  static const Color primaryLight = Color(0xff4caf50);
  static const Color primaryDark = Color(0xff0d3817);

  // Secondary
  static const Color secondary = Color(0xffff9800); // Orange
  static const Color secondaryLight = Color(0xffffb74d);
  static const Color secondaryDark = Color(0xfff57c00);

  // Danger/Error
  static const Color error = Color(0xffd32f2f); // Red
  static const Color errorLight = Color(0xffef5350);
  static const Color errorDark = Color(0xffc62828);

  // Neutral
  static const Color background = Color(0xfffafafa);
  static const Color surface = Color(0xffffffff);
  static const Color surfaceVariant = Color(0xfff5f5f5);
  static const Color border = Color(0xffe0e0e0);

  // Text
  static const Color textPrimary = Color(0xff212121);
  static const Color textSecondary = Color(0xff757575);
  static const Color textHint = Color(0xffbdbdbd);

  // Success
  static const Color success = Color(0xff388e3c); // Dark green
}

/// Touch target sizes (accessibility)
abstract class AppTouchTargets {
  static const double minimum = 44.0; // WCAG AA minimum
  static const double medium = 48.0;
  static const double large = 56.0;
}

/// Border radius
abstract class AppBorderRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double circular = 50.0;
}

/// Elevation/shadows
abstract class AppElevation {
  static const double none = 0.0;
  static const double sm = 2.0;
  static const double md = 4.0;
  static const double lg = 8.0;
  static const double xl = 16.0;
}
