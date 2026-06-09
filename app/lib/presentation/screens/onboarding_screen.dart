import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../routing/router.dart';
import '../widgets/notification_permission_prompt.dart';
import '../widgets/camera_permission_prompt.dart';
import '../widgets/zesto_character.dart';
import 'zesto_guidance_screen.dart';
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

  /// Set once the animated Zesto debut has played, so re-opening onboarding
  /// from the drawer shows a calm, static Zesto instead.
  static const String _zestoIntroPrefsKey = 'zesto_intro_played';
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
  bool _zestoIntroAnimate = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadStoredPresetSelection();
    _initZestoIntro();
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

  /// Animate Zesto's debut only the very first time onboarding is shown.
  Future<void> _initZestoIntro() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_zestoIntroPrefsKey) ?? false) return;
    await prefs.setBool(_zestoIntroPrefsKey, true);
    if (!mounted) return;
    setState(() => _zestoIntroAnimate = true);
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
    configureLaunchRouting(onboardingComplete: true);

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

  Future<void> _openSharedGuidance() async {
    _emitTelemetry('zesto_guidance_reopened', {'source': 'onboarding'});
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ZestoGuidanceScreen(source: 'onboarding'),
      ),
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
            'Welcome to ZeroSpoils.',
            key: const Key('onboarding_title'),
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Everything you buy, remembered — so good food doesn\'t get forgotten.',
            key: const Key('onboarding_welcome_body'),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Center(
              child: Builder(
                builder: (context) {
                  final animate =
                      _zestoIntroAnimate &&
                      !MediaQuery.of(context).disableAnimations;
                  final zesto = ZestoCharacter(
                    key: const Key('onboarding_zesto'),
                    expression: ZestoExpression.wave,
                    size: 112,
                    animate: animate,
                    loop: false,
                  );
                  if (!animate) return zesto;
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: zesto,
                  );
                },
              ),
            ),
          ),
          Text(
            'Track what you have\nKnow what needs using\nSave more of what you buy',
            key: const Key('onboarding_feature_list'),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            key: const Key('onboarding_next_button_0'),
            onPressed: _goNext,
            child: const Text('Get started'),
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
          _buildZestoCompanionBanner(
            key: const Key('onboarding_companion_problem'),
            icon: Icons.qr_code_scanner,
            message:
                'I can help you capture it once and keep the details handy.',
            expression: ZestoExpression.wave,
          ),
          const SizedBox(height: 16),
          _buildPageTitle(
            key: const Key('onboarding_problem_title'),
            icon: Icons.qr_code_scanner,
            title: 'Scan once. We\'ll remember.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Point your camera at a barcode or a whole receipt. We handle the rest — expiry dates, names, the lot.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code_scanner_outlined),
              title: const Text('Scan a barcode'),
              subtitle: const Text(
                'Quick for single items when you are unpacking.',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Or scan a whole receipt'),
              subtitle: const Text(
                'Bring a full grocery trip in at once, then review it.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            key: const Key('onboarding_next_button_1'),
            onPressed: _goNext,
            child: const Text('Show me how'),
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
          _buildZestoCompanionBanner(
            key: const Key('onboarding_companion_solution'),
            icon: Icons.auto_awesome,
            message:
                'I\'ll keep the running list in view so you can focus on real life.',
            expression: ZestoExpression.celebrate,
          ),
          const SizedBox(height: 16),
          _buildPageTitle(
            key: const Key('onboarding_solution_title'),
            icon: Icons.inventory_2_outlined,
            title: 'We remember, so you don\'t have to.',
          ),
          const SizedBox(height: 16),
          benefit(
            '✓',
            'Keep the fridge in view',
            'See what you have without having to remember it all yourself',
          ),
          benefit(
            '✓',
            'Plan shopping smarter',
            'Avoid buying the same thing twice',
          ),
          benefit(
            '✓',
            'Get a gentle nudge',
            'Use food before it slips out of sight and out of mind',
          ),
          benefit(
            '✓',
            'Save more of what you buy',
            'Less food wasted, less money in the bin',
          ),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'A gentle nudge before things expire — less food wasted, less money in the bin.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            key: const Key('onboarding_next_button_2'),
            onPressed: _goNext,
            child: const Text('Start saving'),
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
          _buildZestoCompanionBanner(
            key: const Key('onboarding_companion_workflow'),
            icon: Icons.route_outlined,
            message:
                'Here\'s the simple rhythm I\'ll use to guide you day to day.',
            expression: ZestoExpression.idle,
          ),
          const SizedBox(height: 16),
          _buildPageTitle(
            key: const Key('onboarding_workflow_title'),
            icon: Icons.route_outlined,
            title: 'How it fits together',
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add what you buy or cook'),
              subtitle: const Text(
                'Use quick entry, barcode scan, or batch capture to get started fast.',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text('Check the shopping list before the store'),
              subtitle: const Text(
                'A quick look helps you avoid duplicates and buy with a plan.',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Let receipt scan do the heavy lifting'),
              subtitle: const Text(
                'Review what was found, save it, and keep moving.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('onboarding_open_shared_guidance_button'),
            onPressed: _openSharedGuidance,
            icon: const Icon(Icons.smart_toy_outlined),
            label: const Text('Ask Zesto to show me'),
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
          _buildZestoCompanionBanner(
            key: const Key('onboarding_companion_waste'),
            icon: Icons.insights_outlined,
            message:
                'I\'ll help you notice what\'s getting used and what still needs attention.',
            expression: ZestoExpression.tip,
          ),
          const SizedBox(height: 16),
          _buildPageTitle(
            key: const Key('onboarding_waste_title'),
            icon: Icons.eco_outlined,
            title: 'Keep good food in play',
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('When you use something'),
              subtitle: const Text(
                'Mark it consumed so your list stays honest.',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('When something does not make it'),
              subtitle: const Text(
                'Mark it wasted so the pattern is visible next time.',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: const Text('Use progress to spot the pattern'),
              subtitle: const Text(
                'See what you are saving and where food may still be slipping through.',
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
          _buildZestoCompanionBanner(
            key: const Key('onboarding_companion_permissions'),
            icon: Icons.tune,
            message:
                'A couple of permissions now makes the rest of the experience smoother.',
            expression: ZestoExpression.wave,
          ),
          const SizedBox(height: 16),
          _buildPageTitle(
            key: const Key('onboarding_permissions_title'),
            icon: Icons.notifications_active_outlined,
            title: 'Set up the helpful bits',
          ),
          const SizedBox(height: 12),
          Text(
            'Turn on reminders and camera access for faster entry. Pick a few prepared-food presets if you want quicker defaults.',
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
                  : 'Turn on reminders',
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
              _cameraPermissionGranted ? 'Camera Enabled' : 'Turn on camera',
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
            child: const Text('Start saving'),
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

  Widget _buildPageTitle({
    required Key key,
    required IconData icon,
    required String title,
  }) {
    final theme = Theme.of(context);

    return Row(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildZestoCompanionBanner({
    required Key key,
    required IconData icon,
    required String message,
    required ZestoExpression expression,
  }) {
    final theme = Theme.of(context);

    return Container(
      key: key,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZestoCharacter(
            key: Key('onboarding_companion_zesto'),
            expression: expression,
            size: 48,
            animate: false,
            semanticLabel: 'Zesto companion',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Zesto says',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(message, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
