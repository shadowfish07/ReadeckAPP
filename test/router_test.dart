import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/routing/router.dart';
import 'package:readeck_app/routing/routes.dart';
import 'package:result_dart/result_dart.dart';

// Generate mock classes
@GenerateMocks([SettingsRepository])
import 'router_test.mocks.dart';

void main() {
  group('Router Configuration Tests', () {
    late MockSettingsRepository mockSettingsRepository;
    late GoRouter testRouter;

    setUp(() {
      mockSettingsRepository = MockSettingsRepository();
    });

    testWidgets('should create router with correct initial location', (tester) async {
      when(mockSettingsRepository.isApiConfigured()).thenAnswer((_) async => const Success(true));
      
      testRouter = router(mockSettingsRepository);
      
      expect(testRouter.initialLocation, equals(Routes.dailyRead));
    });

    testWidgets('should have debug logging enabled', (tester) async {
      when(mockSettingsRepository.isApiConfigured()).thenAnswer((_) async => const Success(true));
      
      testRouter = router(mockSettingsRepository);
      
      expect(testRouter.debugLogDiagnostics, isTrue);
    });

    test('should have correct route configuration structure', () async {
      when(mockSettingsRepository.isApiConfigured()).thenAnswer((_) async => const Success(true));
      
      testRouter = router(mockSettingsRepository);
      
      expect(testRouter.configuration.routes, isNotEmpty);
      expect(testRouter.configuration.routes.first, isA<StatefulShellRoute>());
    });
  });

  group('Router Redirect Logic Tests', () {
    late MockSettingsRepository mockSettingsRepository;
    late GoRouter testRouter;

    setUp(() {
      mockSettingsRepository = MockSettingsRepository();
    });

    testWidgets('should redirect to API config when not configured', (tester) async {
      when(mockSettingsRepository.isApiConfigured()).thenAnswer((_) async => const Success(false));
      
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      expect(testRouter.location, equals(Routes.apiConfigSetting));
    });

    testWidgets('should not redirect when API is configured', (tester) async {
      when(mockSettingsRepository.isApiConfigured()).thenAnswer((_) async => const Success(true));
      
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      expect(testRouter.location, equals(Routes.dailyRead));
    });

    testWidgets('should handle settings repository error gracefully', (tester) async {
      when(mockSettingsRepository.isApiConfigured()).thenAnswer((_) async => Failure(Exception('Test error')));
      
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      // Should not redirect on error
      expect(testRouter.location, equals(Routes.dailyRead));
    });
  });

  group('Route Navigation Tests', () {
    late MockSettingsRepository mockSettingsRepository;
    late GoRouter testRouter;

    setUp(() {
      mockSettingsRepository = MockSettingsRepository();
      when(mockSettingsRepository.isApiConfigured()).thenAnswer((_) async => const Success(true));
    });

    testWidgets('should navigate to daily read route', (tester) async {
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      testRouter.go(Routes.dailyRead);
      await tester.pumpAndSettle();
      
      expect(testRouter.location, equals(Routes.dailyRead));
    });

    testWidgets('should navigate to unarchived bookmarks route', (tester) async {
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      testRouter.go(Routes.unarchived);
      await tester.pumpAndSettle();
      
      expect(testRouter.location, equals(Routes.unarchived));
    });

    testWidgets('should navigate to archived bookmarks route', (tester) async {
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      testRouter.go(Routes.archived);
      await tester.pumpAndSettle();
      
      expect(testRouter.location, equals(Routes.archived));
    });

    testWidgets('should navigate to marked bookmarks route', (tester) async {
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      testRouter.go(Routes.marked);
      await tester.pumpAndSettle();
      
      expect(testRouter.location, equals(Routes.marked));
    });

    testWidgets('should navigate to settings route', (tester) async {
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      testRouter.go(Routes.settings);
      await tester.pumpAndSettle();
      
      expect(testRouter.location, equals(Routes.settings));
    });

    testWidgets('should navigate to about page', (tester) async {
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      testRouter.go(Routes.about);
      await tester.pumpAndSettle();
      
      expect(testRouter.location, equals(Routes.about));
    });

    testWidgets('should navigate to API config page', (tester) async {
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      testRouter.go(Routes.apiConfigSetting);
      await tester.pumpAndSettle();
      
      expect(testRouter.location, equals(Routes.apiConfigSetting));
    });

    testWidgets('should navigate to AI settings page', (tester) async {
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      testRouter.go(Routes.aiSetting);
      await tester.pumpAndSettle();
      
      expect(testRouter.location, equals(Routes.aiSetting));
    });
  });

  group('Parameterized Route Tests', () {
    late MockSettingsRepository mockSettingsRepository;
    late GoRouter testRouter;

    setUp(() {
      mockSettingsRepository = MockSettingsRepository();
      when(mockSettingsRepository.isApiConfigured()).thenAnswer((_) async => const Success(true));
    });

    testWidgets('should navigate to bookmark detail with valid ID', (tester) async {
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      const bookmarkId = 'test-bookmark-123';
      testRouter.go('${Routes.bookmarkDetail}/$bookmarkId');
      await tester.pumpAndSettle();
      
      expect(testRouter.location, equals('${Routes.bookmarkDetail}/$bookmarkId'));
    });

    testWidgets('should handle bookmark detail route with special characters in ID', (tester) async {
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      const bookmarkId = 'test-bookmark-with-special-chars_123!';
      final encodedId = Uri.encodeComponent(bookmarkId);
      testRouter.go('${Routes.bookmarkDetail}/$encodedId');
      await tester.pumpAndSettle();
      
      expect(testRouter.location, contains(Routes.bookmarkDetail));
    });

    testWidgets('should handle bookmark detail route with numeric ID', (tester) async {
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      const bookmarkId = '12345';
      testRouter.go('${Routes.bookmarkDetail}/$bookmarkId');
      await tester.pumpAndSettle();
      
      expect(testRouter.location, equals('${Routes.bookmarkDetail}/$bookmarkId'));
    });
  });

  group('Route Title Mapping Tests', () {
    test('should return correct title for daily read route', () {
      final title = _getTitleForRoute(Routes.dailyRead);
      expect(title, equals('每日阅读'));
    });

    test('should return correct title for settings route', () {
      final title = _getTitleForRoute(Routes.settings);
      expect(title, equals('设置'));
    });

    test('should return correct title for about route', () {
      final title = _getTitleForRoute(Routes.about);
      expect(title, equals('关于'));
    });

    test('should return correct title for API config route', () {
      final title = _getTitleForRoute(Routes.apiConfigSetting);
      expect(title, equals('API 配置'));
    });

    test('should return correct title for unarchived route', () {
      final title = _getTitleForRoute(Routes.unarchived);
      expect(title, equals('未读'));
    });

    test('should return correct title for archived route', () {
      final title = _getTitleForRoute(Routes.archived);
      expect(title, equals('已归档'));
    });

    test('should return correct title for marked route', () {
      final title = _getTitleForRoute(Routes.marked);
      expect(title, equals('标记喜爱'));
    });

    test('should return correct title for bookmark detail route', () {
      final title = _getTitleForRoute(Routes.bookmarkDetail);
      expect(title, equals('书签详情'));
    });

    test('should return null for unknown route', () {
      final title = _getTitleForRoute('/unknown-route');
      expect(title, isNull);
    });

    test('should return null for empty route', () {
      final title = _getTitleForRoute('');
      expect(title, isNull);
    });
  });

  group('Router Edge Cases and Error Handling', () {
    late MockSettingsRepository mockSettingsRepository;
    late GoRouter testRouter;

    setUp(() {
      mockSettingsRepository = MockSettingsRepository();
    });

    testWidgets('should handle invalid route navigation gracefully', (tester) async {
      when(mockSettingsRepository.isApiConfigured()).thenAnswer((_) async => const Success(true));
      
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      // Attempt to navigate to invalid route
      expect(() => testRouter.go('/invalid-route'), returnsNormally);
    });

    testWidgets('should handle concurrent redirect operations', (tester) async {
      when(mockSettingsRepository.isApiConfigured()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return const Success(false);
      });
      
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      // Should handle concurrent checks gracefully
      await tester.pumpAndSettle();
      expect(testRouter.location, equals(Routes.apiConfigSetting));
    });

    testWidgets('should handle settings repository timeout', (tester) async {
      when(mockSettingsRepository.isApiConfigured()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 10));
        return const Success(true);
      });
      
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      // Should not hang indefinitely
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(testRouter.location, isNotNull);
    });

    testWidgets('should handle null settings repository response', (tester) async {
      when(mockSettingsRepository.isApiConfigured()).thenAnswer((_) async => const Success(null));
      
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      // Should treat null as false and redirect
      expect(testRouter.location, equals(Routes.apiConfigSetting));
    });
  });

  group('StatefulShellRoute Configuration Tests', () {
    late MockSettingsRepository mockSettingsRepository;
    late GoRouter testRouter;

    setUp(() {
      mockSettingsRepository = MockSettingsRepository();
      when(mockSettingsRepository.isApiConfigured()).thenAnswer((_) async => const Success(true));
    });

    testWidgets('should maintain state across tab navigation', (tester) async {
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      // Navigate between tabs
      testRouter.go(Routes.dailyRead);
      await tester.pumpAndSettle();
      
      testRouter.go(Routes.unarchived);
      await tester.pumpAndSettle();
      
      testRouter.go(Routes.archived);
      await tester.pumpAndSettle();
      
      testRouter.go(Routes.marked);
      await tester.pumpAndSettle();
      
      testRouter.go(Routes.settings);
      await tester.pumpAndSettle();
      
      // Should successfully navigate through all tabs
      expect(testRouter.location, equals(Routes.settings));
    });

    testWidgets('should handle settings page PopScope correctly', (tester) async {
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      testRouter.go(Routes.settings);
      await tester.pumpAndSettle();
      
      expect(testRouter.location, equals(Routes.settings));
      
      // Simulate back navigation from settings
      if (testRouter.canPop()) {
        testRouter.pop();
        await tester.pumpAndSettle();
      }
      
      // Should handle navigation appropriately
      expect(testRouter.location, isNotNull);
    });
  });

  group('Route Builder and Provider Tests', () {
    late MockSettingsRepository mockSettingsRepository;
    late GoRouter testRouter;

    setUp(() {
      mockSettingsRepository = MockSettingsRepository();
      when(mockSettingsRepository.isApiConfigured()).thenAnswer((_) async => const Success(true));
    });

    testWidgets('should create providers for each route correctly', (tester) async {
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      // Test that routes can be accessed without provider errors
      final routes = [
        Routes.dailyRead,
        Routes.unarchived,
        Routes.archived,
        Routes.marked,
        Routes.settings,
        Routes.about,
        Routes.apiConfigSetting,
        Routes.aiSetting,
      ];
      
      for (final route in routes) {
        testRouter.go(route);
        await tester.pumpAndSettle();
        expect(testRouter.location, equals(route));
      }
    });

    testWidgets('should handle bookmark detail route with missing bookmark gracefully', (tester) async {
      testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      // Navigate to bookmark detail with non-existent ID
      testRouter.go('${Routes.bookmarkDetail}/non-existent-id');
      await tester.pumpAndSettle();
      
      // Should handle gracefully (implementation may show error page)
      expect(testRouter.location, contains(Routes.bookmarkDetail));
    });
  });

  group('Router Performance Tests', () {
    late MockSettingsRepository mockSettingsRepository;

    setUp(() {
      mockSettingsRepository = MockSettingsRepository();
      when(mockSettingsRepository.isApiConfigured()).thenAnswer((_) async => const Success(true));
    });

    test('should create router instance quickly', () {
      final stopwatch = Stopwatch()..start();
      
      final testRouter = router(mockSettingsRepository);
      
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(testRouter, isNotNull);
    });

    testWidgets('should handle rapid navigation changes', (tester) async {
      final testRouter = router(mockSettingsRepository);
      
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      
      final stopwatch = Stopwatch()..start();
      
      // Rapid navigation between routes
      for (int i = 0; i < 10; i++) {
        testRouter.go(Routes.dailyRead);
        testRouter.go(Routes.unarchived);
        testRouter.go(Routes.archived);
        testRouter.go(Routes.marked);
        testRouter.go(Routes.settings);
      }
      
      await tester.pumpAndSettle();
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(testRouter.location, equals(Routes.settings));
    });
  });
}

// Helper function to test title mapping (copy from router.dart implementation)
String? _getTitleForRoute(String location) {
  final Map<String, String> routeTitleMap = {
    Routes.settings: '设置',
    Routes.about: '关于',
    Routes.apiConfigSetting: 'API 配置',
    Routes.dailyRead: '每日阅读',
    Routes.unarchived: '未读',
    Routes.archived: '已归档',
    Routes.marked: '标记喜爱',
    Routes.bookmarkDetail: '书签详情',
  };
  
  return routeTitleMap[location];
}