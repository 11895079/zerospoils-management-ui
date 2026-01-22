library;

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class ItemDetailScreen extends StatelessWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Item Details', style: AppTextStyles.h3),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item ID: $itemId', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'This is a placeholder item detail view. The next steps will wire this screen to the repository and display item properties like quantity, location, and expiry.',
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }
}
