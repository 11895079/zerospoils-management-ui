// GoRouter configuration with deep linking support
import 'package:go_router/go_router.dart';
import '../screens/home_shell.dart';
import '../screens/item_detail_screen.dart';

final router = GoRouter(
  routes: <RouteBase>[
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
      ],
    ),
  ],
  // Deep linking configuration
  initialLocation: '/',
);
