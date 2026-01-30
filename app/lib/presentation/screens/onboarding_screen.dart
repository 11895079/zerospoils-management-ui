import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/notification_permission_prompt.dart';

/// Simple onboarding screen for ZeroSpoils
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _showPermissionPrompt = false;
  bool _onboardingComplete = false;

  Future<void> _completeOnboarding() async {
    // Persist onboarding completion flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    setState(() {
      _onboardingComplete = true;
    });
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete) {
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to ZeroSpoils')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Track your food, reduce waste, and get notified before items expire.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showPermissionPrompt = true;
                });
              },
              child: const Text('Enable Notifications'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _completeOnboarding,
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
      // Show permission dialog if requested
      floatingActionButton: _showPermissionPrompt
          ? NotificationPermissionPrompt(
              onGranted: _completeOnboarding,
              onDenied: _completeOnboarding,
            )
          : null,
    );
  }
}
