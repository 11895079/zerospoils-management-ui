import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../widgets/notification_permission_prompt.dart';
import '../widgets/camera_permission_prompt.dart';
import '../../presentation/di/service_locator.dart';

/// Multi-step onboarding screen aligned with prototype flow.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _numPages = 6;
  static const String _onboardingPresetPrefsKey =
      'onboarding_preferred_food_presets';
  static const List<Map<String, String>> _presetOptions = [
    {'id': 'jollof_rice', 'label': '🍚 Jollof rice'},
    {'id': 'curry', 'label': '🍛 Curry'},
    {'id': 'soup', 'label': '🥣 Soup'},
    {'id': 'pasta_dishes', 'label': '🍝 Pasta dishes'},
    {'id': 'stew', 'label': '🍲 Stew'},
    {'id': 'beans', 'label': '🫘 Beans'},
  ];

  late PageController _pageController;
  int _currentPage = 0;
  bool _isCompletingOnboarding = false;
  bool _notificationPermissionGranted = false;
  bool _cameraPermissionGranted = false;
  Set<String> _selectedPresetIds = <String>{};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadStoredPresetSelection();
    _emitTelemetry('onboarding_started', {});
  }

  Future<void> _loadStoredPresetSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_onboardingPresetPrefsKey) ?? const [];
    if (!mounted) return;
    setState(() {
      _selectedPresetIds = stored.toSet();
    });
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
    await prefs.setStringList(
      _onboardingPresetPrefsKey,
      _selectedPresetIds.toList(),
    );
    await prefs.setBool('onboarding_complete', true);

    _emitTelemetry('onboarding_completed', {'pages': _numPages});

    if (!mounted) return;
    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.pop(true);
      return;
    }

    final goRouter = GoRouter.maybeOf(context);
    if (goRouter != null) {
      goRouter.go('/');
      return;
    }

    // Last-resort fallback for edge test scaffolds without routing or nav stack.
    _resetCompletingState();
  }

  void _skipOnboarding() {
    _emitTelemetry('onboarding_skipped', {});
    _completeOnboarding();
  }

  void _resetCompletingState() {
    if (!mounted) return;
    setState(() {
      _isCompletingOnboarding = false;
    });
  }

  void _onPermissionDeferredOrDenied(String permissionType) {
    _emitTelemetry('permission_deferred', {'permission_type': permissionType});
    // Keep users on the final page after permission action.
  }

  void _onPermissionGranted(String permissionType) {
    _emitTelemetry('permission_granted', {'permission_type': permissionType});
    if (!mounted) return;
    setState(() {
      if (permissionType == 'notifications') {
        _notificationPermissionGranted = true;
      } else if (permissionType == 'camera') {
        _cameraPermissionGranted = true;
      }
    });
    // Keep users on the final page after permission action.
  }

  void _togglePreset(String presetId, bool selected) {
    setState(() {
      if (selected) {
        _selectedPresetIds.add(presetId);
      } else {
        _selectedPresetIds.remove(presetId);
      }
    });
  }

  void _goNext() {
    if (_currentPage >= _numPages - 1) {
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goBack() {
    if (_currentPage <= 0) {
      return;
    }
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appBarForeground =
        theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome', key: Key('onboarding_appbar_title')),
        leading: _currentPage == 0
            ? null
            : IconButton(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back),
              ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: appBarForeground),
            onPressed: _skipOnboarding,
            key: const Key('onboarding_skip_button'),
            child: const Text('Skip'),
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
                _buildProblemPage(),
                _buildSolutionPage(),
                _buildWorkflowPage(),
                _buildWastePage(),
                _buildPermissionsAndPresetsPage(),
              ],
            ),
          ),
          _buildBottomNav(),
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
            'Reduce food waste, save money, and organize your kitchen.',
            key: const Key('onboarding_welcome_body'),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Icon(Icons.check_circle, size: 80),
          ),
          Text(
            'Track inventory\nSmart reminders\nShopping flow + waste insights',
            key: const Key('onboarding_feature_list'),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            key: const Key('onboarding_next_button_0'),
            onPressed: _goNext,
            child: const Text('Let\'s Get Started'),
          ),
        ],
      ),
    );
  }

  Widget _buildProblemPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          const SizedBox(height: 12),
          Text(
            'Did you know?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '~30% of groceries end up in the trash.\nThat is money, time, and resources wasted.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ever forgotten what is in the fridge? Bought duplicates? Or lost leftovers in the back? We have all been there.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            key: const Key('onboarding_next_button_1'),
            onPressed: _goNext,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionPage() {
    Widget benefit(String emoji, String title, String detail) {
      return Card(
        child: ListTile(
          leading: Text(emoji, style: const TextStyle(fontSize: 24)),
          title: Text(title),
          subtitle: Text(detail),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          Text(
            'ZeroSpoils helps you',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          benefit(
            '✓',
            'Track all your food',
            'What you have and when it expires',
          ),
          benefit('✓', 'Plan shopping smarter', 'Avoid duplicate purchases'),
          benefit(
            '✓',
            'Reduce waste proactively',
            'Use items before they spoil',
          ),
          benefit(
            '✓',
            'Save money on takeout',
            'Cook with what you already have',
          ),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Result: Save money, reduce waste, better organized kitchen.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            key: const Key('onboarding_next_button_2'),
            onPressed: _goNext,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          Text(
            'Inventory + Shopping Workflow',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add items you buy or prepare'),
              subtitle: const Text(
                'Use the + action to add individual items or shopping batches.',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text('Use shopping list before store trips'),
              subtitle: const Text(
                'Mark purchased items and move them into inventory.',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Capture receipt batches with OCR'),
              subtitle: const Text(
                'Automatically detect line items for review and save.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            key: const Key('onboarding_next_button_3'),
            onPressed: _goNext,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildWastePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          Text(
            'Reduce Waste',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('When you use an item'),
              subtitle: const Text('Tap it and mark it consumed.'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('When something goes bad'),
              subtitle: const Text(
                'Mark wasted and capture reason + percentage.',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: const Text('Track improvement over time'),
              subtitle: const Text(
                'Use progress insights to reduce future waste.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            key: const Key('onboarding_next_button_4'),
            onPressed: _goNext,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsAndPresetsPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          Text(
            'Permissions + Presets',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Enable notifications and camera for reminders + faster entry. Pick prepared food presets to speed up expiry defaults.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            key: const Key('onboarding_notifications_button'),
            icon: Icon(
              _notificationPermissionGranted
                  ? Icons.check_circle
                  : Icons.notifications,
            ),
            label: Text(
              _notificationPermissionGranted
                  ? 'Notifications Enabled'
                  : 'Enable Notifications',
            ),
            onPressed: () async {
              _emitTelemetry('permission_prompt_shown', {
                'permission_type': 'notifications',
              });
              final granted = await showDialog<bool>(
                context: context,
                builder: (_) => const NotificationPermissionPrompt(),
              );
              if (!mounted || granted == null) {
                return;
              }
              if (granted) {
                _onPermissionGranted('notifications');
              } else {
                _onPermissionDeferredOrDenied('notifications');
              }
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            key: const Key('onboarding_camera_button'),
            icon: Icon(
              _cameraPermissionGranted ? Icons.check_circle : Icons.camera_alt,
            ),
            label: Text(
              _cameraPermissionGranted ? 'Camera Enabled' : 'Enable Camera',
            ),
            onPressed: () async {
              _emitTelemetry('permission_prompt_shown', {
                'permission_type': 'camera',
              });
              final granted = await showDialog<bool>(
                context: context,
                builder: (_) => const CameraPermissionPrompt(),
              );
              if (!mounted || granted == null) {
                return;
              }
              if (granted) {
                _onPermissionGranted('camera');
              } else {
                _onPermissionDeferredOrDenied('camera');
              }
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetOptions
                .map(
                  (preset) => FilterChip(
                    key: Key('onboarding_preset_chip_${preset['id']}'),
                    label: Text(preset['label']!),
                    selected: _selectedPresetIds.contains(preset['id']),
                    onSelected: (selected) =>
                        _togglePreset(preset['id']!, selected),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            key: const Key('onboarding_continue_button'),
            onPressed: _isCompletingOnboarding ? null : _completeOnboarding,
            child: const Text('Continue to App'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_currentPage + 1} of $_numPages',
            key: const Key('onboarding_page_indicator'),
          ),
          Row(
            children: List.generate(
              _numPages,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Theme.of(context).primaryColor
                        : theme.colorScheme.outline,
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
