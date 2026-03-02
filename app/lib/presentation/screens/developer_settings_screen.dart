import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/feature_flags/feature_flag_key.dart';
import '../../core/feature_flags/feature_flags_provider.dart';

/// Developer settings screen for feature flag management
///
/// Only visible in debug builds. Allows:
/// - Toggling individual feature flags
/// - Viewing override status (whether using local override vs default/remote)
/// - Resetting all overrides to defaults
class DeveloperSettingsScreen extends ConsumerWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allFlagsWithStatus = ref.watch(allFlagsWithStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Settings'),
        centerTitle: true,
      ),
      body: allFlagsWithStatus.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading flags: $err')),
        data: (flags) => ListView(
          children: [
            // Header with reset button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Feature Flags',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _resetAllOverrides(context, ref),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset All Overrides'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Override = using local setting (persists across restarts)\nDefault = using built-in default value',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Flag list
            ...flags.entries.map((entry) {
              final flag = entry.key;
              final status = entry.value;
              return _FlagListTile(
                flag: flag,
                enabled: status.value,
                isOverridden: status.isOverridden,
                onChanged: (value) => _toggleFlag(context, ref, flag, value),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFlag(
    BuildContext context,
    WidgetRef ref,
    FeatureFlagKey flag,
    bool value,
  ) async {
    final service = await ref.read(featureFlagsServiceProvider.future);
    await service.setLocalOverride(flag, value);

    // Invalidate providers to refresh UI
    ref.invalidate(allFlagsWithStatusProvider);
    ref.invalidate(isFlagEnabledProvider(flag));
  }

  Future<void> _resetAllOverrides(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Overrides?'),
        content: const Text(
          'This will reset all feature flag overrides to their default values. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = await ref.read(featureFlagsServiceProvider.future);
      await service.resetAllOverrides();

      // Invalidate providers to refresh UI
      ref.invalidate(allFlagsWithStatusProvider);
      ref.invalidate(isFlagEnabledProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All overrides reset to defaults')),
        );
      }
    }
  }
}

/// Individual flag tile with toggle
class _FlagListTile extends StatelessWidget {
  final FeatureFlagKey flag;
  final bool enabled;
  final bool isOverridden;
  final Function(bool) onChanged;

  const _FlagListTile({
    required this.flag,
    required this.enabled,
    required this.isOverridden,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              flag.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isOverridden)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'OVERRIDE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        flag.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(value: enabled, onChanged: onChanged),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Default: ${flag.defaultValue ? 'enabled' : 'disabled'}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Target: ${flag.targetMilestone}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
            if (flag.costNotes != null) ...[
              const SizedBox(height: 4),
              Text(
                'Cost: ${flag.costNotes}',
                style: const TextStyle(fontSize: 11, color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
