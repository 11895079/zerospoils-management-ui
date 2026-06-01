// GoRouter configuration with deep linking support
import 'package:go_router/go_router.dart';
import '../screens/home_shell.dart';
import '../screens/item_detail_screen.dart';
import '../screens/item_form_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/receipt_batch_capture_screen.dart';
import '../screens/receipt_batch_detail_screen.dart';
import '../screens/receipt_batches_screen.dart';
import '../../domain/models/receipt_batch.dart';

/// Launch-time onboarding state loaded before runApp.
///
/// Keeping this in memory allows a synchronous router redirect, which avoids
/// null-child router frames on startup.
bool _onboardingCompleteAtLaunch = false;

void configureLaunchRouting({required bool onboardingComplete}) {
  _onboardingCompleteAtLaunch = onboardingComplete;
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
  redirect: (context, state) {
    final isOnOnboardingPage = state.matchedLocation == '/onboarding';

    // If onboarding is complete and user is on onboarding page, redirect to home
    if (_onboardingCompleteAtLaunch && isOnOnboardingPage) {
      return '/';
    }

    // If onboarding is not complete and user is not on onboarding page, redirect to onboarding
    if (!_onboardingCompleteAtLaunch && !isOnOnboardingPage) {
      return '/onboarding';
    }

    // No redirect needed
    return null;
  },
);
