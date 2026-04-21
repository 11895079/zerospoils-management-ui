import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../widgets/notification_permission_prompt.dart';
import '../widgets/camera_permission_prompt.dart';
import '../../presentation/di/service_locator.dart';

/// Feature flag for onboarding flow length (A/B test)
enum OnboardingVariant { short, long }

final onboardingVariantProvider = StateProvider<OnboardingVariant>(
  (ref) => OnboardingVariant.short,
);

/// Simple onboarding screen for ZeroSpoils
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isCompletingOnboarding = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _emitTelemetry('onboarding_started', {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _emitTelemetry(String eventName, Map<String, dynamic> properties) {
    final telemetry = ref.read(telemetryClientProvider);
    telemetry.enqueue({'name': eventName, 'properties': properties});
  }

  Future<void> _completeOnboarding() async {
    if (_isCompletingOnboarding) return;
    if (mounted) {
      setState(() {
        _isCompletingOnboarding = true;
      });
    }

    // Persist onboarding completion flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    _emitTelemetry('onboarding_completed', {
      'variant': ref.read(onboardingVariantProvider).toString(),
    });

    if (!mounted) return;
    final goRouter = GoRouter.maybeOf(context);
    if (goRouter != null) {
      goRouter.go('/');
      return;
    }

    // In non-router contexts (e.g., some widget tests), just avoid throwing.
    if (mounted) {
      setState(() {
        _isCompletingOnboarding = false;
      });
    }
  }

  void _skipOnboarding() {
    _emitTelemetry('onboarding_skipped', {});
    _completeOnboarding();
  }

  void _onPermissionDeferredOrDenied(String permissionType) {
    _emitTelemetry('permission_deferred', {'permission_type': permissionType});
    // Continue to next page or complete
    if (_currentPage < _getNumPages() - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onPermissionGranted(String permissionType) {
    _emitTelemetry('permission_granted', {'permission_type': permissionType});
    // Continue to next page or complete
    if (_currentPage < _getNumPages() - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  int _getNumPages() {
    final variant = ref.watch(onboardingVariantProvider);
    return variant == OnboardingVariant.short ? 2 : 3;
  }

  @override
  Widget build(BuildContext context) {
    final variant = ref.watch(onboardingVariantProvider);
    final numPages = _getNumPages();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome', key: Key('onboarding_appbar_title')),
        actions: [
          TextButton(
            onPressed: _skipOnboarding,
            key: const Key('onboarding_skip_button'),
            child: const Text('Skip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildWelcomePage(),
                if (variant == OnboardingVariant.long)
                  _buildValuePropositionPage(),
                _buildPermissionsPage(),
              ],
            ),
          ),
          _buildBottomNav(numPages),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '🥬 ZeroSpoils',
            key: const Key('onboarding_title'),
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Track your food, reduce waste, and get notified before items expire.',
            key: const Key('onboarding_welcome_body'),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Icon(Icons.check_circle, size: 80, color: Colors.green),
          ),
          Text(
            'Never waste food again\n'
            'Smart reminders\n'
            'Simple & offline',
            key: const Key('onboarding_feature_list'),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildValuePropositionPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'How It Works',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildFeatureCard(
            '📸',
            'Add Items',
            'Quickly add food to your inventory',
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            '⏰',
            'Get Reminders',
            'Be notified before items expire',
          ),
          const SizedBox(height: 16),
          _buildFeatureCard('📊', 'Track Waste', 'See what you\'re discarding'),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String emoji, String title, String description) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Permissions',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            'We need permission for notifications and camera to give you the best experience.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            key: const Key('onboarding_notifications_button'),
            icon: const Icon(Icons.notifications),
            label: const Text('Enable Notifications'),
            onPressed: () async {
              _emitTelemetry('permission_prompt_shown', {
                'permission_type': 'notifications',
              });
              final granted = await showDialog<bool>(
                context: context,
                builder: (_) => const NotificationPermissionPrompt(),
              );
              if (!mounted || granted == null) return;
              if (granted) {
                _onPermissionGranted('notifications');
              } else {
                _onPermissionDeferredOrDenied('notifications');
              }
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            key: const Key('onboarding_camera_button'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Enable Camera'),
            onPressed: () async {
              _emitTelemetry('permission_prompt_shown', {
                'permission_type': 'camera',
              });
              final granted = await showDialog<bool>(
                context: context,
                builder: (_) => const CameraPermissionPrompt(),
              );
              if (!mounted || granted == null) return;
              if (granted) {
                _onPermissionGranted('camera');
              } else {
                _onPermissionDeferredOrDenied('camera');
              }
            },
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            key: const Key('onboarding_continue_button'),
            onPressed: _isCompletingOnboarding ? null : _completeOnboarding,
            child: const Text('Continue to App'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(int numPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_currentPage + 1} of $numPages',
            key: const Key('onboarding_page_indicator'),
          ),
          Row(
            children: List.generate(
              numPages,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
