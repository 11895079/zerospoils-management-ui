library;

/// Expiring Soon screen
/// Shows items grouped by expiry urgency: Today, This Week, Expired

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/item_model.dart';
import '../../domain/utils/expiry_classifier.dart';
import '../../domain/models/expiry_bucket.dart';
import '../di/repository_providers.dart';
import '../di/service_locator.dart' hide itemRepositoryProvider;
import '../widgets/app_button.dart';
import '../widgets/item_card.dart';
import 'package:go_router/go_router.dart';

class ExpiringTodayScreen extends ConsumerStatefulWidget {
  const ExpiringTodayScreen({super.key});

  @override
  ConsumerState<ExpiringTodayScreen> createState() =>
      _ExpiringTodayScreenState();
}

class _ExpiringTodayScreenState extends ConsumerState<ExpiringTodayScreen> {
  bool _isLoading = true;
  List<Item> _items = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadItems();
    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryClientProvider).enqueue({
        'name': 'screen_viewed',
        'properties': {'screen_name': 'expiring_soon'},
      });
    });
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(itemRepositoryProvider);
      await repository.init();
      final items = await repository.getAllItems();

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading items: $e';
          _isLoading = false;
        });
      }
    }
  }

  Map<ExpiryBucket, List<Item>> _groupItemsByBucket() {
    final grouped = <ExpiryBucket, List<Item>>{
      ExpiryBucket.today: [],
      ExpiryBucket.thisWeek: [],
      ExpiryBucket.expired: [],
    };

    for (final item in _items) {
      if (item.status != ItemStatus.available) continue;

      final bucket = ExpiryClassifier.classify(item);
      if (bucket != ExpiryBucket.later) {
        grouped[bucket]!.add(item);
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Expiring Soon', style: AppTextStyles.h3),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _errorMessage!,
                    style: AppTextStyles.body.copyWith(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    text: 'Retry',
                    onPressed: _loadItems,
                    secondary: true,
                  ),
                ],
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final grouped = _groupItemsByBucket();
    final hasExpiringItems = grouped.values.any((items) => items.isNotEmpty);

    if (!hasExpiringItems) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadItems,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (grouped[ExpiryBucket.today]!.isNotEmpty)
            _buildBucketSection(
              ExpiryBucket.today,
              grouped[ExpiryBucket.today]!,
            ),
          if (grouped[ExpiryBucket.thisWeek]!.isNotEmpty)
            _buildBucketSection(
              ExpiryBucket.thisWeek,
              grouped[ExpiryBucket.thisWeek]!,
            ),
          if (grouped[ExpiryBucket.expired]!.isNotEmpty)
            _buildBucketSection(
              ExpiryBucket.expired,
              grouped[ExpiryBucket.expired]!,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✨ 🎉 ✨', style: TextStyle(fontSize: 48)),
          const SizedBox(height: AppSpacing.lg),
          Text('All clear!', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nothing expiring soon.\nGreat job staying on top of\nyour inventory!',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: 'Review Inventory',
            onPressed: () {
              context.go('/');
            },
            secondary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBucketSection(ExpiryBucket bucket, List<Item> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Text(bucket.displayName.toUpperCase(), style: AppTextStyles.h3),
              const SizedBox(width: AppSpacing.sm),
              Text(bucket.emoji, style: const TextStyle(fontSize: 20)),
              const Spacer(),
              Text(
                '(${items.length})',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: GestureDetector(
              onTap: () {
                // Track telemetry
                ref.read(telemetryClientProvider).enqueue({
                  'name': 'item_tapped_from_expiring_soon',
                  'properties': {'item_id': item.id, 'bucket': bucket.name},
                });
                context.pushNamed(
                  'item-detail',
                  pathParameters: {'id': item.id},
                );
              },
              child: ItemCard(item: item),
            ),
          );
        }),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
