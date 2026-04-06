library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/adapters/receipt_batch_adapter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/badge_model.dart';
import '../../domain/models/item_model.dart';
import '../../domain/models/receipt_batch.dart';
import '../../domain/repositories/progress_stats_service.dart';
import '../di/repository_providers.dart';
import '../widgets/app_drawer.dart';
import 'inventory_screen.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(progressStatsProvider);

    return Scaffold(
      key: const Key('screen_progress'),
      drawer: const AppDrawer(),
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Progress'), elevation: 1),
      body: statsAsync.when(
        data: (stats) => _buildContent(context, ref, stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Unable to load progress: $error',
              style: AppTextStyles.body.copyWith(color: AppColors.danger),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ProgressStats stats,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildStreakCard(stats),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle('Summary'),
        const SizedBox(height: AppSpacing.sm),
        _buildSummaryGrid([
          _StatTile(
            label: 'Total Items',
            value: '${stats.totalItems}',
            onTap: () => _openInventoryWithStatus(ref, null),
          ),
          _StatTile(
            label: 'Available',
            value: '${stats.availableItems}',
            onTap: () => _openInventoryWithStatus(ref, ItemStatus.available),
          ),
          _StatTile(
            label: 'Consumed',
            value: '${stats.consumedItems}',
            onTap: () => _openInventoryWithStatus(ref, ItemStatus.consumed),
          ),
          _StatTile(
            label: 'Wasted',
            value: '${stats.wastedItems}',
            onTap: () => _openInventoryWithStatus(ref, ItemStatus.wasted),
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle('Expiry Health'),
        const SizedBox(height: AppSpacing.sm),
        _buildSummaryGrid([
          _StatTile(
            label: 'Expiring Today',
            value: '${stats.expiringTodayCount}',
          ),
          _StatTile(
            label: 'This Week',
            value: '${stats.expiringThisWeekCount}',
          ),
          _StatTile(
            label: 'Expiring Soon',
            value: '${stats.expiringSoonCount}',
          ),
          _StatTile(label: 'Expired', value: '${stats.expiredCount}'),
          _StatTile(label: 'No Expiry', value: '${stats.noExpiryCount}'),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle('Value Impact'),
        const SizedBox(height: AppSpacing.sm),
        _buildSummaryGrid([
          _StatTile(label: 'Total Value', value: _currency(stats.totalValue)),
          _StatTile(
            label: 'Consumed Value',
            value: _currency(stats.consumedValue),
          ),
          _StatTile(label: 'Wasted Value', value: _currency(stats.wastedValue)),
          _StatTile(label: 'Saved (est.)', value: _currency(stats.savedValue)),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle('Activity'),
        const SizedBox(height: AppSpacing.sm),
        _buildSummaryGrid([
          _StatTile(label: 'Added (7d)', value: '${stats.addedLast7Days}'),
          _StatTile(label: 'Added (30d)', value: '${stats.addedLast30Days}'),
          _StatTile(label: 'Updated (7d)', value: '${stats.updatedLast7Days}'),
          _StatTile(
            label: 'Updated (30d)',
            value: '${stats.updatedLast30Days}',
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle('Categories'),
        const SizedBox(height: AppSpacing.sm),
        _buildChipWrap(
          stats.categoryCounts.map(
            (key, value) => MapEntry(key.displayName, value),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle('Locations'),
        const SizedBox(height: AppSpacing.sm),
        _buildChipWrap(
          stats.locationCounts.map(
            (key, value) => MapEntry(key.displayName, value),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle('Types'),
        const SizedBox(height: AppSpacing.sm),
        _buildChipWrap(
          stats.typeCounts.map(
            (key, value) => MapEntry(key.displayName, value),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle('Badges & Achievements'),
        const SizedBox(height: AppSpacing.sm),
        _buildBadgeProgressList(stats),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle('Telemetry (Local Aggregation)'),
        const SizedBox(height: AppSpacing.sm),
        _buildTelemetrySection(stats),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle('Recent Receipt Batch'),
        const SizedBox(height: AppSpacing.sm),
        _buildRecentBatchSection(ref),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  void _openInventoryWithStatus(WidgetRef ref, ItemStatus? status) {
    ref.read(inventoryFilterProvider.notifier).state = InventoryFilterState(
      status: status,
      hideConsumed: status == null,
      expiringSoonOnly: false,
      preparedOnly: false,
      createdAfter: null,
      createdBefore: null,
      searchQuery: '',
    );
    ref.read(homeTabIndexProvider.notifier).state = 0;
  }

  Widget _buildRecentBatchSection(WidgetRef ref) {
    return FutureBuilder<ReceiptBatch?>(
      future: _loadRecentBatch(ref),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text(
            'Unable to load recent batch',
            style: AppTextStyles.body.copyWith(color: AppColors.danger),
          );
        }

        final batch = snapshot.data;
        if (batch == null) {
          return Text(
            'No recent receipt batches yet.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          );
        }

        final total = batch.items.fold<double>(
          0,
          (sum, item) => sum + (item.price * item.quantity),
        );

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${batch.items.length} items · ${_currency(total)} total',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Source: ${batch.source.name}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<ReceiptBatch?> _loadRecentBatch(WidgetRef ref) async {
    if (!Hive.isAdapterRegistered(receiptBatchAdapterTypeId)) {
      return null;
    }
    try {
      final repo = ref.read(receiptBatchRepositoryProvider);
      await repo.init();
      final batches = await repo.getAllBatches();
      if (batches.isEmpty) return null;
      return batches.first;
    } catch (_) {
      return null;
    }
  }

  Widget _buildStreakCard(ProgressStats stats) {
    final streak = stats.noWasteStreak;
    final daysRemaining = streak.daysRemaining;
    final progress = streak.streakDays / 7;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9BD47F), Color(0xFF5E8F3E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Text(
                  '🔥 ${streak.streakDays}-day streak',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Level up'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No Waste Week',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            daysRemaining == 0
                ? 'You made it! Keep the streak alive.'
                : 'Log $daysRemaining more saves to level up',
            style: AppTextStyles.body.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.35),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFE3F2A8)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Judgement-free: compare with friends only when you opt in.',
            style: AppTextStyles.body.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeProgressList(ProgressStats stats) {
    final entries = BadgeType.values
        .where((type) => stats.badgeProgress.containsKey(type))
        .map((type) => MapEntry(type, stats.badgeProgress[type]!))
        .toList();

    return Column(
      children: entries
          .map(
            (entry) =>
                _BadgeProgressTile(badgeType: entry.key, progress: entry.value),
          )
          .toList(),
    );
  }

  Widget _buildTelemetrySection(ProgressStats stats) {
    final telemetry = stats.telemetry;
    final totalEvents = telemetry.eventCounts.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInsightCard(
          title: 'Local Insights',
          subtitle: 'These insights are computed on-device from your activity.',
          icon: Icons.shield,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildSummaryGrid([
          _StatTile(label: 'Total Events', value: '$totalEvents'),
          _StatTile(
            label: 'Items Added',
            value: '${telemetry.eventCounts['item_added'] ?? 0}',
          ),
          _StatTile(
            label: 'Items Wasted',
            value: '${telemetry.eventCounts['item_wasted'] ?? 0}',
          ),
          _StatTile(
            label: 'Reminders Opened',
            value: '${telemetry.eventCounts['reminder_opened'] ?? 0}',
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        _buildTopInsights(
          label: 'Top Add Sources',
          values: telemetry.itemAddedBySource,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTopInsights(
          label: 'Top Waste Reasons',
          values: telemetry.itemWastedByReason,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTopInsights(
          label: 'Most Viewed Screens',
          values: telemetry.screenViewedByScreen,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTopInsights(
          label: 'Tab Switches',
          values: telemetry.tabSwitchedByTab,
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.h3);
  }

  Widget _buildSummaryGrid(List<_StatTile> tiles) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: tiles
          .map((tile) => SizedBox(width: 160, child: _StatCard(tile: tile)))
          .toList(),
    );
  }

  Widget _buildChipWrap(Map<String, int> values) {
    if (values.isEmpty) {
      return Text(
        'No data yet',
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: values.entries
          .map(
            (entry) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTopInsights({
    required String label,
    required Map<String, int> values,
  }) {
    final topEntries = _topEntries(values, 4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildChipWrap(topEntries),
      ],
    );
  }

  Map<String, int> _topEntries(Map<String, int> values, int limit) {
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final trimmed = entries.take(limit);
    return {for (final entry in trimmed) entry.key: entry.value};
  }

  String _currency(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }
}

class _StatTile {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _StatTile({required this.label, required this.value, this.onTap});
}

class _StatCard extends StatelessWidget {
  final _StatTile tile;

  const _StatCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? const Color(0x33000000)
                : const Color(0x11000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tile.label, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(tile.value, style: AppTextStyles.h3),
        ],
      ),
    );

    if (tile.onTap == null) return content;
    return InkWell(
      onTap: tile.onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: content,
    );
  }
}

class _BadgeProgressTile extends StatelessWidget {
  final BadgeType badgeType;
  final BadgeProgress progress;

  const _BadgeProgressTile({required this.badgeType, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (progress.progressPercentage * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(badgeType.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  badgeType.displayName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text('$percentage%'),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: progress.progressPercentage.clamp(0, 1),
            minHeight: 8,
            backgroundColor: theme.dividerColor,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ],
      ),
    );
  }
}
