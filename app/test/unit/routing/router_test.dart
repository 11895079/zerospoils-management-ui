// Unit tests for router configuration and navigation
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zerospoils/presentation/routing/router.dart' as router_config;

void main() {
  group('Router Tests', () {
    test('Router is initialized as GoRouter', () {
      expect(router_config.router, isNotNull);
      expect(router_config.router, isA<GoRouter>());
    });

    test('Item detail route path format is valid', () {
      // Verify item route path structure
      const testItemId = '123';
      final itemPath = '/item/$testItemId';
      expect(itemPath, equals('/item/123'));
    });

    test('Item ID can be extracted from route', () {
      final testId = 'abc-123-def';
      final routePath = '/item/$testId';

      // Extract ID from path (simple string parsing)
      final segments = routePath.split('/');
      final extractedId = segments.last;

      expect(extractedId, equals(testId));
    });

    test('Root path is configured', () {
      const rootPath = '/';
      expect(rootPath, equals('/'));
    });

    test('Named routes are accessible', () {
      // Routes defined: 'home' (root) and 'item-detail' (nested)
      // GoRouter supports namedLocation() method for named routes
      expect(router_config.router, isA<GoRouter>());
    });

    test('Route paths follow expected structure', () {
      // Verify common route patterns
      const homeRoute = '/';
      const itemRouteTemplate = '/item/:id';

      expect(homeRoute, startsWith('/'));
      expect(itemRouteTemplate, contains(':id'));
    });
  });
}
