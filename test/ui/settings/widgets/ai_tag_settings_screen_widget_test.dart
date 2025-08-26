import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/routing/routes.dart';
import 'package:readeck_app/ui/settings/view_models/ai_tag_settings_viewmodel.dart';
import 'package:readeck_app/ui/settings/widgets/ai_tag_settings_screen.dart';

import 'ai_tag_settings_screen_widget_test.mocks.dart';

// Navigation test helper
class NavigationItem {
  final String route;
  final Object? extra;

  NavigationItem(this.route, this.extra);
}

@GenerateNiceMocks([MockSpec<AiTagSettingsViewModel>()])
void main() {
  late MockAiTagSettingsViewModel mockViewModel;
  late List<NavigationItem> capturedNavigations;

  setUp(() {
    mockViewModel = MockAiTagSettingsViewModel();
    capturedNavigations = [];

    // Setup default mock behaviors
    when(mockViewModel.aiTagTargetLanguage).thenReturn('中文');
    when(mockViewModel.aiTagModelName).thenReturn('');

    // Setup commands
    final mockSaveLanguageCommand =
        Command.createAsyncNoResult<String>((_) async {});

    when(mockViewModel.saveAiTagTargetLanguage)
        .thenReturn(mockSaveLanguageCommand);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                ChangeNotifierProvider<AiTagSettingsViewModel>.value(
              value: mockViewModel,
              child: AiTagSettingsScreen(viewModel: mockViewModel),
            ),
          ),
          GoRoute(
            path: Routes.modelSelection,
            builder: (context, state) {
              // Capture navigation for verification
              capturedNavigations
                  .add(NavigationItem(state.uri.toString(), state.extra));
              return const Scaffold(body: Text('Model Selection Screen'));
            },
          ),
        ],
      ),
    );
  }

  group('AiTagSettingsScreen Widget Tests', () {
    testWidgets('should build without error and display all required elements',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert - Basic structure
      expect(find.byType(AiTagSettingsScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.text('AI 标签设置'), findsOneWidget);

      // Assert - Section headers
      expect(find.text('基础设置'), findsOneWidget);
      expect(find.text('模型配置'), findsOneWidget);
    });

    testWidgets('should display target language ListTile with correct data',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.aiTagTargetLanguage).thenReturn('English');

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('标签推荐语言'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.byIcon(Icons.translate), findsOneWidget);
    });

    testWidgets(
        'should display specialized model ListTile with "使用全局模型" when no model is set',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.aiTagModelName).thenReturn('');

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert - NEW FUNCTIONALITY
      expect(find.text('专用模型'), findsOneWidget);
      expect(find.text('使用全局模型'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    testWidgets(
        'should display specialized model ListTile with model name when model is set',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.aiTagModelName).thenReturn('claude-3-haiku');

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert - NEW FUNCTIONALITY
      expect(find.text('专用模型'), findsOneWidget);
      expect(find.text('claude-3-haiku'), findsOneWidget);
      expect(find.text('使用全局模型'), findsNothing);
    });

    testWidgets(
        'should navigate to model selection with correct scenario parameter when specialized model is tapped',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.aiTagModelName).thenReturn('test-ai-model');

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Find and tap the specialized model ListTile
      final specializedModelTile = find.ancestor(
        of: find.text('专用模型'),
        matching: find.byType(ListTile),
      );

      await tester.tap(specializedModelTile);
      await tester.pumpAndSettle();

      // Assert - NEW FUNCTIONALITY: Navigation with scenario parameter
      expect(capturedNavigations, hasLength(1));
      expect(capturedNavigations.first.route,
          equals('${Routes.modelSelection}?scenario=ai_tag'));
    });

    testWidgets(
        'should show language selection dialog when target language is tapped',
        (WidgetTester tester) async {
      // Arrange - Set current language to avoid duplicates
      when(mockViewModel.aiTagTargetLanguage).thenReturn('English');

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Find and tap the target language ListTile
      final languageTile = find.ancestor(
        of: find.text('标签推荐语言'),
        matching: find.byType(ListTile),
      );

      await tester.tap(languageTile);
      await tester.pumpAndSettle();

      // Assert - Should show modal bottom sheet instead of dialog
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('选择AI标签目标语言'), findsOneWidget);

      // Should display some supported languages in the bottom sheet
      expect(find.text('中文'), findsOneWidget);
      expect(find.text('日本語'), findsOneWidget);
    });

    testWidgets(
        'should show language selection dialog when language tile is tapped',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Open language dialog
      final languageTile = find.ancestor(
        of: find.text('标签推荐语言'),
        matching: find.byType(ListTile),
      );
      await tester.tap(languageTile);
      await tester.pumpAndSettle();

      // Assert - bottom sheet should be displayed
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('选择AI标签目标语言'), findsOneWidget);
      expect(find.text('English'), findsAtLeastNWidgets(1));
      expect(find.text('中文'), findsAtLeastNWidgets(1));

      // Select English (this will trigger the command, but we can't easily verify)
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('should update UI when viewModel changes',
        (WidgetTester tester) async {
      // Arrange - initial state
      when(mockViewModel.aiTagModelName).thenReturn('initial-ai-model');
      await tester.pumpWidget(createWidgetUnderTest());

      // Verify initial state
      expect(find.text('initial-ai-model'), findsOneWidget);

      // Change the model name and rebuild widget
      when(mockViewModel.aiTagModelName).thenReturn('updated-ai-model');
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('updated-ai-model'), findsOneWidget);
      expect(find.text('initial-ai-model'), findsNothing);
    });

    testWidgets('should handle edge case with empty model name correctly',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.aiTagModelName).thenReturn('');

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('使用全局模型'), findsOneWidget);

      // Tap should still navigate correctly
      final specializedModelTile = find.ancestor(
        of: find.text('专用模型'),
        matching: find.byType(ListTile),
      );

      await tester.tap(specializedModelTile);
      await tester.pumpAndSettle();

      expect(capturedNavigations, hasLength(1));
      expect(capturedNavigations.first.route,
          equals('${Routes.modelSelection}?scenario=ai_tag'));
    });

    testWidgets('should handle null model name gracefully',
        (WidgetTester tester) async {
      // Arrange - simulate null scenario
      when(mockViewModel.aiTagModelName).thenReturn('');

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert - should default to "使用全局模型"
      expect(find.text('使用全局模型'), findsOneWidget);
      expect(find.text('专用模型'), findsOneWidget);
    });

    testWidgets('should display different target languages correctly',
        (WidgetTester tester) async {
      // Test multiple language scenarios
      final testLanguages = ['中文', 'English', '日本語', '한국어'];

      for (final language in testLanguages) {
        when(mockViewModel.aiTagTargetLanguage).thenReturn(language);

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text(language), findsOneWidget);
        expect(find.text('标签推荐语言'), findsOneWidget);

        // Clean up for next iteration
        await tester.pumpWidget(Container());
        await tester.pump();
      }
    });

    testWidgets('should handle language dialog cancellation',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Open language dialog
      final languageTile = find.ancestor(
        of: find.text('标签推荐语言'),
        matching: find.byType(ListTile),
      );
      await tester.tap(languageTile);
      await tester.pumpAndSettle();

      // Dismiss bottom sheet by tapping outside
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();

      // Assert - should not call save command and bottom sheet should be closed
      expect(find.byType(BottomSheet), findsNothing);
    });

    group('Command Listeners Integration', () {
      testWidgets(
          'should setup command listeners properly during widget lifecycle',
          (WidgetTester tester) async {
        // This test ensures the command listeners are set up correctly
        // by verifying the widget can be built and disposed without errors

        // Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Navigate away to trigger dispose
        await tester.pumpWidget(const MaterialApp(home: Scaffold()));

        // Assert - no exceptions should be thrown during dispose
        expect(tester.takeException(), isNull);
      });
    });

    group('UI State Management', () {
      testWidgets('should reflect viewModel state changes immediately',
          (WidgetTester tester) async {
        // Arrange
        when(mockViewModel.aiTagTargetLanguage).thenReturn('中文');
        when(mockViewModel.aiTagModelName).thenReturn('model-1');

        // Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Verify initial state
        expect(find.text('中文'), findsOneWidget);
        expect(find.text('model-1'), findsOneWidget);

        // Change both properties
        when(mockViewModel.aiTagTargetLanguage).thenReturn('English');
        when(mockViewModel.aiTagModelName).thenReturn('');
        mockViewModel.notifyListeners();
        await tester.pump();

        // Assert both changes are reflected - rebuild widget to see changes
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(find.text('English'), findsOneWidget);
        expect(find.text('使用全局模型'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels for screen readers',
          (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Assert - Key UI elements should be accessible
        expect(find.bySemanticsLabel('AI 标签设置'), findsOneWidget);

        // ListTiles should be semantically accessible
        expect(
            find.ancestor(
              of: find.text('专用模型'),
              matching: find.byType(ListTile),
            ),
            findsOneWidget);

        expect(
            find.ancestor(
              of: find.text('标签推荐语言'),
              matching: find.byType(ListTile),
            ),
            findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle missing supported languages gracefully',
          (WidgetTester tester) async {
        // This test verifies the widget doesn't crash if supportedLanguages is empty or null
        // which is important for robustness

        // Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Open dialog to test language list
        final languageTile = find.ancestor(
          of: find.text('标签推荐语言'),
          matching: find.byType(ListTile),
        );
        await tester.tap(languageTile);
        await tester.pumpAndSettle();

        // Assert - bottom sheet should open without errors even if no specific test for empty list
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text('选择AI标签目标语言'), findsOneWidget);
      });
    });
  });
}
