library;

/// Primary button matching prototype styles
/// Green filled button with white text

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool small;
  final bool fullWidth;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.secondary = false,
    this.small = false,
    this.fullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = small
        ? AppTextStyles.buttonSmall
        : AppTextStyles.button;
    final height = small ? AppSpacing.buttonHeightSm : AppSpacing.buttonHeight;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary ? Colors.transparent : AppColors.primary,
          foregroundColor: secondary ? AppColors.primary : Colors.white,
          elevation: secondary ? 0 : 2,
          side: secondary
              ? const BorderSide(color: AppColors.primary, width: 1.5)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: small ? AppSpacing.lg : AppSpacing.xl,
          ),
        ),
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: AppSpacing.iconMd),
                  const SizedBox(width: AppSpacing.sm),
                  Text(text, style: buttonStyle),
                ],
              )
            : Text(text, style: buttonStyle),
      ),
    );
  }
}

/// Text button for secondary/cancel actions
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const AppTextButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      child: Text(text, style: AppTextStyles.button),
    );
  }
}
