import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/distribution/app_distribution_service.dart';

/// A small feedback button shown only in beta/debug builds.
///
/// Tapping the button triggers a manual update check via
/// [AppDistributionService.checkForUpdate], which shows the Firebase
/// App Distribution update dialog if a newer beta build is available.
///
/// In production builds (where [kBetaBuild] is false and [kDebugMode] is
/// false) this widget renders as a zero-size [SizedBox] and is removed by
/// tree-shaking.
///
/// The optional [isActive] parameter overrides the default compile-time check
/// and is intended **for testing only**.
///
/// Note: Shake-to-feedback (native Tester SDK) requires additional native
/// platform channel integration beyond flutter plugin v1.x; this FAB serves
/// as the in-app entry point for testers who want to check for updates.
class BetaFeedbackButton extends StatelessWidget {
  const BetaFeedbackButton({super.key, this.isActive});

  /// Overrides [kBetaBuild] || [kDebugMode] for testing purposes.
  @visibleForTesting
  final bool? isActive;

  bool get _enabled => isActive ?? (kBetaBuild || kDebugMode);

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return const SizedBox.shrink();

    return FloatingActionButton.small(
      key: const Key('beta_feedback_fab'),
      heroTag: 'beta_feedback',
      onPressed: () => _onPressed(context),
      tooltip: 'Beta Feedback',
      backgroundColor: Colors.deepOrange.withAlpha(204),
      foregroundColor: Colors.white,
      child: const Icon(Icons.feedback_outlined, size: 18),
    );
  }

  Future<void> _onPressed(BuildContext context) async {
    try {
      await AppDistributionService.instance.checkForUpdate();
    } catch (e) {
      debugPrint('[AppDistribution] Beta feedback action failed (non-fatal): $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update check unavailable. Try again later.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

