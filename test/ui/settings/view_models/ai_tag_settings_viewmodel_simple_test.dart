import 'package:flutter_command/flutter_command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/openrouter/openrouter_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/domain/models/openrouter_model/openrouter_model.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/ui/settings/view_models/ai_tag_settings_viewmodel.dart';
import 'package:result_dart/result_dart.dart';

import 'ai_tag_settings_viewmodel_simple_test.mocks.dart';

// Generate mock classes
@GenerateMocks([SettingsRepository, OpenRouterRepository])
void main() {
  setUpAll(() {
    // Provide dummy values for Mockito
    provideDummy<Result<void>>(Success.unit());
    provideDummy<Result<List<OpenRouterModel>>>(
        const Success(<OpenRouterModel>[]));
    provideDummy<List<OpenRouterModel>>(const <OpenRouterModel>[]);

    Command.globalExceptionHandler = (error, stackTrace) {
      // Handle errors in tests
    };

    // Initialize appLogger for tests
    appLogger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        dateTimeFormat: DateTimeFormat.none,
      ),
      level: Level.warning, // Reduce log noise in tests
    );
  });

  group('AiTagSettingsViewModel', () {
    late MockSettingsRepository mockSettingsRepository;
    late MockOpenRouterRepository mockOpenRouterRepository;
    late AiTagSettingsViewModel viewModel;

    setUp(() {
      mockSettingsRepository = MockSettingsRepository();
      mockOpenRouterRepository = MockOpenRouterRepository();

      // Setup default mock behaviors
      when(mockSettingsRepository.getAiTagModel()).thenReturn('');
      when(mockOpenRouterRepository.getModels(category: anyNamed('category')))
          .thenAnswer((_) async => const Success(<OpenRouterModel>[]));
    });

    tearDown(() {
      // viewModel.dispose() is called in individual tests if needed
    });

    group('初始化', () {
      test('should load current AI tag target language on initialization', () {
        // 设置mock行为
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');

        viewModel = AiTagSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        expect(viewModel.aiTagTargetLanguage, equals('中文'));
        verify(mockSettingsRepository.getAiTagTargetLanguage()).called(1);
      });

      test('should load different language when repository returns it', () {
        when(mockSettingsRepository.getAiTagTargetLanguage())
            .thenReturn('English');

        viewModel = AiTagSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        expect(viewModel.aiTagTargetLanguage, equals('English'));
        verify(mockSettingsRepository.getAiTagTargetLanguage()).called(1);
      });

      test('should initialize saveAiTagTargetLanguage command', () {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');

        viewModel = AiTagSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        expect(viewModel.saveAiTagTargetLanguage, isA<Command<String, void>>());
        expect(viewModel.saveAiTagTargetLanguage, isNotNull);
      });
    });

    group('支持的语言列表', () {
      test('should contain expected languages', () {
        const expectedLanguages = [
          '中文',
          'English',
          '日本語',
          'Français',
          'Deutsch',
          'Español',
          'Русский',
          '한국어',
        ];

        expect(AiTagSettingsViewModel.supportedLanguages,
            equals(expectedLanguages));
        expect(AiTagSettingsViewModel.supportedLanguages.length, equals(8));
      });

      test('should include Chinese as first option', () {
        expect(AiTagSettingsViewModel.supportedLanguages.first, equals('中文'));
      });

      test('should include English as second option', () {
        expect(AiTagSettingsViewModel.supportedLanguages[1], equals('English'));
      });
    });

    group('保存AI标签目标语言', () {
      test('should save language successfully and update local state',
          () async {
        const newLanguage = 'English';

        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.saveAiTagTargetLanguage(newLanguage))
            .thenAnswer((_) async => const Success(()));

        viewModel = AiTagSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        await viewModel.saveAiTagTargetLanguage.executeWithFuture(newLanguage);

        expect(viewModel.aiTagTargetLanguage, equals(newLanguage));
        expect(listenerCallCount,
            greaterThanOrEqualTo(1)); // Should notify listeners at least once
        verify(mockSettingsRepository.saveAiTagTargetLanguage(newLanguage))
            .called(1);
      });

      test('should handle save failure and throw exception', () async {
        const newLanguage = 'Français';
        final exception = Exception('Save failed');

        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.saveAiTagTargetLanguage(newLanguage))
            .thenAnswer((_) async => Failure(exception));

        viewModel = AiTagSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        await expectLater(
          viewModel.saveAiTagTargetLanguage.executeWithFuture(newLanguage),
          throwsA(isA<Exception>()),
        );

        // State should not change when save fails
        expect(viewModel.aiTagTargetLanguage, equals('中文'));
        // Even on failure, commands may notify listeners during execution
        verify(mockSettingsRepository.saveAiTagTargetLanguage(newLanguage))
            .called(1);
      });

      test('should save different supported languages', () async {
        const testLanguages = ['English', '日本語', 'Français', 'Deutsch'];

        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');

        viewModel = AiTagSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        for (final language in testLanguages) {
          when(mockSettingsRepository.saveAiTagTargetLanguage(language))
              .thenAnswer((_) async => const Success(()));

          await viewModel.saveAiTagTargetLanguage.executeWithFuture(language);

          expect(viewModel.aiTagTargetLanguage, equals(language));
          verify(mockSettingsRepository.saveAiTagTargetLanguage(language))
              .called(1);
        }
      });
    });

    group('Command 状态', () {
      test('should have correct initial command state', () {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');

        viewModel = AiTagSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        expect(viewModel.saveAiTagTargetLanguage.isExecuting.value, isFalse);
      });
    });

    group('内存管理', () {
      test('should dispose without errors', () {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');

        viewModel = AiTagSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        expect(() => viewModel.dispose(), returnsNormally);
      });

      test('should not crash when accessing properties after dispose', () {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');

        viewModel = AiTagSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);
        viewModel.dispose();

        // Should still be able to access properties
        expect(() => viewModel.aiTagTargetLanguage, returnsNormally);
        expect(() => viewModel.saveAiTagTargetLanguage, returnsNormally);
      });
    });

    group('模型选择功能', () {
      const testModels = [
        OpenRouterModel(
          id: 'ai-tag-model-1',
          name: 'AI Tag Model 1',
          pricing: ModelPricing(prompt: '0.001', completion: '0.002'),
          contextLength: 4096,
        ),
        OpenRouterModel(
          id: 'ai-tag-model-2',
          name: 'AI Tag Model 2',
          pricing: ModelPricing(prompt: '0.002', completion: '0.003'),
          contextLength: 8192,
        ),
      ];

      test('should initialize model selection commands', () {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');

        viewModel = AiTagSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        expect(viewModel.saveAiTagModel, isA<Command<String, void>>());
        expect(
            viewModel.loadModels, isA<Command<void, List<OpenRouterModel>>>());
      });

      test('should load models with ai_tag category', () async {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockOpenRouterRepository.getModels(category: 'ai_tag'))
            .thenAnswer((_) async => const Success(testModels));

        viewModel = AiTagSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        await viewModel.loadModels.executeWithFuture();

        verify(mockOpenRouterRepository.getModels(category: 'ai_tag'))
            .called(1);
      });

      test('should save ai tag model successfully', () async {
        const modelId = 'ai-tag-model-1';

        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.saveAiTagModel(modelId))
            .thenAnswer((_) async => const Success(()));

        viewModel = AiTagSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        await viewModel.saveAiTagModel.executeWithFuture(modelId);

        verify(mockSettingsRepository.saveAiTagModel(modelId)).called(1);
      });

      test('should return selected ai tag model from loaded models', () async {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.getAiTagModel())
            .thenReturn('ai-tag-model-2');
        when(mockOpenRouterRepository.getModels(category: 'ai_tag'))
            .thenAnswer((_) async => const Success(testModels));

        viewModel = AiTagSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // Load models first
        await viewModel.loadModels.executeWithFuture();

        expect(viewModel.selectedAiTagModel?.id, equals('ai-tag-model-2'));
        expect(viewModel.selectedAiTagModel?.name, equals('AI Tag Model 2'));
      });

      test('should return null when no model is selected', () async {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.getAiTagModel()).thenReturn('');
        when(mockOpenRouterRepository.getModels(category: 'ai_tag'))
            .thenAnswer((_) async => const Success(testModels));

        viewModel = AiTagSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        // Load models first
        await viewModel.loadModels.executeWithFuture();

        expect(viewModel.selectedAiTagModel, isNull);
      });

      test('should handle model loading failure', () async {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockOpenRouterRepository.getModels(category: 'ai_tag'))
            .thenAnswer((_) async => Failure(Exception('Network error')));

        viewModel = AiTagSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        await expectLater(
          viewModel.loadModels.executeWithFuture(),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle model save failure', () async {
        const modelId = 'ai-tag-model-1';
        final exception = Exception('Save failed');

        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.saveAiTagModel(modelId))
            .thenAnswer((_) async => Failure(exception));

        viewModel = AiTagSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        await expectLater(
          viewModel.saveAiTagModel.executeWithFuture(modelId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('边界条件', () {
      test('should handle empty string language', () async {
        const emptyLanguage = '';

        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.saveAiTagTargetLanguage(emptyLanguage))
            .thenAnswer((_) async => const Success(()));

        viewModel = AiTagSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        await viewModel.saveAiTagTargetLanguage
            .executeWithFuture(emptyLanguage);

        expect(viewModel.aiTagTargetLanguage, equals(emptyLanguage));
        verify(mockSettingsRepository.saveAiTagTargetLanguage(emptyLanguage))
            .called(1);
      });

      test('should handle very long language string', () async {
        const longLanguage = 'VeryLongLanguageNameThatExceedsNormalLength';

        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.saveAiTagTargetLanguage(longLanguage))
            .thenAnswer((_) async => const Success(()));

        viewModel = AiTagSettingsViewModel(
            mockSettingsRepository, mockOpenRouterRepository);

        await viewModel.saveAiTagTargetLanguage.executeWithFuture(longLanguage);

        expect(viewModel.aiTagTargetLanguage, equals(longLanguage));
        verify(mockSettingsRepository.saveAiTagTargetLanguage(longLanguage))
            .called(1);
      });
    });
  });
}
