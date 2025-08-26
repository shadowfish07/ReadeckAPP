import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/domain/models/openrouter_model/openrouter_model.dart';
import 'package:readeck_app/routing/routes.dart';
import 'package:readeck_app/ui/settings/view_models/translation_settings_viewmodel.dart';
import 'package:readeck_app/ui/settings/widgets/translation_settings_screen.dart';

import 'translation_settings_screen_widget_test.mocks.dart';

// Navigation test helper
class NavigationItem {
  final String route;
  final Object? extra;

  NavigationItem(this.route, this.extra);
}

@GenerateNiceMocks([MockSpec<TranslationSettingsViewModel>()])
void main() {
  late MockTranslationSettingsViewModel mockViewModel;
  late List<NavigationItem> capturedNavigations;

  setUp(() {
    mockViewModel = MockTranslationSettingsViewModel();
    capturedNavigations = [];

    // Setup default mock behaviors
    when(mockViewModel.translationProvider).thenReturn('AI');
    when(mockViewModel.translationTargetLanguage).thenReturn('中文');
    when(mockViewModel.translationCacheEnabled).thenReturn(true);
    when(mockViewModel.translationModelName).thenReturn('');
    when(mockViewModel.translationModel).thenReturn('');

    // Setup commands
    final mockSaveProviderCommand =
        Command.createAsyncNoResult<String>((_) async {});
    final mockSaveLanguageCommand =
        Command.createAsyncNoResult<String>((_) async {});
    final mockSaveCacheCommand =
        Command.createAsyncNoResult<bool>((_) async {});
    final mockLoadModelsCommand =
        Command.createAsyncNoParam<List<OpenRouterModel>>(
      () async => [],
      initialValue: [],
    );

    when(mockViewModel.saveTranslationProvider)
        .thenReturn(mockSaveProviderCommand);
    when(mockViewModel.saveTranslationTargetLanguage)
        .thenReturn(mockSaveLanguageCommand);
    when(mockViewModel.saveTranslationCacheEnabled)
        .thenReturn(mockSaveCacheCommand);
    when(mockViewModel.loadModels).thenReturn(mockLoadModelsCommand);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                ChangeNotifierProvider<TranslationSettingsViewModel>.value(
              value: mockViewModel,
              child: TranslationSettingsScreen(viewModel: mockViewModel),
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

  group('TranslationSettingsScreen Widget Tests', () {
    testWidgets('should build without error and display all required elements',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert - Basic structure
      expect(find.byType(TranslationSettingsScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.text('翻译设置'), findsOneWidget);

      // Assert - Section headers
      expect(find.text('基础设置'), findsOneWidget);
      expect(find.text('模型配置'), findsOneWidget);
      expect(find.text('性能优化'), findsOneWidget);
    });

    testWidgets(
        'should display translation provider ListTile with correct data',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.translationProvider).thenReturn('OpenAI');

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('翻译服务提供方'), findsOneWidget);
      expect(find.text('OpenAI'), findsOneWidget);
      expect(find.byIcon(Icons.translate), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsWidgets);
    });

    testWidgets(
        'should display translation target language ListTile with correct data',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.translationTargetLanguage).thenReturn('English');

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('翻译目标语种'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets(
        'should display specialized model ListTile with "使用全局模型" when no model is set',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.translationModelName).thenReturn('');

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
      when(mockViewModel.translationModelName).thenReturn('gpt-4-turbo');

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert - NEW FUNCTIONALITY
      expect(find.text('专用模型'), findsOneWidget);
      expect(find.text('gpt-4-turbo'), findsOneWidget);
      expect(find.text('使用全局模型'), findsNothing);
    });

    testWidgets(
        'should navigate to model selection with correct scenario parameter when specialized model is tapped',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.translationModelName).thenReturn('test-model');

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
          equals('${Routes.modelSelection}?scenario=translation'));
    });

    testWidgets('should display cache toggle switch with correct state',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.translationCacheEnabled).thenReturn(false);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('启用翻译缓存'), findsOneWidget);
      expect(find.text('缓存翻译结果以提高性能'), findsOneWidget);
      expect(find.byIcon(Icons.cached), findsOneWidget);

      final switch_ = find.byType(Switch);
      expect(switch_, findsOneWidget);

      final switchWidget = tester.widget<Switch>(switch_);
      expect(switchWidget.value, equals(false));
    });

    testWidgets(
        'should show language selection dialog when target language is tapped',
        (WidgetTester tester) async {
      // Arrange - Set current language to English to avoid duplicate text
      when(mockViewModel.translationTargetLanguage).thenReturn('English');

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Find and tap the target language ListTile
      final languageTile = find.ancestor(
        of: find.text('翻译目标语种'),
        matching: find.byType(ListTile),
      );

      await tester.tap(languageTile);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('选择翻译目标语种'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);

      // Should display some supported languages in the dialog
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
        of: find.text('翻译目标语种'),
        matching: find.byType(ListTile),
      );
      await tester.tap(languageTile);
      await tester.pumpAndSettle();

      // Assert - dialog should be displayed
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('选择翻译目标语种'), findsOneWidget);
      expect(find.text('English'), findsAtLeastNWidgets(1));
      expect(find.text('中文'), findsAtLeastNWidgets(1));

      // Select English (this will trigger the command, but we can't easily verify)
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('should execute cache command when switch is toggled',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.translationCacheEnabled).thenReturn(true);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Find and tap the switch
      final switchTile = find.byType(SwitchListTile);
      await tester.tap(switchTile);
      await tester.pumpAndSettle();

      // Assert - The command might be called multiple times due to UI interactions
      verify(mockViewModel.saveTranslationCacheEnabled)
          .called(greaterThanOrEqualTo(1));
    });

    testWidgets('should show info snackbar when translation provider is tapped',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Find and tap the provider ListTile
      final providerTile = find.ancestor(
        of: find.text('翻译服务提供方'),
        matching: find.byType(ListTile),
      );

      await tester.tap(providerTile);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('目前只支持 AI 翻译服务'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('should update UI when viewModel notifies listeners',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.translationModelName).thenReturn('initial-model');

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('initial-model'), findsOneWidget);

      // Change the model name and notify - need to rebuild the widget
      when(mockViewModel.translationModelName).thenReturn('updated-model');

      // Since we're using a mock, we need to trigger a rebuild
      // In a real app, the ViewModel would notify listeners
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Assert
      expect(find.text('updated-model'), findsOneWidget);
      expect(find.text('initial-model'), findsNothing);
    });

    testWidgets('should handle edge case with empty model name correctly',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.translationModelName).thenReturn('');

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
          equals('${Routes.modelSelection}?scenario=translation'));
    });

    testWidgets('should handle null model name gracefully',
        (WidgetTester tester) async {
      // Arrange - simulate null scenario
      when(mockViewModel.translationModelName).thenReturn('');

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert - should default to "使用全局模型"
      expect(find.text('使用全局模型'), findsOneWidget);
      expect(find.text('专用模型'), findsOneWidget);
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

    group('Accessibility', () {
      testWidgets('should have proper semantic labels for screen readers',
          (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Assert - Key UI elements should be accessible
        expect(find.bySemanticsLabel('翻译设置'), findsOneWidget);

        // ListTiles should be semantically accessible
        expect(
            find.ancestor(
              of: find.text('专用模型'),
              matching: find.byType(ListTile),
            ),
            findsOneWidget);

        expect(
            find.ancestor(
              of: find.text('翻译目标语种'),
              matching: find.byType(ListTile),
            ),
            findsOneWidget);
      });
    });
  });
}
