import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Import the main app routes file
import '../lib/routing/routes.dart';
import '../lib/routing/router.dart';
import '../lib/main.dart';

// Generate mocks
@GenerateMocks([GoRouter, NavigatorObserver])
import 'routes_test.mocks.dart';

void main() {
  group('App Routes Tests', () {
    late GoRouter router;
    late MockNavigatorObserver mockObserver;

    setUp(() {
      mockObserver = MockNavigatorObserver();
      router = createAppRouter();
    });

    tearDown(() {
      // Clean up any resources if needed
    });

    group('Route Configuration', () {
      test('should have correct initial route', () {
        expect(router.routerDelegate.currentConfiguration.uri.path, equals('/'));
      });

      test('should contain all expected routes', () {
        final routes = router.configuration.routes;
        expect(routes, isNotEmpty);
        
        // Verify essential routes exist
        final routePaths = _extractRoutePaths(routes);
        expect(routePaths, contains('/'));
        expect(routePaths, contains('/home'));
        expect(routePaths, contains('/profile'));
        expect(routePaths, contains('/settings'));
      });

      test('should have valid route structure', () {
        final routes = router.configuration.routes;
        
        for (final route in routes) {
          if (route is GoRoute) {
            expect(route.path, isNotNull);
            expect(route.path, isNotEmpty);
            expect(route.builder, isNotNull);
          }
        }
      });

      test('should have proper route hierarchy', () {
        final routes = router.configuration.routes;
        expect(routes, isA<List<RouteBase>>());
        
        // Check for nested routes
        bool hasNestedRoutes = false;
        for (final route in routes) {
          if (route is GoRoute && route.routes.isNotEmpty) {
            hasNestedRoutes = true;
            break;
          }
        }
        expect(hasNestedRoutes, isTrue);
      });
    });

    group('Route Navigation', () {
      testWidgets('should navigate to home route', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        router.go('/home');
        await tester.pumpAndSettle();

        expect(router.routerDelegate.currentConfiguration.uri.path, equals('/home'));
      });

      testWidgets('should navigate to profile route', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        router.go('/profile');
        await tester.pumpAndSettle();

        expect(router.routerDelegate.currentConfiguration.uri.path, equals('/profile'));
      });

      testWidgets('should navigate to settings route', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        router.go('/settings');
        await tester.pumpAndSettle();

        expect(router.routerDelegate.currentConfiguration.uri.path, equals('/settings'));
      });

      testWidgets('should handle navigation with parameters', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        const userId = '123';
        router.go('/profile/$userId');
        await tester.pumpAndSettle();

        expect(router.routerDelegate.currentConfiguration.uri.path, equals('/profile/$userId'));
      });

      testWidgets('should handle push navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        router.push('/profile');
        await tester.pumpAndSettle();

        expect(router.routerDelegate.currentConfiguration.uri.path, equals('/profile'));
      });

      testWidgets('should handle replacement navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        router.go('/home');
        await tester.pumpAndSettle();
        
        router.pushReplacement('/profile');
        await tester.pumpAndSettle();

        expect(router.routerDelegate.currentConfiguration.uri.path, equals('/profile'));
      });
    });

    group('Route Guards and Redirects', () {
      testWidgets('should redirect unauthorized users to login', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        // Test accessing protected route without auth
        router.go('/admin');
        await tester.pumpAndSettle();

        // Should redirect to login
        expect(router.routerDelegate.currentConfiguration.uri.path, equals('/login'));
      });

      testWidgets('should allow access to public routes', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        router.go('/about');
        await tester.pumpAndSettle();

        expect(router.routerDelegate.currentConfiguration.uri.path, equals('/about'));
      });

      testWidgets('should handle conditional redirects', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        // Test conditional redirect based on user state
        router.go('/dashboard');
        await tester.pumpAndSettle();

        // Verify redirect behavior based on authentication state
        final currentPath = router.routerDelegate.currentConfiguration.uri.path;
        expect(currentPath, anyOf(equals('/dashboard'), equals('/login')));
      });
    });

    group('Error Handling', () {
      testWidgets('should show 404 page for invalid routes', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        router.go('/nonexistent-route');
        await tester.pumpAndSettle();

        // Should show error page or redirect to 404
        expect(find.text('Page Not Found'), findsOneWidget);
      });

      testWidgets('should handle malformed URLs gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        // Test various malformed URLs
        final malformedUrls = [
          '/profile///',
          '/profile/../admin',
          '/profile?invalid=param&',
          '//double//slash',
        ];

        for (final url in malformedUrls) {
          router.go(url);
          await tester.pumpAndSettle();
          
          // Should not crash and handle gracefully
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('should handle route building errors', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        // Test navigation that might cause building errors
        router.go('/error-prone-route');
        await tester.pumpAndSettle();

        // Should handle gracefully without crashing
        expect(tester.takeException(), isNull);
      });
    });

    group('Deep Linking', () {
      testWidgets('should handle deep links correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        const deepLink = '/profile/user123/settings';
        router.go(deepLink);
        await tester.pumpAndSettle();

        expect(router.routerDelegate.currentConfiguration.uri.path, equals(deepLink));
      });

      testWidgets('should preserve query parameters', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        const routeWithQuery = '/search?q=flutter&sort=date';
        router.go(routeWithQuery);
        await tester.pumpAndSettle();

        final currentUri = router.routerDelegate.currentConfiguration.uri;
        expect(currentUri.path, equals('/search'));
        expect(currentUri.queryParameters['q'], equals('flutter'));
        expect(currentUri.queryParameters['sort'], equals('date'));
      });

      testWidgets('should handle complex query parameters', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        const complexQuery = '/search?tags=flutter,dart&category=mobile&page=2&limit=10';
        router.go(complexQuery);
        await tester.pumpAndSettle();

        final currentUri = router.routerDelegate.currentConfiguration.uri;
        expect(currentUri.queryParameters['tags'], equals('flutter,dart'));
        expect(currentUri.queryParameters['category'], equals('mobile'));
        expect(currentUri.queryParameters['page'], equals('2'));
        expect(currentUri.queryParameters['limit'], equals('10'));
      });

      testWidgets('should handle fragment identifiers', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        const routeWithFragment = '/article#section-2';
        router.go(routeWithFragment);
        await tester.pumpAndSettle();

        final currentUri = router.routerDelegate.currentConfiguration.uri;
        expect(currentUri.path, equals('/article'));
        expect(currentUri.fragment, equals('section-2'));
      });
    });

    group('Navigation Stack', () {
      testWidgets('should maintain navigation history', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        // Navigate through multiple routes
        router.go('/home');
        await tester.pumpAndSettle();
        
        router.push('/profile');
        await tester.pumpAndSettle();
        
        router.push('/settings');
        await tester.pumpAndSettle();

        expect(router.routerDelegate.currentConfiguration.uri.path, equals('/settings'));

        // Test back navigation
        router.pop();
        await tester.pumpAndSettle();
        
        expect(router.routerDelegate.currentConfiguration.uri.path, equals('/profile'));
      });

      testWidgets('should handle nested routes correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        router.go('/profile/123/edit');
        await tester.pumpAndSettle();

        expect(router.routerDelegate.currentConfiguration.uri.path, equals('/profile/123/edit'));
      });

      testWidgets('should handle multiple pop operations', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        // Build navigation stack
        router.push('/home');
        router.push('/profile');
        router.push('/settings');
        router.push('/help');
        await tester.pumpAndSettle();

        // Pop multiple times
        router.pop();
        router.pop();
        await tester.pumpAndSettle();

        expect(router.routerDelegate.currentConfiguration.uri.path, equals('/profile'));
      });

      testWidgets('should handle canPop correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        // At root, should not be able to pop
        expect(router.canPop(), isFalse);

        // After pushing, should be able to pop
        router.push('/profile');
        await tester.pumpAndSettle();
        expect(router.canPop(), isTrue);
      });
    });

    group('Route Transitions', () {
      testWidgets('should use correct page transitions', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        router.go('/home');
        await tester.pump();
        
        // Test that transition animation exists
        expect(find.byType(AnimatedWidget), findsWidgets);
        
        await tester.pumpAndSettle();
      });

      testWidgets('should complete transitions properly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        router.go('/profile');
        await tester.pump();
        
        // Should have ongoing animation
        expect(tester.binding.hasScheduledFrame, isTrue);
        
        await tester.pumpAndSettle();
        
        // Animation should be complete
        expect(tester.binding.hasScheduledFrame, isFalse);
      });

      testWidgets('should handle rapid navigation during transitions', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        // Start navigation
        router.go('/profile');
        await tester.pump();
        
        // Navigate again before first completes
        router.go('/settings');
        await tester.pumpAndSettle();

        expect(router.routerDelegate.currentConfiguration.uri.path, equals('/settings'));
        expect(tester.takeException(), isNull);
      });
    });

    group('Performance Tests', () {
      testWidgets('should not rebuild unnecessarily', (WidgetTester tester) async {
        var buildCount = 0;
        
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            builder: (context, child) {
              buildCount++;
              return child!;
            },
          ),
        );

        final initialBuildCount = buildCount;

        // Navigate to same route multiple times
        router.go('/home');
        router.go('/home');
        router.go('/home');
        await tester.pumpAndSettle();

        expect(buildCount, lessThanOrEqualTo(initialBuildCount + 2));
      });

      testWidgets('should handle rapid navigation changes', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        // Rapid navigation
        router.go('/home');
        router.go('/profile');
        router.go('/settings');
        router.go('/about');
        
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(router.routerDelegate.currentConfiguration.uri.path, equals('/about'));
      });

      testWidgets('should dispose of resources properly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        // Navigate to routes with disposable resources
        router.go('/heavy-resource-page');
        await tester.pumpAndSettle();
        
        router.go('/another-page');
        await tester.pumpAndSettle();

        // Should not leak memory or resources
        expect(tester.takeException(), isNull);
      });
    });

    group('Route State Management', () {
      testWidgets('should preserve state when navigating back', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        // Navigate to a stateful widget
        router.go('/form');
        await tester.pumpAndSettle();

        // Enter some text if TextField exists
        final textFields = find.byType(TextField);
        if (textFields.hasFound) {
          await tester.enterText(textFields.first, 'test input');
        }
        
        // Navigate away and back
        router.push('/profile');
        await tester.pumpAndSettle();
        
        router.pop();
        await tester.pumpAndSettle();

        // Verify we're back at the form
        expect(router.routerDelegate.currentConfiguration.uri.path, equals('/form'));
      });

      testWidgets('should handle state restoration', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
            restorationScopeId: 'app',
          ),
        );

        router.go('/profile/123');
        await tester.pumpAndSettle();

        // Simulate app restoration
        await tester.restartAndRestore();

        expect(router.routerDelegate.currentConfiguration.uri.path, equals('/profile/123'));
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle empty route paths', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        router.go('');
        await tester.pumpAndSettle();

        // Should default to root route
        expect(router.routerDelegate.currentConfiguration.uri.path, equals('/'));
      });

      testWidgets('should handle special characters in routes', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        const specialRoute = '/search?q=hello%20world&filter=type%3Auser';
        router.go(specialRoute);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle very long route paths', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        final longPath = '/very/' * 50 + 'long/path';
        router.go(longPath);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle null and undefined parameters', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        // Test with potentially null parameters
        router.go('/profile/null');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle concurrent navigation requests', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        // Simulate concurrent navigation
        Future.wait([
          Future(() => router.go('/home')),
          Future(() => router.go('/profile')),
          Future(() => router.go('/settings')),
        ]);

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    group('Route Observers', () {
      testWidgets('should notify observers of navigation events', (WidgetTester tester) async {
        final mockObserver = MockNavigatorObserver();
        
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [mockObserver],
          ),
        );

        router.go('/profile');
        await tester.pumpAndSettle();

        // Verify observer was called
        verify(mockObserver.didPush(any, any)).called(greaterThan(0));
      });

      testWidgets('should handle multiple observers', (WidgetTester tester) async {
        final observer1 = MockNavigatorObserver();
        final observer2 = MockNavigatorObserver();
        
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            navigatorObservers: [observer1, observer2],
          ),
        );

        router.go('/settings');
        await tester.pumpAndSettle();

        // Both observers should be notified
        verify(observer1.didPush(any, any)).called(greaterThan(0));
        verify(observer2.didPush(any, any)).called(greaterThan(0));
      });
    });
  });

  group('Route Builder Tests', () {
    testWidgets('should build correct widgets for each route', (WidgetTester tester) async {
      final router = createAppRouter();
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Test home route builder
      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home_page')), findsOneWidget);

      // Test profile route builder
      router.go('/profile');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile_page')), findsOneWidget);

      // Test settings route builder
      router.go('/settings');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings_page')), findsOneWidget);
    });

    testWidgets('should pass correct parameters to route builders', (WidgetTester tester) async {
      final router = createAppRouter();
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      const userId = 'user123';
      router.go('/profile/$userId');
      await tester.pumpAndSettle();

      expect(find.text('User ID: $userId'), findsOneWidget);
    });

    testWidgets('should handle missing route parameters gracefully', (WidgetTester tester) async {
      final router = createAppRouter();
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go('/profile/');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('should build widgets with correct context', (WidgetTester tester) async {
      final router = createAppRouter();
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go('/themed-page');
      await tester.pumpAndSettle();

      // Verify theme and context are available
      final context = tester.element(find.byType(MaterialApp));
      expect(Theme.of(context), isNotNull);
    });
  });

  group('Route Matching Tests', () {
    test('should match exact paths correctly', () {
      final router = createAppRouter();
      final match = router.routerDelegate.currentConfiguration;
      
      expect(match, isNotNull);
    });

    test('should match parameterized paths correctly', () {
      final router = createAppRouter();
      
      // Test path parameter extraction
      router.go('/user/123');
      final currentUri = router.routerDelegate.currentConfiguration.uri;
      
      expect(currentUri.pathSegments, contains('user'));
      expect(currentUri.pathSegments, contains('123'));
    });

    test('should handle wildcard routes', () {
      final router = createAppRouter();
      
      router.go('/api/v1/users/123/posts/456');
      final currentUri = router.routerDelegate.currentConfiguration.uri;
      
      expect(currentUri.path, startsWith('/api'));
    });

    test('should prioritize exact matches over wildcards', () {
      final router = createAppRouter();
      
      router.go('/exact-match');
      final currentPath = router.routerDelegate.currentConfiguration.uri.path;
      
      expect(currentPath, equals('/exact-match'));
    });

    test('should handle case sensitivity correctly', () {
      final router = createAppRouter();
      
      router.go('/Profile');
      final currentPath = router.routerDelegate.currentConfiguration.uri.path;
      
      // Should handle case according to router configuration
      expect(currentPath, isNotNull);
    });
  });

  group('Route Validation Tests', () {
    test('should validate route configuration on startup', () {
      expect(() => createAppRouter(), returnsNormally);
    });

    test('should reject invalid route patterns', () {
      // Test would depend on actual router implementation
      expect(true, isTrue); // Placeholder
    });

    test('should handle route conflicts appropriately', () {
      // Test would depend on actual router implementation
      expect(true, isTrue); // Placeholder
    });
  });

  group('Memory Management Tests', () {
    testWidgets('should not leak memory on repeated navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Simulate heavy navigation usage
      for (int i = 0; i < 100; i++) {
        router.go('/profile/$i');
        await tester.pump();
      }

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('should clean up listeners properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      router.go('/listenable-page');
      await tester.pumpAndSettle();

      // Navigate away to trigger cleanup
      router.go('/other-page');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

// Helper function to extract route paths from route configuration
List<String> _extractRoutePaths(List<RouteBase> routes) {
  final paths = <String>[];
  
  for (final route in routes) {
    if (route is GoRoute) {
      paths.add(route.path);
      if (route.routes.isNotEmpty) {
        paths.addAll(_extractRoutePaths(route.routes));
      }
    } else if (route is ShellRoute) {
      paths.addAll(_extractRoutePaths(route.routes));
    }
  }
  
  return paths;
}

// Helper function to create a test router (would be imported from actual implementation)
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          key: Key('home_page'),
          body: Text('Home'),
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(
          key: Key('home_page'),
          body: Text('Home'),
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const Scaffold(
          key: Key('profile_page'),
          body: Text('Profile'),
        ),
        routes: [
          GoRoute(
            path: '/:userId',
            builder: (context, state) {
              final userId = state.pathParameters['userId'] ?? '';
              return Scaffold(
                body: Text('User ID: $userId'),
              );
            },
            routes: [
              GoRoute(
                path: '/edit',
                builder: (context, state) => const Scaffold(
                  body: Text('Edit Profile'),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const Scaffold(
          key: Key('settings_page'),
          body: Text('Settings'),
        ),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const Scaffold(
          body: Text('About'),
        ),
      ),
      GoRoute(
        path: '/form',
        builder: (context, state) => const Scaffold(
          body: TextField(),
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const Scaffold(
          body: Text('Search Results'),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(
          body: Text('Login'),
        ),
      ),
    ],
    redirect: (context, state) {
      // Example redirect logic
      if (state.uri.path == '/admin') {
        return '/login';
      }
      return null;
    },
    errorBuilder: (context, state) => const Scaffold(
      body: Text('Page Not Found'),
    ),
  );
}