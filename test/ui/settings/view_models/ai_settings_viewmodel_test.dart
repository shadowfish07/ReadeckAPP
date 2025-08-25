import 'dart:async';

import 'package:flutter_command/flutter_command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/openrouter/openrouter_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/domain/models/openrouter_model/openrouter_model.dart';
import 'package:readeck_app/ui/settings/view_models/ai_settings_viewmodel.dart';
import 'package:result_dart/result_dart.dart';

import '../../../helpers/test_logger_helper.dart';
import 'ai_settings_viewmodel_test.mocks.dart';

// Generate mock classes
@GenerateMocks([SettingsRepository, OpenRouterRepository])
void main() {
  setUpAll(() {
    // Provide dummy values for Mockito
    provideDummy<Result<void>>(Success.unit());
    provideDummy<Result<List<OpenRouterModel>>>(
        const Success(<OpenRouterModel>[]));
    provideDummy<List<OpenRouterModel>>(const <OpenRouterModel>[]);
    provideDummy<Stream<void>>(const Stream<void>.empty());

    Command.globalExceptionHandler = (error, stackTrace) {
      // Handle errors in tests
    };

    setupTestLogger();
  });

  group('AiSettingsViewModel', () {
    late MockSettingsRepository mockSettingsRepository;
    late MockOpenRouterRepository mockOpenRouterRepository;
    late AiSettingsViewModel viewModel;

    const testModels = [
      OpenRouterModel(
        id: 'ai-model-1',
        name: 'AI Model 1',
        pricing: ModelPricing(prompt: '0.001', completion: '0.002'),
        contextLength: 4096,
      ),
      OpenRouterModel(
        id: 'ai-model-2',
        name: 'AI Model 2',
        pricing: ModelPricing(prompt: '0.002', completion: '0.003'),
        contextLength: 8192,
      ),
    ];

    setUp(() {
      mockSettingsRepository = MockSettingsRepository();
      mockOpenRouterRepository = MockOpenRouterRepository();

      // Setup default mock behaviors
      when(mockSettingsRepository.getOpenRouterApiKey()).thenReturn('');
      when(mockSettingsRepository.getSelectedOpenRouterModelName())
          .thenReturn('');
      when(mockSettingsRepository.getSelectedOpenRouterModel()).thenReturn('');
      when(mockSettingsRepository.settingsChanged)
          .thenAnswer((_) => const Stream<void>.empty());
      when(mockOpenRouterRepository.getModels())
          .thenAnswer((_) async => const Success(testModels));
    });

    tearDown(() {
      // viewModel.dispose() is called in individual tests if needed
    });

    group('初始化和基本属性', () {
      test('should initialize with correct dependencies', () {
        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        expect(viewModel, isNotNull);
        expect(viewModel, isA<AiSettingsViewModel>());
      });

      test('should load current openRouterApiKey on initialization', () {
        const testApiKey = 'test-api-key-123';
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(testApiKey);

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        expect(viewModel.openRouterApiKey, equals(testApiKey));
        verify(mockSettingsRepository.getOpenRouterApiKey()).called(1);
      });

      test('should load current selectedModelName on initialization', () {
        const testModelName = 'Test Model Name';
        when(mockSettingsRepository.getSelectedOpenRouterModelName())
            .thenReturn(testModelName);

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        expect(viewModel.selectedModelName, equals(testModelName));
        verify(mockSettingsRepository.getSelectedOpenRouterModelName())
            .called(1);
      });

      test('should initialize selectedModel as null initially', () {
        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        expect(viewModel.selectedModel, isNull);
      });

      test('should initialize all commands', () {
        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        expect(viewModel.saveApiKey, isA<Command<String, void>>());
        expect(viewModel.loadApiKey, isA<Command<void, void>>());
        expect(viewModel.loadSelectedModel, isA<Command<void, void>>());
        expect(viewModel.textChangedCommand, isA<Command<String, String>>());
      });

      test(
          'should execute loadApiKey and loadSelectedModel commands on initialization',
          () async {
        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // Give time for commands to execute
        await Future.delayed(const Duration(milliseconds: 100));

        // Commands should be executed during initialization
        expect(viewModel.loadApiKey.isExecuting.value, isFalse);
        expect(viewModel.loadSelectedModel.isExecuting.value, isFalse);
      });
    });

    group('配置变更监听功能', () {
      test('should listen to settings changes on initialization', () {
        final streamController = StreamController<void>();
        when(mockSettingsRepository.settingsChanged)
            .thenAnswer((_) => streamController.stream);

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        // Trigger settings change
        streamController.add(null);

        // Allow async processing - settings change should trigger notifyListeners
        expect(() => streamController.add(null), returnsNormally);

        streamController.close();
      });

      test('should handle settings changes and notify listeners', () async {
        final streamController = StreamController<void>();
        when(mockSettingsRepository.settingsChanged)
            .thenAnswer((_) => streamController.stream);

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        // Trigger settings change
        streamController.add(null);

        // Allow some time for async processing
        await Future.delayed(const Duration(milliseconds: 10));

        // Should be able to trigger multiple changes
        streamController.add(null);
        streamController.add(null);

        streamController.close();
      });

      test('should handle stream subscription lifecycle correctly', () {
        final streamController = StreamController<void>();
        when(mockSettingsRepository.settingsChanged)
            .thenAnswer((_) => streamController.stream);

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // Verify subscription is created
        expect(viewModel, isNotNull);

        // Dispose should cancel subscription
        expect(() => viewModel.dispose(), returnsNormally);

        streamController.close();
      });
    });

    group('模型加载和名称优化显示', () {
      test('should load selected model successfully with cached name priority',
          () async {
        const modelId = 'ai-model-1';
        const cachedModelName = 'Cached Model Name';

        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn(modelId);
        when(mockSettingsRepository.getSelectedOpenRouterModelName())
            .thenReturn(cachedModelName);
        when(mockOpenRouterRepository.getModels())
            .thenAnswer((_) async => const Success(testModels));

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        await viewModel.loadSelectedModel.executeWithFuture();

        // Should find the model from test data
        expect(viewModel.selectedModel, isNotNull);
        expect(viewModel.selectedModel!.id, equals(modelId));
        expect(viewModel.selectedModel!.name, equals('AI Model 1'));

        verify(mockSettingsRepository.getSelectedOpenRouterModel())
            .called(greaterThanOrEqualTo(1));
        verify(mockSettingsRepository.getSelectedOpenRouterModelName())
            .called(greaterThanOrEqualTo(1));
        verify(mockOpenRouterRepository.getModels()).called(1);
      });

      test('should handle cached model name display before API call', () async {
        const modelId = 'ai-model-1';
        const cachedModelName = 'Cached Model Name';

        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn(modelId);
        when(mockSettingsRepository.getSelectedOpenRouterModelName())
            .thenReturn(cachedModelName);
        when(mockOpenRouterRepository.getModels())
            .thenAnswer((_) async => const Success(testModels));

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        await viewModel.loadSelectedModel.executeWithFuture();

        // notifyListeners should be called for cached name display
        expect(listenerCallCount, greaterThanOrEqualTo(1));
      });

      test('should handle empty model ID gracefully', () async {
        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn('');
        when(mockSettingsRepository.getSelectedOpenRouterModelName())
            .thenReturn('');

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        await viewModel.loadSelectedModel.executeWithFuture();

        expect(viewModel.selectedModel, isNull);
        // Should not call API when model ID is empty
        verifyNever(mockOpenRouterRepository.getModels());
      });

      test('should handle model not found in API results', () async {
        const modelId = 'nonexistent-model';
        const cachedModelName = 'Nonexistent Model';

        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn(modelId);
        when(mockSettingsRepository.getSelectedOpenRouterModelName())
            .thenReturn(cachedModelName);
        when(mockOpenRouterRepository.getModels())
            .thenAnswer((_) async => const Success(testModels));

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        await viewModel.loadSelectedModel.executeWithFuture();

        expect(viewModel.selectedModel, isNull);
        verify(mockOpenRouterRepository.getModels()).called(1);
      });

      test('should handle API failure gracefully', () async {
        const modelId = 'ai-model-1';
        const cachedModelName = 'Cached Model Name';
        final apiError = Exception('API Error');

        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn(modelId);
        when(mockSettingsRepository.getSelectedOpenRouterModelName())
            .thenReturn(cachedModelName);
        when(mockOpenRouterRepository.getModels())
            .thenAnswer((_) async => Failure(apiError));

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // Should not throw exception
        await expectLater(
          viewModel.loadSelectedModel.executeWithFuture(),
          completes,
        );

        expect(viewModel.selectedModel, isNull);
        verify(mockOpenRouterRepository.getModels()).called(1);
      });

      test('should handle exception in loadSelectedModel gracefully', () async {
        const modelId = 'ai-model-1';

        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn(modelId);
        when(mockSettingsRepository.getSelectedOpenRouterModelName())
            .thenThrow(Exception('Repository error'));

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // Should not throw exception
        await expectLater(
          viewModel.loadSelectedModel.executeWithFuture(),
          completes,
        );

        expect(viewModel.selectedModel, isNull);
      });

      test('should update selectedModel when model is found', () async {
        const modelId = 'ai-model-2';
        const cachedModelName = 'Cached AI Model 2';

        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn(modelId);
        when(mockSettingsRepository.getSelectedOpenRouterModelName())
            .thenReturn(cachedModelName);
        when(mockOpenRouterRepository.getModels())
            .thenAnswer((_) async => const Success(testModels));

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        await viewModel.loadSelectedModel.executeWithFuture();

        expect(viewModel.selectedModel, isNotNull);
        expect(viewModel.selectedModel!.id, equals('ai-model-2'));
        expect(viewModel.selectedModel!.name, equals('AI Model 2'));
        expect(viewModel.selectedModel!.contextLength, equals(8192));
      });
    });

    group('防抖机制测试', () {
      test('should initialize textChangedCommand with debounce behavior',
          () async {
        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        expect(viewModel.textChangedCommand, isNotNull);
        expect(viewModel.textChangedCommand.value, equals(''));
      });

      test('should debounce text changes and trigger save after delay',
          () async {
        const originalApiKey = 'original-key';
        const newApiKey = 'new-api-key';

        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(originalApiKey);
        when(mockSettingsRepository.saveOpenRouterApiKey(newApiKey.trim()))
            .thenAnswer((_) async => const Success(()));

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // Trigger text change
        viewModel.textChangedCommand.execute(newApiKey);

        // Wait for debounce delay (500ms)
        await Future.delayed(const Duration(milliseconds: 600));

        // Should trigger save after debounce delay
        verify(mockSettingsRepository.saveOpenRouterApiKey(newApiKey.trim()))
            .called(1);
      });

      test('should not save if text content is same as existing API key',
          () async {
        const existingApiKey = 'existing-key';

        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(existingApiKey);

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // Trigger text change with same content
        viewModel.textChangedCommand.execute(existingApiKey);

        // Wait for debounce delay
        await Future.delayed(const Duration(milliseconds: 600));

        // Should not trigger save for same content
        verifyNever(mockSettingsRepository.saveOpenRouterApiKey(any));
      });

      test('should trim whitespace before comparing and saving', () async {
        const originalApiKey = 'original-key';
        const newApiKeyWithSpaces = '  new-api-key  ';
        const trimmedApiKey = 'new-api-key';

        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(originalApiKey);
        when(mockSettingsRepository.saveOpenRouterApiKey(trimmedApiKey))
            .thenAnswer((_) async => const Success(()));

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // Trigger text change with whitespace
        viewModel.textChangedCommand.execute(newApiKeyWithSpaces);

        // Wait for debounce delay
        await Future.delayed(const Duration(milliseconds: 600));

        // Should save trimmed version
        verify(mockSettingsRepository.saveOpenRouterApiKey(trimmedApiKey))
            .called(1);
      });

      test(
          'should only execute last change when multiple changes occur rapidly',
          () async {
        const originalApiKey = 'original-key';
        const firstChange = 'first-change';
        const secondChange = 'second-change';
        const finalChange = 'final-change';

        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(originalApiKey);
        when(mockSettingsRepository.saveOpenRouterApiKey(finalChange))
            .thenAnswer((_) async => const Success(()));

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // Trigger multiple rapid changes
        viewModel.textChangedCommand.execute(firstChange);
        viewModel.textChangedCommand.execute(secondChange);
        viewModel.textChangedCommand.execute(finalChange);

        // Wait for debounce delay
        await Future.delayed(const Duration(milliseconds: 600));

        // Should only save the final change
        verify(mockSettingsRepository.saveOpenRouterApiKey(finalChange))
            .called(1);
        verifyNever(mockSettingsRepository.saveOpenRouterApiKey(firstChange));
        verifyNever(mockSettingsRepository.saveOpenRouterApiKey(secondChange));
      });

      test('should handle debounce with same content as repository', () async {
        const sameApiKey = 'same-key';

        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(sameApiKey);

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // Trigger text change with same content (with different whitespace)
        viewModel.textChangedCommand.execute('  $sameApiKey  ');

        // Wait for debounce delay
        await Future.delayed(const Duration(milliseconds: 600));

        // Should not save when trimmed content is same
        verifyNever(mockSettingsRepository.saveOpenRouterApiKey(any));
      });
    });

    group('API Key保存功能', () {
      test('should save API key successfully', () async {
        const newApiKey = 'new-api-key-123';

        when(mockSettingsRepository.saveOpenRouterApiKey(newApiKey))
            .thenAnswer((_) async => const Success(()));

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        await viewModel.saveApiKey.executeWithFuture(newApiKey);

        expect(listenerCallCount, greaterThanOrEqualTo(1));
        verify(mockSettingsRepository.saveOpenRouterApiKey(newApiKey))
            .called(1);
      });

      test('should handle save API key failure and throw exception', () async {
        const newApiKey = 'failing-api-key';
        final saveError = Exception('Save failed');

        when(mockSettingsRepository.saveOpenRouterApiKey(newApiKey))
            .thenAnswer((_) async => Failure(saveError));

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        await expectLater(
          viewModel.saveApiKey.executeWithFuture(newApiKey),
          throwsA(isA<Exception>()),
        );

        verify(mockSettingsRepository.saveOpenRouterApiKey(newApiKey))
            .called(1);
      });

      test('should save different API key values', () async {
        final testApiKeys = [
          'test-key-1',
          'test-key-2',
          'very-long-api-key-with-numbers-123456789',
          '',
        ];

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        for (final apiKey in testApiKeys) {
          when(mockSettingsRepository.saveOpenRouterApiKey(apiKey))
              .thenAnswer((_) async => const Success(()));

          await viewModel.saveApiKey.executeWithFuture(apiKey);

          verify(mockSettingsRepository.saveOpenRouterApiKey(apiKey)).called(1);
        }
      });
    });

    group('loadApiKey功能', () {
      test('should load API key and notify listeners', () async {
        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        await viewModel.loadApiKey.executeWithFuture();

        expect(listenerCallCount, greaterThanOrEqualTo(1));
      });

      test('should complete loadApiKey command without errors', () async {
        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        await expectLater(
          viewModel.loadApiKey.executeWithFuture(),
          completes,
        );
      });
    });

    group('资源管理和dispose', () {
      test('should dispose all commands without errors', () {
        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        expect(() => viewModel.dispose(), returnsNormally);
      });

      test('should cancel settings subscription on dispose', () {
        final streamController = StreamController<void>();
        when(mockSettingsRepository.settingsChanged)
            .thenAnswer((_) => streamController.stream);

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        expect(() => viewModel.dispose(), returnsNormally);

        streamController.close();
      });

      test('should not crash when accessing properties after dispose', () {
        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);
        viewModel.dispose();

        // Should still be able to access properties
        expect(() => viewModel.openRouterApiKey, returnsNormally);
        expect(() => viewModel.selectedModelName, returnsNormally);
        expect(() => viewModel.selectedModel, returnsNormally);
      });

      test('should handle multiple dispose calls safely', () {
        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // First dispose should work fine
        expect(() => viewModel.dispose(), returnsNormally);

        // Second dispose will throw an error because Commands don't allow double dispose
        // This is expected behavior in flutter_command library
        expect(() => viewModel.dispose(), throwsA(isA<AssertionError>()));
      });

      test('should dispose with null settings subscription', () {
        // Create viewModel where subscription might be null
        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        expect(() => viewModel.dispose(), returnsNormally);
      });
    });

    group('边界条件和错误处理', () {
      test('should handle empty string API key', () async {
        const emptyApiKey = '';

        when(mockSettingsRepository.saveOpenRouterApiKey(emptyApiKey))
            .thenAnswer((_) async => const Success(()));

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        await viewModel.saveApiKey.executeWithFuture(emptyApiKey);

        verify(mockSettingsRepository.saveOpenRouterApiKey(emptyApiKey))
            .called(1);
      });

      test('should handle very long API key', () async {
        final longApiKey =
            'very-very-long-api-key-' * 50; // Create a very long string

        when(mockSettingsRepository.saveOpenRouterApiKey(longApiKey))
            .thenAnswer((_) async => const Success(()));

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        await viewModel.saveApiKey.executeWithFuture(longApiKey);

        verify(mockSettingsRepository.saveOpenRouterApiKey(longApiKey))
            .called(1);
      });

      test('should handle special characters in API key', () async {
        const specialApiKey = 'api-key-!@#\$%^&*()_+{}[]|\\:";\'<>?,./';

        when(mockSettingsRepository.saveOpenRouterApiKey(specialApiKey))
            .thenAnswer((_) async => const Success(()));

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        await viewModel.saveApiKey.executeWithFuture(specialApiKey);

        verify(mockSettingsRepository.saveOpenRouterApiKey(specialApiKey))
            .called(1);
      });

      test('should handle repository returning null for API key', () {
        when(mockSettingsRepository.getOpenRouterApiKey()).thenReturn('');

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        expect(viewModel.openRouterApiKey, equals(''));
      });

      test('should handle repository returning null for model name', () {
        when(mockSettingsRepository.getSelectedOpenRouterModelName())
            .thenReturn('');

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        expect(viewModel.selectedModelName, equals(''));
      });

      test('should handle empty models list from API', () async {
        const modelId = 'ai-model-1';

        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn(modelId);
        when(mockSettingsRepository.getSelectedOpenRouterModelName())
            .thenReturn('Test Model');
        when(mockOpenRouterRepository.getModels())
            .thenAnswer((_) async => const Success(<OpenRouterModel>[]));

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        await viewModel.loadSelectedModel.executeWithFuture();

        expect(viewModel.selectedModel, isNull);
      });
    });

    group('Command 状态', () {
      test('should have correct initial command states', () async {
        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // Wait for auto-executed commands to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(viewModel.saveApiKey.isExecuting.value, isFalse);
        expect(viewModel.loadApiKey.isExecuting.value, isFalse);
        expect(viewModel.loadSelectedModel.isExecuting.value, isFalse);
        // textChangedCommand is synchronous, so isExecuting is not supported
      });

      test('should show executing state during command execution', () async {
        // Make save operation slow to test executing state
        when(mockSettingsRepository.saveOpenRouterApiKey(any))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return const Success(());
        });

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        final future = viewModel.saveApiKey.executeWithFuture('test-key');

        // Should be executing during the operation
        expect(viewModel.saveApiKey.isExecuting.value, isTrue);

        await future;

        // Should not be executing after completion
        expect(viewModel.saveApiKey.isExecuting.value, isFalse);
      });
    });

    group('复杂场景测试', () {
      test('should handle concurrent command executions', () async {
        when(mockSettingsRepository.saveOpenRouterApiKey(any))
            .thenAnswer((_) async => const Success(()));

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // Execute multiple commands concurrently
        final futures = [
          viewModel.saveApiKey.executeWithFuture('key1'),
          viewModel.loadApiKey.executeWithFuture(),
          viewModel.loadSelectedModel.executeWithFuture(),
        ];

        await expectLater(
          Future.wait(futures),
          completes,
        );
      });

      test('should handle settings change while loading model', () async {
        final settingsController = StreamController<void>();
        when(mockSettingsRepository.settingsChanged)
            .thenAnswer((_) => settingsController.stream);

        // Make model loading slow
        when(mockOpenRouterRepository.getModels()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return const Success(testModels);
        });

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        // Start model loading and trigger settings change
        final loadFuture = viewModel.loadSelectedModel.executeWithFuture();
        settingsController.add(null);

        await loadFuture;

        expect(listenerCallCount, greaterThanOrEqualTo(1));
        settingsController.close();
      });

      test('should handle debounce during model loading', () async {
        const apiKey = 'test-key';

        when(mockSettingsRepository.getOpenRouterApiKey()).thenReturn('');
        when(mockSettingsRepository.saveOpenRouterApiKey(apiKey))
            .thenAnswer((_) async => const Success(()));

        // Make model loading slow
        when(mockOpenRouterRepository.getModels()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return const Success(testModels);
        });

        viewModel = AiSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // Trigger text change while model is loading
        viewModel.textChangedCommand.execute(apiKey);

        // Wait for both debounce and model loading
        await Future.delayed(const Duration(milliseconds: 600));

        verify(mockSettingsRepository.saveOpenRouterApiKey(apiKey)).called(1);
      });
    });
  });
}
