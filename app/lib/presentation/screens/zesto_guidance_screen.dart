library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../di/service_locator.dart' show telemetryClientProvider;
import '../widgets/zesto_character.dart';

class ZestoGuidanceScreen extends ConsumerStatefulWidget {
  const ZestoGuidanceScreen({super.key, required this.source});

  final String source;

  @override
  ConsumerState<ZestoGuidanceScreen> createState() =>
      _ZestoGuidanceScreenState();
}

class _ZestoGuidanceScreenState extends ConsumerState<ZestoGuidanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(telemetryClientProvider).enqueue({
        'name': 'zesto_guidance_opened',
        'properties': {'source': widget.source},
      });
    });
  }

  void _onSectionViewed(String sectionId) {
    ref.read(telemetryClientProvider).enqueue({
      'name': 'zesto_guidance_section_viewed',
      'properties': {'source': widget.source, 'section_id': sectionId},
    });
  }

  void _onDone() {
    ref.read(telemetryClientProvider).enqueue({
      'name': 'zesto_guidance_completed',
      'properties': {'source': widget.source},
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const Key('screen_zesto_guidance'),
      appBar: AppBar(title: const Text('How ZeroSpoils helps')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildHero(theme),
          const SizedBox(height: AppSpacing.lg),
          _GuidanceStepCard(
            key: const Key('zesto_step_add_items'),
            icon: Icons.playlist_add_circle_outlined,
            title: 'Add what came home',
            body:
                'Add a few items, scan a barcode, or capture a receipt. We remember the details from there.',
            tip: 'Add it once, and I can help you avoid buying it twice.',
            onViewed: () => _onSectionViewed('add_items'),
          ),
          const SizedBox(height: AppSpacing.md),
          _GuidanceStepCard(
            key: const Key('zesto_step_track_freshness'),
            icon: Icons.event_available_outlined,
            title: 'See what needs using first',
            body:
                'Expiry dates and reminders bring the easy-to-forget items back into view.',
            tip: 'Check Expiring Today before meals. It is the quickest win.',
            onViewed: () => _onSectionViewed('track_freshness'),
          ),
          const SizedBox(height: AppSpacing.md),
          _GuidanceStepCard(
            key: const Key('zesto_step_take_action'),
            icon: Icons.check_circle_outline,
            title: 'Keep it up to date',
            body:
                'When something gets used, moved, or tossed, mark it. A few quick updates keep everything useful.',
            tip:
                'Do a 60-second check at night, then a quick weekend audit before shopping. Progress, not perfection.',
            onViewed: () => _onSectionViewed('take_action'),
          ),
          const SizedBox(height: AppSpacing.md),
          _GuidanceStepCard(
            key: const Key('zesto_step_review_progress'),
            icon: Icons.insights_outlined,
            title: 'See what you are saving',
            body:
                'Progress shows what you used, what you saved, and where food may still be slipping through.',
            tip: 'Start with the money saved. It tells the story fast.',
            onViewed: () => _onSectionViewed('review_progress'),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            key: const Key('zesto_guidance_done_button'),
            onPressed: _onDone,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Start saving'),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F8F1), Color(0xFFF7FFFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          const ZestoCharacter(
            key: Key('zesto_guidance_character'),
            expression: ZestoExpression.wave,
            size: 120,
            animate: false,
            semanticLabel: 'Zesto coach',
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'I\'m Zesto. Add food once, and we\'ll help you remember what to use first.',
            key: const Key('zesto_guidance_intro_text'),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceStepCard extends StatefulWidget {
  const _GuidanceStepCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.tip,
    required this.onViewed,
  });

  final IconData icon;
  final String title;
  final String body;
  final String tip;
  final VoidCallback onViewed;

  @override
  State<_GuidanceStepCard> createState() => _GuidanceStepCardState();
}

class _GuidanceStepCardState extends State<_GuidanceStepCard> {
  bool _acknowledged = false;

  String _sectionKey() {
    return widget.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  void _handleViewed() {
    if (_acknowledged) return;
    widget.onViewed();
    setState(() {
      _acknowledged = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sectionKey = _sectionKey();

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(widget.body, style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.sm),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: _acknowledged
                    ? const Color(0xFFEAF7EE)
                    : const Color(0xFFFFF6E6),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: _acknowledged
                      ? AppColors.success.withValues(alpha: 0.45)
                      : const Color(0xFFFFD39A),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Zesto tip: ${widget.tip}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: Key('zesto_section_viewed_$sectionKey'),
                onPressed: _handleViewed,
                style: TextButton.styleFrom(
                  foregroundColor: _acknowledged ? AppColors.success : null,
                ),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _acknowledged
                      ? Icon(
                          Icons.check_circle,
                          key: Key('zesto_section_ack_icon_$sectionKey'),
                          size: 18,
                          color: AppColors.success,
                        )
                      : Icon(
                          Icons.radio_button_unchecked,
                          key: Key(
                            'zesto_section_ack_icon_pending_$sectionKey',
                          ),
                          size: 18,
                        ),
                ),
                label: Text(_acknowledged ? 'Saved' : 'Got it'),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _acknowledged
                  ? Padding(
                      key: Key('zesto_section_ack_message_$sectionKey'),
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        'Nice. This tip is marked as done.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
