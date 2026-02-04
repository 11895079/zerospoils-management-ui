// GoRouter configuration with deep linking support
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/home_shell.dart';
import '../screens/item_detail_screen.dart';
import '../screens/item_form_screen.dart';
import '../screens/onboarding_screen.dart';

/// Determine initial location based on onboarding completion status
Future<String> getInitialLocation() async {
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  return onboardingComplete ? '/' : '/onboarding';
}

final router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeShell(),
      routes: [
        GoRoute(
          path: 'item/:id',
          name: 'item-detail',
          builder: (context, state) {
            final itemId = state.pathParameters['id'] ?? '';
            return ItemDetailScreen(itemId: itemId);
          },
        ),
        GoRoute(
          path: 'add-item',
          name: 'add-item',
          builder: (context, state) => const ItemFormScreen(),
        ),
        GoRoute(
          path: 'edit-item/:id',
          name: 'edit-item',
          builder: (context, state) {
            final itemId = state.pathParameters['id'] ?? '';
            return ItemFormScreen(itemId: itemId);
          },
        ),
      ],
    ),
  ],
  initialLocation:
      '/onboarding', // Default for initialization; updated in main.dart
);
