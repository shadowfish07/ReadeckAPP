import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/data/service/shared_preference_service.dart';
import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/main.dart';
import 'package:result_dart/result_dart.dart';

import 'settings_repository_test.mocks.dart';

// Generate mock classes
@GenerateMocks([SharedPreferencesService, ReadeckApiClient])
void main() {
  setUpAll(() {
    // Initialize appLogger for tests
    appLogger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        dateTimeFormat: DateTimeFormat.none,
      ),
      level: Level.warning, // Reduce log noise in tests
    );

    // Provide dummy values for Mockito
    provideDummy<Result<void>>(Success.unit());
  });

  group('SettingsRepository - Scenario Model Tests', () {
    late MockSharedPreferencesService mockPrefsService;
    late MockReadeckApiClient mockApiClient;
    late SettingsRepository repository;

    setUp(() {
      mockPrefsService = MockSharedPreferencesService();
      mockApiClient = MockReadeckApiClient();

      // Setup default mock behaviors for scenario models only
      when(mockPrefsService.getTranslationModel())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getAiTagModel())
          .thenAnswer((_) async => const Success(''));

      repository = SettingsRepository(mockPrefsService, mockApiClient);
    });

    group('Translation Model', () {
      test('should get translation model from service', () async {
        when(mockPrefsService.getTranslationModel())
            .thenAnswer((_) async => const Success('translation-model-1'));

        await repository.loadSettings();
        final result = repository.getTranslationModel();

        expect(result, equals('translation-model-1'));
        verify(mockPrefsService.getTranslationModel()).called(1);
      });

      test('should save translation model successfully', () async {
        const modelId = 'translation-model-2';

        when(mockPrefsService.setTranslationModel(modelId))
            .thenAnswer((_) async => const Success(()));

        final result = await repository.saveTranslationModel(modelId);

        expect(result.isSuccess(), isTrue);
        verify(mockPrefsService.setTranslationModel(modelId)).called(1);
      });

      test('should handle translation model save failure', () async {
        const modelId = 'translation-model-fail';
        final exception = Exception('Save failed');

        when(mockPrefsService.setTranslationModel(modelId))
            .thenAnswer((_) async => Failure(exception));

        final result = await repository.saveTranslationModel(modelId);

        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), equals(exception));
        verify(mockPrefsService.setTranslationModel(modelId)).called(1);
      });

      test('should cache translation model after save', () async {
        const modelId = 'cached-translation-model';

        when(mockPrefsService.setTranslationModel(modelId))
            .thenAnswer((_) async => const Success(()));

        await repository.saveTranslationModel(modelId);

        // Verify cached value is returned without calling service again
        final cachedResult = repository.getTranslationModel();
        expect(cachedResult, equals(modelId));

        // Should still only have 1 call from the setup, not from the getter
        verify(mockPrefsService.getTranslationModel()).called(1);
      });
    });

    group('AI Tag Model', () {
      test('should get ai tag model from service', () async {
        when(mockPrefsService.getAiTagModel())
            .thenAnswer((_) async => const Success('ai-tag-model-1'));

        await repository.loadSettings();
        final result = repository.getAiTagModel();

        expect(result, equals('ai-tag-model-1'));
        verify(mockPrefsService.getAiTagModel()).called(1);
      });

      test('should save ai tag model successfully', () async {
        const modelId = 'ai-tag-model-2';

        when(mockPrefsService.setAiTagModel(modelId))
            .thenAnswer((_) async => const Success(()));

        final result = await repository.saveAiTagModel(modelId);

        expect(result.isSuccess(), isTrue);
        verify(mockPrefsService.setAiTagModel(modelId)).called(1);
      });

      test('should handle ai tag model save failure', () async {
        const modelId = 'ai-tag-model-fail';
        final exception = Exception('Save failed');

        when(mockPrefsService.setAiTagModel(modelId))
            .thenAnswer((_) async => Failure(exception));

        final result = await repository.saveAiTagModel(modelId);

        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), equals(exception));
        verify(mockPrefsService.setAiTagModel(modelId)).called(1);
      });

      test('should cache ai tag model after save', () async {
        const modelId = 'cached-ai-tag-model';

        when(mockPrefsService.setAiTagModel(modelId))
            .thenAnswer((_) async => const Success(()));

        await repository.saveAiTagModel(modelId);

        // Verify cached value is returned without calling service again
        final cachedResult = repository.getAiTagModel();
        expect(cachedResult, equals(modelId));

        // Should still only have 1 call from the setup, not from the getter
        verify(mockPrefsService.getAiTagModel()).called(1);
      });
    });

    group('Settings Loading', () {
      test('should load scenario models during loadSettings', () async {
        when(mockPrefsService.getTranslationModel())
            .thenAnswer((_) async => const Success('loaded-translation-model'));
        when(mockPrefsService.getAiTagModel())
            .thenAnswer((_) async => const Success('loaded-ai-tag-model'));

        await repository.loadSettings();

        expect(repository.getTranslationModel(),
            equals('loaded-translation-model'));
        expect(repository.getAiTagModel(), equals('loaded-ai-tag-model'));

        // Verify both scenario models were loaded
        verify(mockPrefsService.getTranslationModel()).called(1);
        verify(mockPrefsService.getAiTagModel()).called(1);
      });

      test('should handle empty scenario models during loadSettings', () async {
        when(mockPrefsService.getTranslationModel())
            .thenAnswer((_) async => const Success(''));
        when(mockPrefsService.getAiTagModel())
            .thenAnswer((_) async => const Success(''));

        await repository.loadSettings();

        expect(repository.getTranslationModel(), equals(''));
        expect(repository.getAiTagModel(), equals(''));
      });
    });

    group('Cache Behavior', () {
      test('should return cached values after first load', () async {
        // First load
        when(mockPrefsService.getTranslationModel())
            .thenAnswer((_) async => const Success('cached-translation'));
        when(mockPrefsService.getAiTagModel())
            .thenAnswer((_) async => const Success('cached-ai-tag'));

        await repository.loadSettings();

        // Clear the mock to verify no additional calls
        clearInteractions(mockPrefsService);

        // Access cached values
        final translationModel = repository.getTranslationModel();
        final aiTagModel = repository.getAiTagModel();

        expect(translationModel, equals('cached-translation'));
        expect(aiTagModel, equals('cached-ai-tag'));

        // Verify no additional service calls were made
        verifyNever(mockPrefsService.getTranslationModel());
        verifyNever(mockPrefsService.getAiTagModel());
      });

      test('should update cache when models are saved', () async {
        await repository.loadSettings();

        // Save new models
        when(mockPrefsService.setTranslationModel('new-translation'))
            .thenAnswer((_) async => const Success(()));
        when(mockPrefsService.setAiTagModel('new-ai-tag'))
            .thenAnswer((_) async => const Success(()));

        await repository.saveTranslationModel('new-translation');
        await repository.saveAiTagModel('new-ai-tag');

        // Verify cached values are updated
        expect(repository.getTranslationModel(), equals('new-translation'));
        expect(repository.getAiTagModel(), equals('new-ai-tag'));
      });
    });
  });
}
