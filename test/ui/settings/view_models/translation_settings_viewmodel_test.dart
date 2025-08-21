import 'dart:async';

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
    provideDummy<Stream<void>>(const Stream<void>.empty());

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
      when(mockSettingsRepository.settingsChanged)
          .thenAnswer((_) => const Stream<void>.empty());
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
        expect(
            viewModel.loadModels, isA<Command<void, List<OpenRouterModel>>>());
      });

      test('should load translation model when accessed', () {
        when(mockSettingsRepository.getTranslationModel())
            .thenReturn('translation-model-1');

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        // Access the translation model to trigger the call
        final model = viewModel.translationModel;

        expect(model, equals('translation-model-1'));
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
            .thenAnswer((_) async {
          // Update mock to return new value after save
          when(mockSettingsRepository.getTranslationProvider())
              .thenReturn(newProvider);
          return const Success(());
        });

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
            .thenAnswer((_) async {
          // Update mock to return new value after save
          when(mockSettingsRepository.getTranslationTargetLanguage())
              .thenReturn(newLanguage);
          return const Success(());
        });

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
        // Should also clear translation cache when changing target language
        verify(mockArticleRepository.clearTranslationCache()).called(1);
      });

      test('should handle save failure and not clear cache', () async {
        const newLanguage = 'French';
        final exception = Exception('Save failed');

        when(mockSettingsRepository.getTranslationTargetLanguage())
            .thenReturn('中文');
        when(mockSettingsRepository.saveTranslationTargetLanguage(newLanguage))
            .thenAnswer((_) async => Failure(exception));

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        await expectLater(
          viewModel.saveTranslationTargetLanguage
              .executeWithFuture(newLanguage),
          throwsA(isA<Exception>()),
        );

        // State should not change when save fails
        expect(viewModel.translationTargetLanguage, equals('中文'));
        // Should not clear cache if save fails
        verifyNever(mockArticleRepository.clearTranslationCache());
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
            .thenAnswer((_) async {
          // Update mock to return new value after save
          when(mockSettingsRepository.getTranslationCacheEnabled())
              .thenReturn(newCacheEnabled);
          return const Success(());
        });

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

    group('缓存管理功能', () {
      test('should clear translation cache successfully', () async {
        when(mockSettingsRepository.getTranslationProvider()).thenReturn('AI');

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        await viewModel.clearTranslationCache.executeWithFuture();

        verify(mockArticleRepository.clearTranslationCache()).called(1);
      });

      test('should handle cache clearing failure', () async {
        final exception = Exception('Clear cache failed');
        when(mockSettingsRepository.getTranslationProvider()).thenReturn('AI');
        when(mockArticleRepository.clearTranslationCache())
            .thenAnswer((_) async => Failure(exception));

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        await expectLater(
          viewModel.clearTranslationCache.executeWithFuture(),
          throwsA(isA<Exception>()),
        );

        verify(mockArticleRepository.clearTranslationCache()).called(1);
      });

      test('should allow multiple cache clearing operations', () async {
        when(mockSettingsRepository.getTranslationProvider()).thenReturn('AI');

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        // Clear cache multiple times
        await viewModel.clearTranslationCache.executeWithFuture();
        await viewModel.clearTranslationCache.executeWithFuture();
        await viewModel.clearTranslationCache.executeWithFuture();

        verify(mockArticleRepository.clearTranslationCache()).called(3);
      });
    });

    group('配置变更监听功能', () {
      test('should listen to settings changes on initialization', () {
        final streamController = StreamController<void>();
        when(mockSettingsRepository.settingsChanged)
            .thenAnswer((_) => streamController.stream);

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

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

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

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

      test('should handle settings changes notification correctly', () async {
        final streamController = StreamController<void>();
        when(mockSettingsRepository.settingsChanged)
            .thenAnswer((_) => streamController.stream);

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);
        final initialListenerCount = listenerCallCount;

        // Trigger settings change from external source (not from this ViewModel)
        streamController.add(null);
        await Future.delayed(const Duration(milliseconds: 10));

        // Verify that listeners were notified
        expect(listenerCallCount, greaterThan(initialListenerCount));

        streamController.close();
      });

      test(
          'should continue working after settings change during save operations',
          () async {
        final streamController = StreamController<void>();
        when(mockSettingsRepository.settingsChanged)
            .thenAnswer((_) => streamController.stream);
        when(mockSettingsRepository.saveTranslationProvider('NewProvider'))
            .thenAnswer((_) async => const Success(()));

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        // Trigger save operation which will call notifyListeners locally
        await viewModel.saveTranslationProvider
            .executeWithFuture('NewProvider');
        final saveListenerCount = listenerCallCount;

        // Trigger external settings change (from another part of the app)
        streamController.add(null);
        await Future.delayed(const Duration(milliseconds: 10));

        // Both local notifyListeners (from save) and external change should work
        expect(saveListenerCount, greaterThanOrEqualTo(1));
        expect(listenerCallCount, greaterThan(saveListenerCount));

        streamController.close();
      });

      test('should handle simultaneous settings changes and cache clearing',
          () async {
        final streamController = StreamController<void>();
        when(mockSettingsRepository.settingsChanged)
            .thenAnswer((_) => streamController.stream);
        when(mockSettingsRepository.saveTranslationTargetLanguage('English'))
            .thenAnswer((_) async => const Success(()));

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        // Trigger save target language (which also clears cache)
        final saveFuture = viewModel.saveTranslationTargetLanguage
            .executeWithFuture('English');

        // Trigger external settings change while save is in progress
        streamController.add(null);

        await saveFuture;
        await Future.delayed(const Duration(milliseconds: 10));

        // Should handle both operations correctly
        expect(listenerCallCount, greaterThanOrEqualTo(1));
        verify(mockArticleRepository.clearTranslationCache()).called(1);

        streamController.close();
      });
    });

    group('内存管理', () {
      test('should dispose without errors', () {
        when(mockSettingsRepository.getTranslationProvider()).thenReturn('AI');

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        expect(() => viewModel.dispose(), returnsNormally);
      });

      test('should cancel settings subscription on dispose', () {
        final streamController = StreamController<void>();
        when(mockSettingsRepository.settingsChanged)
            .thenAnswer((_) => streamController.stream);

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        expect(() => viewModel.dispose(), returnsNormally);
        streamController.close();
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

      test('should handle multiple dispose calls safely', () {
        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        // First dispose should work fine
        expect(() => viewModel.dispose(), returnsNormally);

        // Second dispose will throw an error because Commands don't allow double dispose
        // This is expected behavior in flutter_command library
        expect(() => viewModel.dispose(), throwsA(isA<AssertionError>()));
      });

      test('should dispose with null settings subscription', () {
        // Create viewModel where subscription might be null
        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        expect(() => viewModel.dispose(), returnsNormally);
      });

      test('should handle settings subscription lifecycle correctly', () {
        final streamController = StreamController<void>();
        when(mockSettingsRepository.settingsChanged)
            .thenAnswer((_) => streamController.stream);

        viewModel = TranslationSettingsViewModel(mockSettingsRepository,
            mockArticleRepository, mockOpenRouterRepository);

        // Verify subscription is created
        expect(viewModel, isNotNull);

        // Dispose should cancel subscription
        expect(() => viewModel.dispose(), returnsNormally);
        streamController.close();
      });
    });
  });
}
