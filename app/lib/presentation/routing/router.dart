// GoRouter configuration with deep linking support
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/home_shell.dart';
import '../screens/item_detail_screen.dart';
import '../screens/item_form_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/receipt_batch_capture_screen.dart';
import '../screens/receipt_batch_detail_screen.dart';
import '../screens/receipt_batches_screen.dart';
import '../../domain/models/receipt_batch.dart';

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
          path: 'edit-item/:id',
          name: 'edit-item',
          builder: (context, state) {
            final itemId = state.pathParameters['id'] ?? '';
            return ItemFormScreen(itemId: itemId);
          },
        ),
        GoRoute(
          path: 'receipt-batches',
          name: 'receipt-batches',
          builder: (context, state) => const ReceiptBatchesScreen(),
          routes: [
            GoRoute(
              path: 'capture',
              name: 'receipt-batch-capture',
              builder: (context, state) => const ReceiptBatchCaptureScreen(
                source: ReceiptBatchSource.inventory,
              ),
            ),
            GoRoute(
              path: ':id',
              name: 'receipt-batch-detail',
              builder: (context, state) {
                final batchId = state.pathParameters['id'] ?? '';
                return ReceiptBatchDetailScreen(batchId: batchId);
              },
            ),
          ],
        ),
      ],
    ),
  ],
  initialLocation: '/onboarding',
  redirect: (context, state) async {
    // Check if onboarding is complete
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    final isOnOnboardingPage = state.matchedLocation == '/onboarding';

    // If onboarding is complete and user is on onboarding page, redirect to home
    if (onboardingComplete && isOnOnboardingPage) {
      return '/';
    }

    // If onboarding is not complete and user is not on onboarding page, redirect to onboarding
    if (!onboardingComplete && !isOnOnboardingPage) {
      return '/onboarding';
    }

    // No redirect needed
    return null;
  },
);
