import 'package:flutter_command/flutter_command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/article/article_repository.dart';
import 'package:readeck_app/data/repository/openrouter/openrouter_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/domain/models/openrouter_model/openrouter_model.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/ui/settings/view_models/translation_settings_viewmodel.dart';
import 'package:result_dart/result_dart.dart';

import 'translation_settings_viewmodel_test.mocks.dart';

// Generate mock classes
@GenerateMocks([SettingsRepository, ArticleRepository, OpenRouterRepository])
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

  group('TranslationSettingsViewModel', () {
    late MockSettingsRepository mockSettingsRepository;
    late MockArticleRepository mockArticleRepository;
    late MockOpenRouterRepository mockOpenRouterRepository;
    late TranslationSettingsViewModel viewModel;

    const testModels = [
      OpenRouterModel(
        id: 'translation-model-1',
        name: 'Translation Model 1',
        pricing: ModelPricing(prompt: '0.001', completion: '0.002'),
        contextLength: 4096,
      ),
      OpenRouterModel(
        id: 'translation-model-2',
        name: 'Translation Model 2',
        pricing: ModelPricing(prompt: '0.002', completion: '0.003'),
        contextLength: 8192,
      ),
    ];

    setUp(() {
      mockSettingsRepository = MockSettingsRepository();
      mockArticleRepository = MockArticleRepository();
      mockOpenRouterRepository = MockOpenRouterRepository();

      // Setup default mock behaviors
      when(mockSettingsRepository.getTranslationProvider()).thenReturn('AI');
      when(mockSettingsRepository.getTranslationTargetLanguage())
          .thenReturn('中文');
      when(mockSettingsRepository.getTranslationCacheEnabled())
          .thenReturn(true);
      when(mockSettingsRepository.getTranslationModel()).thenReturn('');
      when(mockOpenRouterRepository.getModels(category: anyNamed('category')))
          .thenAnswer((_) async => const Success(testModels));
      when(mockArticleRepository.clearTranslationCache())
          .thenAnswer((_) async => const Success(()));
    });

    tearDown(() {
      // viewModel.dispose() is called in individual tests if needed
    });

    group('初始化', () {
      test('should load current translation settings on initialization', () {
        // 设置mock行为
        when(mockSettingsRepository.getTranslationProvider()).thenReturn('AI');
        when(mockSettingsRepository.getTranslationTargetLanguage())
            .thenReturn('English');
        when(mockSettingsRepository.getTranslationCacheEnabled())
            .thenReturn(false);

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        expect(viewModel.translationProvider, equals('AI'));
        expect(viewModel.translationTargetLanguage, equals('English'));
        expect(viewModel.translationCacheEnabled, equals(false));
        verify(mockSettingsRepository.getTranslationProvider()).called(1);
        verify(mockSettingsRepository.getTranslationTargetLanguage()).called(1);
        verify(mockSettingsRepository.getTranslationCacheEnabled()).called(1);
      });

      test('should initialize commands', () {
        when(mockSettingsRepository.getTranslationProvider()).thenReturn('AI');

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        expect(viewModel.saveTranslationProvider, isA<Command<String, void>>());
        expect(viewModel.saveTranslationTargetLanguage,
            isA<Command<String, void>>());
        expect(
            viewModel.saveTranslationCacheEnabled, isA<Command<bool, void>>());
        expect(viewModel.saveTranslationModel, isA<Command<String, void>>());
        expect(
            viewModel.loadModels, isA<Command<void, List<OpenRouterModel>>>());
      });

      test('should load translation model on initialization', () {
        when(mockSettingsRepository.getTranslationModel())
            .thenReturn('translation-model-1');

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        verify(mockSettingsRepository.getTranslationModel()).called(1);
      });
    });

    group('支持的语言列表', () {
      test('should contain expected languages', () {
        const expectedLanguages = [
          '中文',
          'English',
          '日本語',
          '한국어',
          'Français',
          'Deutsch',
          'Español',
          'Italiano',
          'Português',
          'Русский',
        ];

        expect(TranslationSettingsViewModel.supportedLanguages,
            equals(expectedLanguages));
        expect(
            TranslationSettingsViewModel.supportedLanguages.length, equals(10));
      });

      test('should include Chinese as first option', () {
        expect(TranslationSettingsViewModel.supportedLanguages.first,
            equals('中文'));
      });

      test('should include English as second option', () {
        expect(TranslationSettingsViewModel.supportedLanguages[1],
            equals('English'));
      });
    });

    group('保存翻译服务提供方', () {
      test('should save provider successfully and update local state',
          () async {
        const newProvider = 'NewAI';

        when(mockSettingsRepository.getTranslationProvider()).thenReturn('AI');
        when(mockSettingsRepository.saveTranslationProvider(newProvider))
            .thenAnswer((_) async => const Success(()));

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        await viewModel.saveTranslationProvider.executeWithFuture(newProvider);

        expect(viewModel.translationProvider, equals(newProvider));
        expect(listenerCallCount,
            greaterThanOrEqualTo(1)); // Should notify listeners at least once
        verify(mockSettingsRepository.saveTranslationProvider(newProvider))
            .called(1);
      });

      test('should handle save failure and throw exception', () async {
        const newProvider = 'FailProvider';
        final exception = Exception('Save failed');

        when(mockSettingsRepository.getTranslationProvider()).thenReturn('AI');
        when(mockSettingsRepository.saveTranslationProvider(newProvider))
            .thenAnswer((_) async => Failure(exception));

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        await expectLater(
          viewModel.saveTranslationProvider.executeWithFuture(newProvider),
          throwsA(isA<Exception>()),
        );

        // State should not change when save fails
        expect(viewModel.translationProvider, equals('AI'));
        // Even on failure, commands may notify listeners during execution
        verify(mockSettingsRepository.saveTranslationProvider(newProvider))
            .called(1);
      });
    });

    group('保存翻译目标语种', () {
      test('should save language successfully and update local state',
          () async {
        const newLanguage = 'English';

        when(mockSettingsRepository.getTranslationTargetLanguage())
            .thenReturn('中文');
        when(mockSettingsRepository.saveTranslationTargetLanguage(newLanguage))
            .thenAnswer((_) async => const Success(()));

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        await viewModel.saveTranslationTargetLanguage
            .executeWithFuture(newLanguage);

        expect(viewModel.translationTargetLanguage, equals(newLanguage));
        expect(listenerCallCount,
            greaterThanOrEqualTo(1)); // Should notify listeners at least once
        verify(mockSettingsRepository
                .saveTranslationTargetLanguage(newLanguage))
            .called(1);
      });
    });

    group('保存翻译缓存设置', () {
      test('should save cache enabled successfully and update local state',
          () async {
        const newCacheEnabled = false;

        when(mockSettingsRepository.getTranslationCacheEnabled())
            .thenReturn(true);
        when(mockSettingsRepository
                .saveTranslationCacheEnabled(newCacheEnabled))
            .thenAnswer((_) async => const Success(()));

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        await viewModel.saveTranslationCacheEnabled
            .executeWithFuture(newCacheEnabled);

        expect(viewModel.translationCacheEnabled, equals(newCacheEnabled));
        expect(listenerCallCount,
            greaterThanOrEqualTo(1)); // Should notify listeners at least once
        verify(mockSettingsRepository
                .saveTranslationCacheEnabled(newCacheEnabled))
            .called(1);
      });
    });

    group('模型选择功能', () {
      test('should load models with translation category', () async {
        when(mockSettingsRepository.getTranslationProvider()).thenReturn('AI');

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        await viewModel.loadModels.executeWithFuture();

        verify(mockOpenRouterRepository.getModels(category: 'translation'))
            .called(1);
      });

      test('should save translation model successfully', () async {
        const modelId = 'translation-model-1';

        when(mockSettingsRepository.getTranslationProvider()).thenReturn('AI');
        when(mockSettingsRepository.saveTranslationModel(modelId))
            .thenAnswer((_) async => const Success(()));

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        await viewModel.saveTranslationModel.executeWithFuture(modelId);

        verify(mockSettingsRepository.saveTranslationModel(modelId)).called(1);
      });

      test('should return selected translation model from loaded models',
          () async {
        when(mockSettingsRepository.getTranslationProvider()).thenReturn('AI');
        when(mockSettingsRepository.getTranslationModel())
            .thenReturn('translation-model-2');

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        // Load models first
        await viewModel.loadModels.executeWithFuture();

        expect(viewModel.selectedTranslationModel?.id,
            equals('translation-model-2'));
        expect(viewModel.selectedTranslationModel?.name,
            equals('Translation Model 2'));
      });

      test('should return null when no model is selected', () async {
        when(mockSettingsRepository.getTranslationProvider()).thenReturn('AI');
        when(mockSettingsRepository.getTranslationModel()).thenReturn('');

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        // Load models first
        await viewModel.loadModels.executeWithFuture();

        expect(viewModel.selectedTranslationModel, isNull);
      });

      test(
          'should return null when selected model does not exist in loaded models',
          () async {
        when(mockSettingsRepository.getTranslationProvider()).thenReturn('AI');
        when(mockSettingsRepository.getTranslationModel())
            .thenReturn('nonexistent-model');

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        // Load models first
        await viewModel.loadModels.executeWithFuture();

        expect(viewModel.selectedTranslationModel, isNull);
      });
    });

    group('内存管理', () {
      test('should dispose without errors', () {
        when(mockSettingsRepository.getTranslationProvider()).thenReturn('AI');

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        expect(() => viewModel.dispose(), returnsNormally);
      });

      test('should not crash when accessing properties after dispose', () {
        when(mockSettingsRepository.getTranslationProvider()).thenReturn('AI');

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);
        viewModel.dispose();

        // Should still be able to access properties
        expect(() => viewModel.translationProvider, returnsNormally);
        expect(() => viewModel.translationTargetLanguage, returnsNormally);
        expect(() => viewModel.translationCacheEnabled, returnsNormally);
      });
    });
  });
}
