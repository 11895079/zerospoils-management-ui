import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerospoils/core/theme/app_colors.dart';
import 'package:zerospoils/presentation/themes/app_theme.dart';

void main() {
  group('Dark theme tokens', () {
    test('dark theme reports dark brightness', () {
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
      expect(AppTheme.darkTheme.colorScheme.brightness, Brightness.dark);
    });

    test('dark semantic text tokens are lighter than dark surfaces', () {
      expect(
        AppColors.textPrimaryDark.computeLuminance(),
        greaterThan(AppColors.backgroundDark.computeLuminance()),
      );
      expect(
        AppColors.textSecondaryDark.computeLuminance(),
        greaterThan(AppColors.backgroundDark.computeLuminance()),
      );
      expect(
        AppColors.textTertiaryDark.computeLuminance(),
        greaterThan(AppColors.backgroundDark.computeLuminance()),
      );
    });

    test('dark semantic surfaces remain distinct from text tokens', () {
      expect(AppColors.cardBackgroundDark, isNot(AppColors.textPrimaryDark));
      expect(AppColors.backgroundSecondaryDark, isNot(AppColors.textSecondaryDark));
      expect(AppColors.borderDark, isNot(AppColors.textTertiaryDark));
    });
  });
}
