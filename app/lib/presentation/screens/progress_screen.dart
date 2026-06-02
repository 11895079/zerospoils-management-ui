library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/adapters/receipt_batch_adapter.dart';
import '../../generated_l10n/app_localizations.dart';
import '../../generated_l10n/app_localizations_en.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/models/badge_model.dart';
import '../../domain/models/item_model.dart';
import '../../domain/models/receipt_batch.dart';
import '../../domain/models/zesto_model.dart';
import '../../domain/repositories/progress_stats_service.dart';
import '../di/repository_providers.dart';
import '../widgets/app_drawer.dart';
import 'inventory_screen.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final statsAsync = ref.watch(progressStatsProvider);

    return Scaffold(
      key: const Key('screen_progress'),
      drawer: const AppDrawer(),
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(l10n.screenTitleProgress), elevation: 1),
      body: statsAsync.when(
        data: (stats) => _buildContent(context, ref, stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Unable to load progress: $error',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
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
        _buildSectionTitle(context, 'Summary'),
        const SizedBox(height: AppSpacing.sm),
        _buildSummaryGrid([
          _StatTile(
            id: 'total_items',
            label: 'Total Items',
            value: '${stats.totalItems}',
            onTap: () => _openInventoryWithStatus(ref, null),
          ),
          _StatTile(
            id: 'available',
            label: 'Available',
            value: '${stats.availableItems}',
            onTap: () => _openInventoryWithStatus(ref, ItemStatus.available),
          ),
          _StatTile(
            id: 'consumed',
            label: 'Consumed',
            value: '${stats.consumedItems}',
            onTap: () => _openInventoryWithStatus(ref, ItemStatus.consumed),
          ),
          _StatTile(
            id: 'wasted',
            label: 'Wasted',
            value: '${stats.wastedItems}',
            onTap: () => _openInventoryWithStatus(ref, ItemStatus.wasted),
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle(context, 'Expiry Health'),
        const SizedBox(height: AppSpacing.sm),
        _buildSummaryGrid([
          _StatTile(
            id: 'expiring_today',
            label: 'Expiring Today',
            value: '${stats.expiringTodayCount}',
          ),
          _StatTile(
            id: 'this_week',
            label: 'This Week',
            value: '${stats.expiringThisWeekCount}',
          ),
          _StatTile(
            id: 'expiring_soon',
            label: 'Expiring Soon',
            value: '${stats.expiringSoonCount}',
          ),
          _StatTile(
            id: 'expired',
            label: 'Expired',
            value: '${stats.expiredCount}',
          ),
          _StatTile(
            id: 'no_expiry',
            label: 'No Expiry',
            value: '${stats.noExpiryCount}',
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle(context, 'Value Impact'),
        const SizedBox(height: AppSpacing.sm),
        _buildSummaryGrid([
          _StatTile(
            id: 'total_value',
            label: 'Total Value',
            value: _currency(stats.totalValue),
          ),
          _StatTile(
            id: 'consumed_value',
            label: 'Consumed Value',
            value: _currency(stats.consumedValue),
          ),
          _StatTile(
            id: 'wasted_value',
            label: 'Wasted Value',
            value: _currency(stats.wastedValue),
          ),
          _StatTile(
            id: 'saved_est',
            label: 'Saved (est.)',
            value: _currency(stats.savedValue),
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle(context, 'Activity'),
        const SizedBox(height: AppSpacing.sm),
        _buildSummaryGrid([
          _StatTile(
            id: 'added_7d',
            label: 'Added (7d)',
            value: '${stats.addedLast7Days}',
          ),
          _StatTile(
            id: 'added_30d',
            label: 'Added (30d)',
            value: '${stats.addedLast30Days}',
          ),
          _StatTile(
            id: 'updated_7d',
            label: 'Updated (7d)',
            value: '${stats.updatedLast7Days}',
          ),
          _StatTile(
            id: 'updated_30d',
            label: 'Updated (30d)',
            value: '${stats.updatedLast30Days}',
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle(context, 'Categories'),
        const SizedBox(height: AppSpacing.sm),
        _buildChipWrap(
          context,
          stats.categoryCounts.map(
            (key, value) => MapEntry(key.displayName, value),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle(context, 'Locations'),
        const SizedBox(height: AppSpacing.sm),
        _buildChipWrap(
          context,
          stats.locationCounts.map(
            (key, value) => MapEntry(key.displayName, value),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle(context, 'Types'),
        const SizedBox(height: AppSpacing.sm),
        _buildChipWrap(
          context,
          stats.typeCounts.map(
            (key, value) => MapEntry(key.displayName, value),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle(context, 'Badges & Achievements'),
        const SizedBox(height: AppSpacing.sm),
        _buildBadgeProgressList(stats),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle(context, 'Telemetry (Local Aggregation)'),
        const SizedBox(height: AppSpacing.sm),
        _buildTelemetrySection(context, stats),
        if (kDebugMode) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildSectionTitle(context, 'Zesto Debug Triggers'),
          const SizedBox(height: AppSpacing.sm),
          _buildZestoDebugPanel(context, ref),
        ],
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle(context, 'Recent Receipt Batch'),
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
          final theme = Theme.of(context);
          return Text(
            'Unable to load recent batch',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.danger,
            ),
          );
        }

        final batch = snapshot.data;
        if (batch == null) {
          final theme = Theme.of(context);
          return Text(
            'No recent receipt batches yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Source: ${batch.source.name}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZestoDebugPanel(BuildContext context, WidgetRef ref) {
    final zesto = ref.read(zestoServiceProvider);
    Future<void> trigger(MascotMessageType type) async {
      await zesto.showMascot(type, bypassAntiSpam: true);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          FilledButton.tonal(
            onPressed: () => unawaited(trigger(MascotMessageType.dailyWelcome)),
            child: const Text('Daily Welcome'),
          ),
          FilledButton.tonal(
            onPressed: () => unawaited(trigger(MascotMessageType.firstItem)),
            child: const Text('First Item'),
          ),
          FilledButton.tonal(
            onPressed: () => unawaited(trigger(MascotMessageType.itemAdded)),
            child: const Text('Item Added'),
          ),
          FilledButton.tonal(
            onPressed: () => unawaited(trigger(MascotMessageType.consumed)),
            child: const Text('Consumed'),
          ),
          FilledButton.tonal(
            onPressed: () => unawaited(trigger(MascotMessageType.quickSave)),
            child: const Text('Quick Save'),
          ),
          FilledButton.tonal(
            onPressed: () => unawaited(trigger(MascotMessageType.wasted)),
            child: const Text('Wasted'),
          ),
          FilledButton.tonal(
            onPressed: () =>
                unawaited(trigger(MascotMessageType.badgeUnlocked)),
            child: const Text('Badge'),
          ),
          FilledButton.tonal(
            onPressed: () =>
                unawaited(trigger(MascotMessageType.streakMilestone)),
            child: const Text('Streak'),
          ),
          FilledButton.tonal(
            onPressed: () =>
                unawaited(trigger(MascotMessageType.savingsMilestone)),
            child: const Text('Savings'),
          ),
          FilledButton.tonal(
            onPressed: () => unawaited(trigger(MascotMessageType.zeroWaste)),
            child: const Text('Zero Waste'),
          ),
          FilledButton.tonal(
            onPressed: () => unawaited(trigger(MascotMessageType.expiryAlert)),
            child: const Text('Expiry Alert'),
          ),
          OutlinedButton(
            onPressed: zesto.dismissMascot,
            child: const Text('Dismiss'),
          ),
        ],
      ),
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

  Widget _buildTelemetrySection(BuildContext context, ProgressStats stats) {
    final telemetry = stats.telemetry;
    final totalEvents = telemetry.eventCounts.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInsightCard(
          context: context,
          title: 'Local Insights',
          subtitle: 'These insights are computed on-device from your activity.',
          icon: Icons.shield,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildSummaryGrid([
          _StatTile(
            id: 'total_events',
            label: 'Total Events',
            value: '$totalEvents',
          ),
          _StatTile(
            id: 'items_added',
            label: 'Items Added',
            value: '${telemetry.eventCounts['item_added'] ?? 0}',
          ),
          _StatTile(
            id: 'items_wasted',
            label: 'Items Wasted',
            value: '${telemetry.eventCounts['item_wasted'] ?? 0}',
          ),
          _StatTile(
            id: 'reminders_opened',
            label: 'Reminders Opened',
            value: '${telemetry.eventCounts['reminder_opened'] ?? 0}',
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        _buildTopInsights(
          context: context,
          label: 'Top Add Sources',
          values: telemetry.itemAddedBySource,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTopInsights(
          context: context,
          label: 'Top Waste Reasons',
          values: telemetry.itemWastedByReason,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTopInsights(
          context: context,
          label: 'Most Viewed Screens',
          values: telemetry.screenViewedByScreen,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTopInsights(
          context: context,
          label: 'Tab Switches',
          values: telemetry.tabSwitchedByTab,
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.14,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    final titleKeySuffix = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return Text(
      key: Key('progress_section_title_$titleKeySuffix'),
      title,
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
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

  Widget _buildChipWrap(BuildContext context, Map<String, int> values) {
    final theme = Theme.of(context);

    if (values.isEmpty) {
      return Text(
        'No data yet',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.textTheme.bodySmall?.color,
        ),
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
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTopInsights({
    required BuildContext context,
    required String label,
    required Map<String, int> values,
  }) {
    final topEntries = _topEntries(values, 4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildChipWrap(context, topEntries),
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
  /// Stable, non-localized identifier used for widget keys (copy/locale-safe).
  final String id;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _StatTile({
    required this.id,
    required this.label,
    required this.value,
    this.onTap,
  });
}

class _StatCard extends StatelessWidget {
  final _StatTile tile;

  const _StatCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keySuffix = tile.id;
    final content = Container(
      key: Key('progress_stat_card_$keySuffix'),
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
          Text(
            key: Key('progress_stat_label_$keySuffix'),
            tile.label,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            key: Key('progress_stat_value_$keySuffix'),
            tile.value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text('$percentage%', style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: progress.progressPercentage.clamp(0, 1),
            minHeight: 8,
            backgroundColor: theme.dividerColor,
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
