// GoRouter configuration with deep linking support
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_shell.dart';

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
            final itemId = state.pathParameters['id'];
            return Scaffold(
              appBar: AppBar(title: const Text('Item Details')),
              body: Center(child: Text('Item: $itemId')),
            );
          },
        ),
      ],
    ),
  ],
  // Deep linking configuration
  initialLocation: '/',
);
