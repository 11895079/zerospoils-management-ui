// Application theme configuration
// Applies design tokens to Flutter Material theme
import 'package:flutter/material.dart';
import '../../core/constants/design_tokens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      // Text themes
      textTheme: _buildLightTextTheme(),
      // App bar theme
      appBarTheme: AppBarThemeData(
        elevation: AppElevation.sm,
        centerTitle: false,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        titleTextStyle: const TextStyle(
          fontSize: AppTypography.titleSize,
          fontWeight: FontWeight.w600,
          color: AppColors.surface,
        ),
      ),
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          minimumSize: const Size.square(AppTouchTargets.minimum),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          textStyle: const TextStyle(
            fontSize: AppTypography.subtitleSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.square(AppTouchTargets.minimum),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          side: const BorderSide(color: AppColors.primary, width: 2),
          textStyle: const TextStyle(
            fontSize: AppTypography.subtitleSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: AppElevation.md,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: AppTypography.bodySize,
        ),
      ),
      // FAB theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        elevation: AppElevation.lg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        ),
      ),
      // Scaffold background
      scaffoldBackgroundColor: AppColors.background,
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: _buildDarkTextTheme(),
      appBarTheme: AppBarThemeData(
        elevation: AppElevation.sm,
        centerTitle: false,
        backgroundColor: const Color(0xFF101513),
        foregroundColor: const Color(0xFFF2F6F2),
        titleTextStyle: const TextStyle(
          fontSize: AppTypography.titleSize,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF2F6F2),
        ),
      ),
      cardColor: const Color(0xFF1A201D),
      dividerColor: const Color(0xFF2C3631),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: const Color(0xFF102114),
          minimumSize: const Size.square(AppTouchTargets.minimum),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          textStyle: const TextStyle(
            fontSize: AppTypography.subtitleSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          minimumSize: const Size.square(AppTouchTargets.minimum),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          side: const BorderSide(color: AppColors.primaryLight, width: 2),
          textStyle: const TextStyle(
            fontSize: AppTypography.subtitleSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E2722),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: const BorderSide(color: Color(0xFF2F3C35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: const BorderSide(color: Color(0xFF2F3C35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFFAAB6AE),
          fontSize: AppTypography.bodySize,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: const Color(0xFF102114),
        elevation: AppElevation.lg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFF121714),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: AppElevation.md,
        backgroundColor: Color(0xFF171E1A),
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: Color(0xFF9DA8A1),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static TextTheme _buildLightTextTheme() {
    return TextTheme(
      displayLarge: const TextStyle(
        fontSize: AppTypography.displaySize,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: AppTypography.tightLineHeight,
      ),
      displayMedium: const TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: AppTypography.tightLineHeight,
      ),
      displaySmall: const TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: AppTypography.tightLineHeight,
      ),
      headlineMedium: const TextStyle(
        fontSize: AppTypography.largeHeadingSize,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: AppTypography.normalLineHeight,
      ),
      headlineSmall: const TextStyle(
        fontSize: AppTypography.headingSize,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: AppTypography.normalLineHeight,
      ),
      titleLarge: const TextStyle(
        fontSize: AppTypography.titleSize,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: AppTypography.normalLineHeight,
      ),
      titleMedium: const TextStyle(
        fontSize: AppTypography.subtitleSize,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: AppTypography.normalLineHeight,
      ),
      titleSmall: const TextStyle(
        fontSize: AppTypography.bodySize,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: AppTypography.normalLineHeight,
      ),
      bodyLarge: const TextStyle(
        fontSize: AppTypography.subtitleSize,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: AppTypography.relaxedLineHeight,
      ),
      bodyMedium: const TextStyle(
        fontSize: AppTypography.bodySize,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: AppTypography.relaxedLineHeight,
      ),
      bodySmall: const TextStyle(
        fontSize: AppTypography.captionSize,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        height: AppTypography.relaxedLineHeight,
      ),
      labelLarge: const TextStyle(
        fontSize: AppTypography.bodySize,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      labelMedium: const TextStyle(
        fontSize: AppTypography.captionSize,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      labelSmall: const TextStyle(
        fontSize: 11.0,
        fontWeight: FontWeight.w500,
        color: AppColors.textHint,
      ),
    );
  }

  static TextTheme _buildDarkTextTheme() {
    const textPrimary = Color(0xFFF2F6F2);
    const textSecondary = Color(0xFFC2CEC6);
    const textHint = Color(0xFF95A39B);

    return TextTheme(
      displayLarge: const TextStyle(
        fontSize: AppTypography.displaySize,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: AppTypography.tightLineHeight,
      ),
      displayMedium: const TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: AppTypography.tightLineHeight,
      ),
      displaySmall: const TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: AppTypography.tightLineHeight,
      ),
      headlineMedium: const TextStyle(
        fontSize: AppTypography.largeHeadingSize,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: AppTypography.normalLineHeight,
      ),
      headlineSmall: const TextStyle(
        fontSize: AppTypography.headingSize,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: AppTypography.normalLineHeight,
      ),
      titleLarge: const TextStyle(
        fontSize: AppTypography.titleSize,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: AppTypography.normalLineHeight,
      ),
      titleMedium: const TextStyle(
        fontSize: AppTypography.subtitleSize,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        height: AppTypography.normalLineHeight,
      ),
      titleSmall: const TextStyle(
        fontSize: AppTypography.bodySize,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        height: AppTypography.normalLineHeight,
      ),
      bodyLarge: const TextStyle(
        fontSize: AppTypography.subtitleSize,
        fontWeight: FontWeight.normal,
        color: textPrimary,
        height: AppTypography.relaxedLineHeight,
      ),
      bodyMedium: const TextStyle(
        fontSize: AppTypography.bodySize,
        fontWeight: FontWeight.normal,
        color: textPrimary,
        height: AppTypography.relaxedLineHeight,
      ),
      bodySmall: const TextStyle(
        fontSize: AppTypography.captionSize,
        fontWeight: FontWeight.normal,
        color: textSecondary,
        height: AppTypography.relaxedLineHeight,
      ),
      labelLarge: const TextStyle(
        fontSize: AppTypography.bodySize,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      labelMedium: const TextStyle(
        fontSize: AppTypography.captionSize,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      labelSmall: const TextStyle(
        fontSize: 11.0,
        fontWeight: FontWeight.w500,
        color: textHint,
      ),
    );
  }
}
