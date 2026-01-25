library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../di/repository_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _persistDemoMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('demo_mode_enabled', enabled);
  }

  Future<void> _clearAllItems(WidgetRef ref) async {
    final repository = ref.read(itemRepositoryProvider);
    await repository.init();
    await repository.clear();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoEnabled = ref.watch(demoModeProvider);
    final hasManualItems = ref.watch(hasManualItemsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Settings', style: AppTextStyles.h3),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Demo Mode', style: AppTextStyles.h4),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        hasManualItems
                            ? 'Demo mode is disabled after manual items are added.'
                            : 'Preload sample items for quick exploration. Will turn off automatically after you add your first item.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: demoEnabled,
                  onChanged: hasManualItems
                      ? null
                      : (value) async {
                          // Update provider and persist
                          ref.read(demoModeProvider.notifier).state = value;
                          await _persistDemoMode(value);

                          // Clear items if turning off demo mode
                          if (!value) {
                            await _clearAllItems(ref);
                          }

                          // Force refresh of inventory list
                          ref.invalidate(itemsFutureProvider);

                          // Show feedback
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'Demo mode enabled'
                                      : 'Demo mode disabled',
                                ),
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('About', style: AppTextStyles.h4),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'ZeroSpoils helps households reduce food waste by tracking inventory, expiry, and usage.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
