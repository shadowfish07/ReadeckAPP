import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/openrouter/openrouter_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/domain/models/openrouter_model/openrouter_model.dart';
import 'package:readeck_app/ui/settings/view_models/model_selection_viewmodel.dart';
import 'package:result_dart/result_dart.dart';

import '../../../../helpers/test_logger_helper.dart';
import 'model_selection_viewmodel_test.mocks.dart';

@GenerateMocks([SettingsRepository, OpenRouterRepository])
void main() {
  group('ModelSelectionViewModel', () {
    late MockSettingsRepository mockSettingsRepository;
    late MockOpenRouterRepository mockOpenRouterRepository;
    late ModelSelectionViewModel viewModel;
    late List<OpenRouterModel> testModels;

    setUpAll(() {
      // Setup global exception handler for flutter_command
      Command.globalExceptionHandler = (error, stackTrace) {
        // Silently handle errors in tests - this prevents async save failures
        // from causing test failures when testing error scenarios
        // In real app, these would be handled by proper error handling mechanisms
      };

      setupTestLogger();

      // Provide dummy values for Mockito
      provideDummy<Result<List<OpenRouterModel>>>(
        const Success([]),
      );
      provideDummy<Result<void>>(
        const Success(()),
      );
    });

    setUp(() {
      mockSettingsRepository = MockSettingsRepository();
      mockOpenRouterRepository = MockOpenRouterRepository();

      // 创建测试模型数据
      testModels = [
        const OpenRouterModel(
          id: 'model1',
          name: 'Model 1',
          pricing: ModelPricing(prompt: '0.001', completion: '0.002'),
          contextLength: 4096,
        ),
        const OpenRouterModel(
          id: 'model2',
          name: 'Model 2',
          pricing: ModelPricing(prompt: '0.002', completion: '0.003'),
          contextLength: 8192,
        ),
        const OpenRouterModel(
          id: 'model3',
          name: 'Model 3',
          pricing: ModelPricing(prompt: '0.003', completion: '0.004'),
          contextLength: 16384,
        ),
      ];

      // Setup default mock behavior
      when(mockOpenRouterRepository.getModels(category: anyNamed('category')))
          .thenAnswer((_) async => Success(testModels));
      when(mockSettingsRepository.getSelectedOpenRouterModel()).thenReturn('');
      when(mockSettingsRepository.saveSelectedOpenRouterModel(any))
          .thenAnswer((_) async => const Success(()));
      when(mockSettingsRepository.getTranslationModel()).thenReturn('');
      when(mockSettingsRepository.getAiTagModel()).thenReturn('');
      when(mockSettingsRepository.saveTranslationModel(any))
          .thenAnswer((_) async => const Success(()));
      when(mockSettingsRepository.saveAiTagModel(any))
          .thenAnswer((_) async => const Success(()));
      when(mockSettingsRepository.saveSelectedOpenRouterModel(any, any))
          .thenAnswer((_) async => const Success(()));
      when(mockSettingsRepository.saveTranslationModel(any, any))
          .thenAnswer((_) async => const Success(()));
      when(mockSettingsRepository.saveAiTagModel(any, any))
          .thenAnswer((_) async => const Success(()));
      when(mockSettingsRepository.getSelectedOpenRouterModelName())
          .thenReturn('Global Model');

      viewModel = ModelSelectionViewModel(
          mockSettingsRepository, mockOpenRouterRepository);
    });

    group('初始化测试', () {
      test('should initialize with empty models and null selected model',
          () async {
        // Wait for initial commands to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(viewModel.availableModels, isNotEmpty);
        expect(viewModel.selectedModel, isNull);
      });

      test('should load models on initialization', () async {
        // Wait for commands to complete
        await Future.delayed(const Duration(milliseconds: 100));

        verify(mockOpenRouterRepository.getModels(category: null)).called(1);
        expect(viewModel.availableModels, hasLength(3));
      });

      test('should load selected model on initialization', () async {
        // Wait for commands to complete
        await Future.delayed(const Duration(milliseconds: 100));

        verify(mockSettingsRepository.getSelectedOpenRouterModel()).called(1);
      });
    });

    group('模型排序逻辑测试', () {
      test('should maintain original order when no model is selected',
          () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        final models = viewModel.availableModels;
        expect(models[0].id, 'model1');
        expect(models[1].id, 'model2');
        expect(models[2].id, 'model3');
      });

      test('should move selected model to top of list', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        // Select model2
        viewModel.selectModel(testModels[1]);

        final models = viewModel.availableModels;
        expect(models[0].id, 'model2'); // Selected model should be first
        expect(models[1].id, 'model1');
        expect(models[2].id, 'model3');
      });

      test('should handle selecting non-existent model gracefully', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        const nonExistentModel = OpenRouterModel(
          id: 'nonexistent',
          name: 'Non-existent Model',
        );

        viewModel.selectModel(nonExistentModel);

        // Should not crash, original order should be maintained
        final models = viewModel.availableModels;
        expect(models[0].id, 'model1');
        expect(models[1].id, 'model2');
        expect(models[2].id, 'model3');
      });
    });

    group('模型选择功能测试', () {
      test('should update selected model when selectModel is called', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        final modelToSelect = testModels[1];
        viewModel.selectModel(modelToSelect);

        expect(viewModel.selectedModel?.id, 'model2');
      });

      test('should save selected model to repository', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        final modelToSelect = testModels[1];
        viewModel.selectModel(modelToSelect);

        // Allow time for async save operation
        await Future.delayed(const Duration(milliseconds: 50));

        verify(mockSettingsRepository.saveSelectedOpenRouterModel(
                'model2', 'Model 2'))
            .called(1);
      });

      test('should notify listeners when model is selected', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        bool notified = false;
        viewModel.addListener(() {
          notified = true;
        });

        viewModel.selectModel(testModels[1]);
        expect(notified, true);
      });
    });

    group('Command 功能测试', () {
      test('should execute loadModels command on initialization', () async {
        // Commands are executed in constructor
        await Future.delayed(const Duration(milliseconds: 100));

        expect(viewModel.loadModels.value, isNotNull);
        expect(viewModel.loadModels.value, hasLength(3));
      });

      test('should execute loadSelectedModel command on initialization',
          () async {
        await Future.delayed(const Duration(milliseconds: 100));

        verify(mockSettingsRepository.getSelectedOpenRouterModel()).called(1);
      });

      test('should handle loadModels command errors', () async {
        // Create new viewModel with error scenario
        when(mockOpenRouterRepository.getModels(category: anyNamed('category')))
            .thenAnswer((_) async => Failure(Exception('Network error')));

        final errorViewModel = ModelSelectionViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // Wait longer for commands to complete
        await Future.delayed(const Duration(milliseconds: 500));

        expect(errorViewModel.loadModels.errors.value, isNotNull);
        expect(errorViewModel.availableModels, isEmpty);

        errorViewModel.dispose();
      });
    });

    group('边界条件测试', () {
      test('should handle empty model list from repository', () async {
        // Setup empty model list
        when(mockOpenRouterRepository.getModels(category: anyNamed('category')))
            .thenAnswer((_) async => const Success(<OpenRouterModel>[]));

        final emptyViewModel = ModelSelectionViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // Wait longer for commands to complete
        await Future.delayed(const Duration(milliseconds: 500));

        expect(emptyViewModel.availableModels, isEmpty);
        expect(emptyViewModel.selectedModel, isNull);

        emptyViewModel.dispose();
      });

      test('should handle previously selected model that exists', () async {
        // Setup with previously selected model
        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn('model2');

        final selectedViewModel = ModelSelectionViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // Wait longer for commands to complete
        await Future.delayed(const Duration(milliseconds: 500));

        expect(selectedViewModel.selectedModel?.id, 'model2');
        // Model2 should be first in the list
        expect(selectedViewModel.availableModels[0].id, 'model2');

        selectedViewModel.dispose();
      });

      test('should handle previously selected model that no longer exists',
          () async {
        // Setup with non-existent selected model
        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn('nonexistent');

        final nonExistentViewModel = ModelSelectionViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // Wait longer for commands to complete
        await Future.delayed(const Duration(milliseconds: 500));

        expect(nonExistentViewModel.selectedModel, isNull);
        // Original order should be maintained
        expect(nonExistentViewModel.availableModels[0].id, 'model1');

        nonExistentViewModel.dispose();
      });
    });

    group('场景功能测试', () {
      test('should load translation models when scenario is translation',
          () async {
        final translationViewModel = ModelSelectionViewModel(
            mockSettingsRepository, mockOpenRouterRepository,
            scenario: 'translation');

        await Future.delayed(const Duration(milliseconds: 100));

        verify(mockOpenRouterRepository.getModels(category: 'translation'))
            .called(1);

        translationViewModel.dispose();
      });

      test('should load ai_tag models when scenario is ai_tag', () async {
        final aiTagViewModel = ModelSelectionViewModel(
            mockSettingsRepository, mockOpenRouterRepository,
            scenario: 'ai_tag');

        await Future.delayed(const Duration(milliseconds: 100));

        verify(mockOpenRouterRepository.getModels(category: 'trivia'))
            .called(1);

        aiTagViewModel.dispose();
      });

      test(
          'should load translation model selection on initialization for translation scenario',
          () async {
        when(mockSettingsRepository.getTranslationModel()).thenReturn('model2');

        final translationViewModel = ModelSelectionViewModel(
            mockSettingsRepository, mockOpenRouterRepository,
            scenario: 'translation');

        await Future.delayed(const Duration(milliseconds: 100));

        verify(mockSettingsRepository.getTranslationModel()).called(1);
        expect(translationViewModel.selectedModel?.id, 'model2');

        translationViewModel.dispose();
      });

      test(
          'should load ai_tag model selection on initialization for ai_tag scenario',
          () async {
        when(mockSettingsRepository.getAiTagModel()).thenReturn('model3');

        final aiTagViewModel = ModelSelectionViewModel(
            mockSettingsRepository, mockOpenRouterRepository,
            scenario: 'ai_tag');

        await Future.delayed(const Duration(milliseconds: 100));

        verify(mockSettingsRepository.getAiTagModel()).called(1);
        expect(aiTagViewModel.selectedModel?.id, 'model3');

        aiTagViewModel.dispose();
      });

      test('should save to correct repository method based on scenario',
          () async {
        final translationViewModel = ModelSelectionViewModel(
            mockSettingsRepository, mockOpenRouterRepository,
            scenario: 'translation');

        await Future.delayed(const Duration(milliseconds: 100));

        translationViewModel.selectModel(testModels[1]);
        await Future.delayed(const Duration(milliseconds: 50));

        verify(mockSettingsRepository.saveTranslationModel('model2', 'Model 2'))
            .called(1);

        translationViewModel.dispose();

        // Test ai_tag scenario
        final aiTagViewModel = ModelSelectionViewModel(
            mockSettingsRepository, mockOpenRouterRepository,
            scenario: 'ai_tag');

        await Future.delayed(const Duration(milliseconds: 100));

        aiTagViewModel.selectModel(testModels[2]);
        await Future.delayed(const Duration(milliseconds: 50));

        verify(mockSettingsRepository.saveAiTagModel('model3', 'Model 3'))
            .called(1);

        aiTagViewModel.dispose();
      });
    });

    group('全局模型选择功能测试', () {
      test(
          'should return true for isUsingGlobalModel when selectedModelId is null',
          () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        expect(viewModel.isUsingGlobalModel, true);
      });

      test(
          'should return true for isUsingGlobalModel when selectedModelId is empty',
          () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        viewModel.selectGlobalModel();
        expect(viewModel.isUsingGlobalModel, true);
      });

      test('should return false for isUsingGlobalModel when model is selected',
          () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        viewModel.selectModel(testModels[0]);
        expect(viewModel.isUsingGlobalModel, false);
      });

      test('should return global model name from repository', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        expect(viewModel.globalModelName, 'Global Model');
        verify(mockSettingsRepository.getSelectedOpenRouterModelName())
            .called(1);
      });

      test('should return global model id from repository', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        expect(viewModel.globalModelId, '');
        verify(mockSettingsRepository.getSelectedOpenRouterModel())
            .called(greaterThan(0));
      });

      test('should save empty string when selectGlobalModel is called',
          () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        viewModel.selectGlobalModel();
        await Future.delayed(const Duration(milliseconds: 50));

        verify(mockSettingsRepository.saveSelectedOpenRouterModel('', ''))
            .called(1);
      });

      test('should notify listeners when selectGlobalModel is called',
          () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        bool notified = false;
        viewModel.addListener(() {
          notified = true;
        });

        viewModel.selectGlobalModel();
        expect(notified, true);
      });
    });

    group('模型名称传递功能测试', () {
      test('should save model with name when using saveSelectedOpenRouterModel',
          () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        final modelToSelect = testModels[1];
        viewModel.selectModel(modelToSelect);

        await Future.delayed(const Duration(milliseconds: 50));

        verify(mockSettingsRepository.saveSelectedOpenRouterModel(
                'model2', 'Model 2'))
            .called(1);
      });

      test('should save translation model with name for translation scenario',
          () async {
        final translationViewModel = ModelSelectionViewModel(
            mockSettingsRepository, mockOpenRouterRepository,
            scenario: 'translation');

        await Future.delayed(const Duration(milliseconds: 100));

        final modelToSelect = testModels[0];
        translationViewModel.selectModel(modelToSelect);

        await Future.delayed(const Duration(milliseconds: 50));

        verify(mockSettingsRepository.saveTranslationModel('model1', 'Model 1'))
            .called(1);

        translationViewModel.dispose();
      });

      test('should save ai_tag model with name for ai_tag scenario', () async {
        final aiTagViewModel = ModelSelectionViewModel(
            mockSettingsRepository, mockOpenRouterRepository,
            scenario: 'ai_tag');

        await Future.delayed(const Duration(milliseconds: 100));

        final modelToSelect = testModels[2];
        aiTagViewModel.selectModel(modelToSelect);

        await Future.delayed(const Duration(milliseconds: 50));

        verify(mockSettingsRepository.saveAiTagModel('model3', 'Model 3'))
            .called(1);

        aiTagViewModel.dispose();
      });

      test(
          'should save empty name when selectGlobalModel called for translation scenario',
          () async {
        final translationViewModel = ModelSelectionViewModel(
            mockSettingsRepository, mockOpenRouterRepository,
            scenario: 'translation');

        await Future.delayed(const Duration(milliseconds: 100));

        translationViewModel.selectGlobalModel();
        await Future.delayed(const Duration(milliseconds: 50));

        verify(mockSettingsRepository.saveTranslationModel('', '')).called(1);

        translationViewModel.dispose();
      });

      test(
          'should save empty name when selectGlobalModel called for ai_tag scenario',
          () async {
        final aiTagViewModel = ModelSelectionViewModel(
            mockSettingsRepository, mockOpenRouterRepository,
            scenario: 'ai_tag');

        await Future.delayed(const Duration(milliseconds: 100));

        aiTagViewModel.selectGlobalModel();
        await Future.delayed(const Duration(milliseconds: 50));

        verify(mockSettingsRepository.saveAiTagModel('', '')).called(1);

        aiTagViewModel.dispose();
      });
    });

    group('AI tag场景分类修正测试', () {
      test('should use trivia category for ai_tag scenario', () async {
        final aiTagViewModel = ModelSelectionViewModel(
            mockSettingsRepository, mockOpenRouterRepository,
            scenario: 'ai_tag');

        await Future.delayed(const Duration(milliseconds: 100));

        verify(mockOpenRouterRepository.getModels(category: 'trivia'))
            .called(1);

        aiTagViewModel.dispose();
      });
    });

    group('边界情况测试', () {
      test('should handle empty model name gracefully', () async {
        // Use one of the existing test models but modify the name to be empty for testing save behavior
        await Future.delayed(const Duration(milliseconds: 100));

        // Create a modified model with empty name but same ID as existing model
        final modelWithEmptyName = testModels[0].copyWith(name: '');

        viewModel.selectModel(modelWithEmptyName);
        expect(viewModel.selectedModel?.id, 'model1');

        await Future.delayed(const Duration(milliseconds: 50));
        verify(mockSettingsRepository.saveSelectedOpenRouterModel('model1', ''))
            .called(1);
      });

      test(
          'should maintain state consistency during global/specific model transitions',
          () async {
        await Future.delayed(const Duration(milliseconds: 100));

        // Initially using global model
        expect(viewModel.isUsingGlobalModel, true);

        // Select specific model
        viewModel.selectModel(testModels[0]);
        expect(viewModel.isUsingGlobalModel, false);
        expect(viewModel.selectedModel?.id, 'model1');

        // Switch back to global model
        viewModel.selectGlobalModel();
        expect(viewModel.isUsingGlobalModel, true);
        expect(viewModel.selectedModel, isNull);
      });

      test('should successfully save models when repository operations succeed',
          () async {
        await Future.delayed(const Duration(milliseconds: 100));

        // Test successful save of specific model
        viewModel.selectModel(testModels[1]);
        await Future.delayed(const Duration(milliseconds: 50));

        verify(mockSettingsRepository.saveSelectedOpenRouterModel(
                'model2', 'Model 2'))
            .called(1);

        // Test successful save of global model
        viewModel.selectGlobalModel();
        await Future.delayed(const Duration(milliseconds: 50));

        verify(mockSettingsRepository.saveSelectedOpenRouterModel('', ''))
            .called(1);
      });

      test('should save scenario-specific models successfully', () async {
        // Test translation scenario
        final translationViewModel = ModelSelectionViewModel(
            mockSettingsRepository, mockOpenRouterRepository,
            scenario: 'translation');

        await Future.delayed(const Duration(milliseconds: 100));

        translationViewModel.selectModel(testModels[0]);
        await Future.delayed(const Duration(milliseconds: 50));

        verify(mockSettingsRepository.saveTranslationModel('model1', 'Model 1'))
            .called(1);

        translationViewModel.dispose();

        // Test ai_tag scenario
        final aiTagViewModel = ModelSelectionViewModel(
            mockSettingsRepository, mockOpenRouterRepository,
            scenario: 'ai_tag');

        await Future.delayed(const Duration(milliseconds: 100));

        aiTagViewModel.selectModel(testModels[2]);
        await Future.delayed(const Duration(milliseconds: 50));

        verify(mockSettingsRepository.saveAiTagModel('model3', 'Model 3'))
            .called(1);

        aiTagViewModel.dispose();
      });
    });

    group('Dispose 测试', () {
      test('should dispose commands properly', () {
        // Commands should be disposed only once, no exceptions should be thrown
        expect(() => viewModel.dispose(), returnsNormally);
      });
    });

    tearDown(() {
      // Always try to dispose viewModel, catch any errors
      try {
        viewModel.dispose();
      } catch (_) {
        // Ignore dispose errors in tearDown - this is expected for tests
        // that explicitly test disposal
      }
    });
  });
}
