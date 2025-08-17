import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/ai_tag_recommendation/ai_tag_recommendation_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/data/service/openrouter_api_client.dart'; // cspell:disable-line
import 'package:readeck_app/data/service/web_content_service.dart';
import 'package:readeck_app/main.dart';
import 'package:result_dart/result_dart.dart';

import 'ai_tag_recommendation_repository_simple_test.mocks.dart';

// Generate Mock classes
@GenerateMocks([OpenRouterApiClient, SettingsRepository])
void main() {
  setUpAll(() {
    // Provide dummy values for Mockito
    provideDummy<Result<String>>(const Success('dummy'));

    // Initialize appLogger for tests
    appLogger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        dateTimeFormat: DateTimeFormat.none,
      ),
      level: Level.off, // Reduce log noise in tests
    );
  });

  group('AiTagRecommendationRepository', () {
    late MockOpenRouterApiClient mockOpenRouterApiClient;
    late MockSettingsRepository mockSettingsRepository;
    late AiTagRecommendationRepository repository;

    setUp(() {
      mockOpenRouterApiClient = MockOpenRouterApiClient();
      mockSettingsRepository = MockSettingsRepository();
      repository = AiTagRecommendationRepository(
        mockOpenRouterApiClient,
        mockSettingsRepository,
      );
    });

    group('isAvailable', () {
      test('should return true when API key and model are configured', () {
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn('test-api-key');
        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn('test-model');

        expect(repository.isAvailable, isTrue);
      });

      test('should return false when API key is empty', () {
        when(mockSettingsRepository.getOpenRouterApiKey()).thenReturn('');
        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn('test-model');

        expect(repository.isAvailable, isFalse);
      });

      test('should return false when model is empty', () {
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn('test-api-key');
        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn('');

        expect(repository.isAvailable, isFalse);
      });

      test('should return false when both API key and model are empty', () {
        when(mockSettingsRepository.getOpenRouterApiKey()).thenReturn('');
        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn('');

        expect(repository.isAvailable, isFalse);
      });
    });

    group('generateTagRecommendations', () {
      const testWebContent = WebContent(
        url: 'https://example.com',
        title: 'Test Article',
        content: 'This is a test article about technology and programming.',
      );
      const existingTags = ['tech', 'programming'];

      test('should return failure when AI is not available', () async {
        when(mockSettingsRepository.getOpenRouterApiKey()).thenReturn('');
        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn('');

        final result = await repository.generateTagRecommendations(
          testWebContent,
          existingTags,
        );

        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull().toString(), contains('AI标签推荐功能不可用'));
      });

      test('should successfully generate tag recommendations', () async {
        // Setup AI availability
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn('test-api-key');
        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn('test-model');
        when(mockSettingsRepository.getAiTagTargetLanguage())
            .thenReturn('English');

        // Mock successful API response
        when(mockOpenRouterApiClient.chatCompletion(
          model: anyNamed('model'),
          messages: anyNamed('messages'),
          temperature: anyNamed('temperature'),
          maxTokens: anyNamed('maxTokens'),
        )).thenAnswer((_) async => const Success('["development", "web"]'));

        final result = await repository.generateTagRecommendations(
          testWebContent,
          existingTags,
        );

        expect(result.isSuccess(), isTrue);
        final tags = result.getOrThrow();
        expect(tags, equals(['development', 'web']));
      });

      test('should handle API call failure', () async {
        // Setup AI availability
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn('test-api-key');
        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn('test-model');
        when(mockSettingsRepository.getAiTagTargetLanguage())
            .thenReturn('English');

        // Mock API failure
        final apiException = Exception('API call failed');
        when(mockOpenRouterApiClient.chatCompletion(
          model: anyNamed('model'),
          messages: anyNamed('messages'),
          temperature: anyNamed('temperature'),
          maxTokens: anyNamed('maxTokens'),
        )).thenAnswer((_) async => Failure(apiException));

        final result = await repository.generateTagRecommendations(
          testWebContent,
          existingTags,
        );

        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), equals(apiException));
      });

      test('should handle JSON array with extra text', () async {
        // Setup AI availability
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn('test-api-key');
        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn('test-model');
        when(mockSettingsRepository.getAiTagTargetLanguage())
            .thenReturn('English');

        // Mock response with extra text around JSON
        when(mockOpenRouterApiClient.chatCompletion(
          model: anyNamed('model'),
          messages: anyNamed('messages'),
          temperature: anyNamed('temperature'),
          maxTokens: anyNamed('maxTokens'),
        )).thenAnswer((_) async => const Success(
            'Here are the recommended tags: ["technology", "ai"] based on the content.'));

        final result = await repository.generateTagRecommendations(
          testWebContent,
          [],
        );

        expect(result.isSuccess(), isTrue);
        final tags = result.getOrThrow();
        expect(tags, equals(['technology', 'ai']));
      });

      test('should filter out empty and long tags', () async {
        // Setup AI availability
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn('test-api-key');
        when(mockSettingsRepository.getSelectedOpenRouterModel())
            .thenReturn('test-model');
        when(mockSettingsRepository.getAiTagTargetLanguage())
            .thenReturn('English');

        // Mock response with empty and long tags
        when(mockOpenRouterApiClient.chatCompletion(
          model: anyNamed('model'),
          messages: anyNamed('messages'),
          temperature: anyNamed('temperature'),
          maxTokens: anyNamed('maxTokens'),
        )).thenAnswer((_) async => const Success(
            '["good", "", "verylongtagthatexceedslimit", "tech"]')); // cspell:disable-line

        final result = await repository.generateTagRecommendations(
          testWebContent,
          [],
        );

        expect(result.isSuccess(), isTrue);
        final tags = result.getOrThrow();
        expect(tags, equals(['good', 'tech']));
      });
    });
  });
}
