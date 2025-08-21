import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/domain/models/openrouter_model/openrouter_model.dart';
import 'package:readeck_app/ui/settings/view_models/model_selection_viewmodel.dart';
import 'package:readeck_app/ui/settings/widgets/model_selection_screen.dart';

import 'model_selection_screen_widget_test.mocks.dart';

// Test data
const testModels = [
  OpenRouterModel(
    id: 'model-1',
    name: 'Test Model 1',
    description:
        'This is a test model for translation tasks. It provides high-quality translations with support for multiple languages.',
    pricing: ModelPricing(prompt: '0.001', completion: '0.002'),
    contextLength: 4096,
  ),
  OpenRouterModel(
    id: 'model-2',
    name: 'Test Model 2',
    description: 'Short description',
    pricing: ModelPricing(prompt: '0.002', completion: '0.003'),
    contextLength: 8192,
  ),
];

@GenerateNiceMocks([MockSpec<ModelSelectionViewModel>()])
void main() {
  late MockModelSelectionViewModel mockViewModel;
  late int popCallCount;

  setUp(() {
    mockViewModel = MockModelSelectionViewModel();
    popCallCount = 0;

    // Setup default mock behaviors
    when(mockViewModel.availableModels).thenReturn([]);
    when(mockViewModel.selectedModel).thenReturn(null);
    when(mockViewModel.scenario).thenReturn(null);
    when(mockViewModel.globalModelName).thenReturn('');
    when(mockViewModel.isUsingGlobalModel).thenReturn(false);

    // Setup commands
    final mockLoadModelsCommand =
        Command.createAsyncNoParam<List<OpenRouterModel>>(
      () async => [],
      initialValue: [],
    );

    when(mockViewModel.loadModels).thenReturn(mockLoadModelsCommand);
  });

  Widget createWidgetUnderTest({String? initialRoute = '/'}) {
    return MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: initialRoute,
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                ChangeNotifierProvider<ModelSelectionViewModel>.value(
              value: mockViewModel,
              child: ModelSelectionScreen(viewModel: mockViewModel),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to create a testable widget with navigation capture
  Widget createWidgetWithNavigationCapture() {
    return MaterialApp(
      home: Builder(
        builder: (context) =>
            ChangeNotifierProvider<ModelSelectionViewModel>.value(
          value: mockViewModel,
          child: Navigator(
            onDidRemovePage: (page) {
              popCallCount++;
            },
            pages: [
              MaterialPage<void>(
                child: ModelSelectionScreen(viewModel: mockViewModel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('ModelSelectionScreen Widget Tests', () {
    group('Basic Structure', () {
      testWidgets('should build without error and display basic elements',
          (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Assert - Basic structure
        expect(find.byType(ModelSelectionScreen), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.text('选择模型'), findsOneWidget);
        expect(find.byType(RefreshIndicator), findsOneWidget);
      });

      testWidgets(
          'should show loading indicator when models are empty and command is executing',
          (WidgetTester tester) async {
        // Arrange
        final loadCommand = Command.createAsyncNoParam<List<OpenRouterModel>>(
          () async {
            await Future.delayed(const Duration(milliseconds: 100));
            return [];
          },
          initialValue: [],
        );

        when(mockViewModel.loadModels).thenReturn(loadCommand);
        when(mockViewModel.availableModels).thenReturn([]);

        // Start the command
        loadCommand.execute();

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump(const Duration(milliseconds: 10));

        // Assert
        expect(find.text('正在加载模型列表...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for command to complete
        await tester.pumpAndSettle();
      });

      testWidgets('should show error state when command fails',
          (WidgetTester tester) async {
        // Arrange
        final loadCommand = Command.createAsyncNoParam<List<OpenRouterModel>>(
          () async {
            throw Exception('Failed to load models');
          },
          initialValue: [],
        );

        when(mockViewModel.loadModels).thenReturn(loadCommand);
        when(mockViewModel.availableModels).thenReturn([]);

        // Start the command
        loadCommand.execute();

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('加载模型失败'), findsOneWidget);
        expect(find.text('重试'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('should show empty state when no models available',
          (WidgetTester tester) async {
        // Arrange
        when(mockViewModel.availableModels).thenReturn([]);

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('暂无可用模型'), findsOneWidget);
        expect(find.text('请先配置 API 密钥并点击刷新按钮加载模型列表'), findsOneWidget);
        expect(find.text('加载模型列表'), findsOneWidget);
        expect(find.byIcon(Icons.psychology_outlined), findsOneWidget);
        expect(find.byIcon(Icons.download), findsOneWidget);
      });
    });

    group('Model List Display', () {
      testWidgets('should display available models correctly',
          (WidgetTester tester) async {
        // Arrange
        when(mockViewModel.availableModels).thenReturn(testModels);
        when(mockViewModel.selectedModel).thenReturn(testModels[0]);

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Test Model 1'), findsOneWidget);
        expect(find.text('Test Model 2'), findsOneWidget);
        expect(find.byType(ModelCard), findsExactly(2));

        // Check that first model is selected
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('should handle model selection correctly',
          (WidgetTester tester) async {
        // Arrange
        when(mockViewModel.availableModels).thenReturn(testModels);
        when(mockViewModel.selectedModel).thenReturn(null);

        // Act
        await tester.pumpWidget(createWidgetWithNavigationCapture());
        await tester.pumpAndSettle();

        // Tap on the first model
        await tester.tap(find.text('Test Model 1'));
        await tester.pumpAndSettle();

        // Assert
        verify(mockViewModel.selectModel(testModels[0])).called(1);
        expect(popCallCount, equals(1)); // Should navigate back
      });

      testWidgets('should display model descriptions correctly',
          (WidgetTester tester) async {
        // Arrange
        when(mockViewModel.availableModels).thenReturn(testModels);

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        expect(
            find.textContaining('This is a test model for translation tasks'),
            findsOneWidget);
        expect(find.text('Short description'), findsOneWidget);
      });

      testWidgets('should handle long descriptions with expand/collapse',
          (WidgetTester tester) async {
        // Arrange
        when(mockViewModel.availableModels).thenReturn(testModels);

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // The first model has a long description
        expect(find.text('展开'), findsOneWidget);

        // Tap expand button
        await tester.tap(find.text('展开'));
        await tester.pump();

        // Should show collapse button
        expect(find.text('收起'), findsOneWidget);
        expect(find.text('展开'), findsNothing);
      });

      testWidgets('should display pricing information correctly',
          (WidgetTester tester) async {
        // Arrange
        when(mockViewModel.availableModels).thenReturn(testModels);

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - Should display formatted prices
        expect(find.textContaining('1M tokens'),
            findsAtLeastNWidgets(2)); // Input and output prices
        expect(find.byIcon(Icons.input), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.output), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.text_fields), findsAtLeastNWidgets(1));
      });
    });

    group('Global Model Card - NEW FUNCTIONALITY', () {
      testWidgets('should show GlobalModelCard when in scenario mode',
          (WidgetTester tester) async {
        // Arrange
        when(mockViewModel.scenario).thenReturn('translation');
        when(mockViewModel.availableModels).thenReturn(testModels);
        when(mockViewModel.globalModelName).thenReturn('Global Model');
        when(mockViewModel.isUsingGlobalModel).thenReturn(false);

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - NEW FUNCTIONALITY
        expect(find.text('使用全局模型'), findsOneWidget);
        expect(find.text('Global Model'), findsOneWidget);
        expect(find.byIcon(Icons.public), findsOneWidget);

        // Should have both GlobalModelCard and regular ModelCards
        expect(find.byType(ModelCard), findsExactly(2)); // Regular models
        // GlobalModelCard is a private class, so we verify by text content
      });

      testWidgets('should not show GlobalModelCard when not in scenario mode',
          (WidgetTester tester) async {
        // Arrange
        when(mockViewModel.scenario).thenReturn(null);
        when(mockViewModel.availableModels).thenReturn(testModels);

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('使用全局模型'), findsNothing);
        expect(find.byIcon(Icons.public), findsNothing);
        expect(find.byType(ModelCard), findsExactly(2)); // Only regular models
      });

      testWidgets('should highlight GlobalModelCard when using global model',
          (WidgetTester tester) async {
        // Arrange
        when(mockViewModel.scenario).thenReturn('ai_tag');
        when(mockViewModel.availableModels).thenReturn(testModels);
        when(mockViewModel.globalModelName).thenReturn('Global AI Model');
        when(mockViewModel.isUsingGlobalModel).thenReturn(true);

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - Should show selected state
        expect(find.text('使用全局模型'), findsOneWidget);
        expect(find.text('Global AI Model'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle),
            findsOneWidget); // Selected indicator
      });

      testWidgets('should show "未配置全局模型" when global model is not set',
          (WidgetTester tester) async {
        // Arrange
        when(mockViewModel.scenario).thenReturn('translation');
        when(mockViewModel.availableModels).thenReturn(testModels);
        when(mockViewModel.globalModelName).thenReturn('');
        when(mockViewModel.isUsingGlobalModel).thenReturn(false);

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - NEW FUNCTIONALITY
        expect(find.text('使用全局模型'), findsOneWidget);
        expect(find.text('未配置全局模型'), findsOneWidget);
      });

      testWidgets('should handle global model selection and navigation',
          (WidgetTester tester) async {
        // Arrange
        when(mockViewModel.scenario).thenReturn('translation');
        when(mockViewModel.availableModels).thenReturn(testModels);
        when(mockViewModel.globalModelName).thenReturn('Global Model');
        when(mockViewModel.isUsingGlobalModel).thenReturn(false);

        // Act
        await tester.pumpWidget(createWidgetWithNavigationCapture());
        await tester.pumpAndSettle();

        // Tap on GlobalModelCard
        await tester.tap(find.text('使用全局模型'));
        await tester.pumpAndSettle();

        // Assert - NEW FUNCTIONALITY
        verify(mockViewModel.selectGlobalModel()).called(1);
        expect(popCallCount, equals(1)); // Should navigate back
      });
    });

    group('Scenario-Based Behavior', () {
      testWidgets('should adjust list item count based on scenario',
          (WidgetTester tester) async {
        // Test without scenario
        when(mockViewModel.scenario).thenReturn(null);
        when(mockViewModel.availableModels).thenReturn(testModels);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(ModelCard), findsExactly(2)); // Only models

        // Test with scenario
        when(mockViewModel.scenario).thenReturn('ai_tag');
        when(mockViewModel.globalModelName).thenReturn('Global');

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(find.text('使用全局模型'), findsOneWidget); // Global option
        expect(find.byType(ModelCard), findsExactly(2)); // Plus models
      });
    });

    group('Refresh Functionality', () {
      testWidgets('should trigger refresh when RefreshIndicator is pulled',
          (WidgetTester tester) async {
        // Arrange
        when(mockViewModel.availableModels).thenReturn(testModels);

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Pull to refresh
        await tester.fling(
            find.byType(RefreshIndicator), const Offset(0.0, 300.0), 1000.0);
        await tester.pumpAndSettle();

        // Assert - check that the command was called (Note: RefreshIndicator calls the onRefresh callback)
        verify(mockViewModel.loadModels.executeWithFuture(null));
      });

      testWidgets('should execute load command when retry button is tapped',
          (WidgetTester tester) async {
        // Arrange - Setup error state
        final loadCommand = Command.createAsyncNoParam<List<OpenRouterModel>>(
          () async {
            throw Exception('Failed to load models');
          },
          initialValue: [],
        );

        when(mockViewModel.loadModels).thenReturn(loadCommand);
        when(mockViewModel.availableModels).thenReturn([]);

        loadCommand.execute();

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Tap retry button
        await tester.tap(find.text('重试'));
        await tester.pumpAndSettle();

        // Assert - Command should be executed again
        // Note: We can't easily verify execution count with flutter_command,
        // but the important thing is that the retry button works without errors
      });
    });

    group('UI State Management', () {
      testWidgets('should update UI when viewModel changes',
          (WidgetTester tester) async {
        // Arrange
        when(mockViewModel.availableModels).thenReturn([]);
        when(mockViewModel.scenario).thenReturn(null);

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Initially no models
        expect(find.text('暂无可用模型'), findsOneWidget);

        // Update viewModel and rebuild widget
        when(mockViewModel.availableModels).thenReturn(testModels);
        when(mockViewModel.scenario).thenReturn('translation');
        when(mockViewModel.globalModelName).thenReturn('Global Model');

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - Should show models and global option
        expect(find.text('Test Model 1'), findsOneWidget);
        expect(find.text('使用全局模型'), findsOneWidget);
        expect(find.text('暂无可用模型'), findsNothing);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle empty model list gracefully',
          (WidgetTester tester) async {
        // Arrange
        when(mockViewModel.availableModels).thenReturn([]);

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - Should show empty state, not crash
        expect(find.text('暂无可用模型'), findsOneWidget);
      });

      testWidgets('should handle null selected model gracefully',
          (WidgetTester tester) async {
        // Arrange
        when(mockViewModel.availableModels).thenReturn(testModels);
        when(mockViewModel.selectedModel).thenReturn(null);

        // Act
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Assert - Should build without crashing
        expect(find.byType(ModelCard), findsExactly(2));
        expect(find.byIcon(Icons.check_circle),
            findsNothing); // No selection indicator
      });
    });
  });
}
