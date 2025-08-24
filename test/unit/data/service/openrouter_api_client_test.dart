import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/service/openrouter_api_client.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/utils/api_not_configured_exception.dart';
import 'package:readeck_app/utils/network_error_exception.dart';
import 'package:result_dart/result_dart.dart';

import '../../../helpers/test_logger_helper.dart';
import 'openrouter_api_client_test.mocks.dart';

// 生成 Mock 类
@GenerateMocks([http.Client, SettingsRepository])
void main() {
  // 为 Mockito 提供 dummy 值
  provideDummy<Result<String>>(Failure(Exception('dummy')));
  provideDummy<Result<List<Map<String, dynamic>>>>(Failure(Exception('dummy')));
  provideDummy<Result<bool>>(Failure(Exception('dummy')));
  provideDummy<Result<int>>(Failure(Exception('dummy')));
  provideDummy<Result<double>>(Failure(Exception('dummy')));
  provideDummy<Result<Map<String, dynamic>>>(Failure(Exception('dummy')));
  group('OpenRouterApiClient Tests', () {
    late OpenRouterApiClient apiClient;
    late MockClient mockHttpClient;
    late MockSettingsRepository mockSettingsRepository;
    const testBaseUrl = 'https://openrouter.ai/api/v1';
    const testApiKey = 'test-api-key-123';

    setUp(() {
      // 初始化全局 appLogger
      setupTestLogger();

      mockHttpClient = MockClient();
      mockSettingsRepository = MockSettingsRepository();
      apiClient = OpenRouterApiClient(
        mockSettingsRepository,
        baseUrl: testBaseUrl,
        httpClient: mockHttpClient,
      );
    });

    tearDown(() {
      apiClient.dispose();
    });

    group('Configuration Tests', () {
      test('should handle unconfigured API', () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey()).thenReturn('');

        // Act
        final isConfigured = apiClient.isConfigured;

        // Assert
        expect(isConfigured, false);
      });

      test('should handle configured API', () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(testApiKey);

        // Act
        final isConfigured = apiClient.isConfigured;

        // Assert
        expect(isConfigured, true);
      });

      test('should handle null API key', () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey()).thenReturn('');

        // Act
        final isConfigured = apiClient.isConfigured;

        // Assert
        expect(isConfigured, false);
      });
    });

    group('streamChatCompletion Tests', () {
      test('should return ApiNotConfiguredException when not configured',
          () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey()).thenReturn('');

        // Act
        final stream = apiClient.streamChatCompletion(
          model: 'openai/gpt-3.5-turbo',
          messages: [
            {'role': 'user', 'content': 'Hello'}
          ],
        );

        // Assert
        await expectLater(
          stream,
          emits(predicate<Result<String>>((result) =>
              result.isError() &&
              result.exceptionOrNull() is ApiNotConfiguredException)),
        );
      });

      test('should handle successful streaming response', () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(testApiKey);

        final mockStreamedResponse = http.StreamedResponse(
          Stream.fromIterable([
            utf8.encode(
                'data: {"choices":[{"delta":{"content":"Hello"}}]}\n\n'),
            utf8.encode(
                'data: {"choices":[{"delta":{"content":" World"}}]}\n\n'),
            utf8.encode('data: [DONE]\n\n'),
          ]),
          200,
        );

        when(mockHttpClient.send(any))
            .thenAnswer((_) async => mockStreamedResponse);

        // Act
        final stream = apiClient.streamChatCompletion(
          model: 'openai/gpt-3.5-turbo',
          messages: [
            {'role': 'user', 'content': 'Hello'}
          ],
        );

        // Assert
        final results = await stream.toList();
        expect(results.length, 2);
        expect(results[0].isSuccess(), true);
        expect(results[0].getOrNull(), 'Hello');
        expect(results[1].isSuccess(), true);
        expect(results[1].getOrNull(), ' World');
      });

      test('should handle HTTP error response', () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(testApiKey);

        final mockStreamedResponse = http.StreamedResponse(
          Stream.fromIterable([utf8.encode('Error message')]),
          400,
        );

        when(mockHttpClient.send(any))
            .thenAnswer((_) async => mockStreamedResponse);

        // Act
        final stream = apiClient.streamChatCompletion(
          model: 'openai/gpt-3.5-turbo',
          messages: [
            {'role': 'user', 'content': 'Hello'}
          ],
        );

        // Assert
        await expectLater(
          stream,
          emits(predicate<Result<String>>((result) =>
              result.isError() &&
              result.exceptionOrNull() is NetworkErrorException)),
        );
      });

      test('should handle malformed JSON in stream', () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(testApiKey);

        final mockStreamedResponse = http.StreamedResponse(
          Stream.fromIterable([
            utf8.encode(
                'data: {"choices":[{"delta":{"content":"Hello"}}]}\n\n'),
            utf8.encode('data: invalid json\n\n'),
            utf8.encode(
                'data: {"choices":[{"delta":{"content":" World"}}]}\n\n'),
            utf8.encode('data: [DONE]\n\n'),
          ]),
          200,
        );

        when(mockHttpClient.send(any))
            .thenAnswer((_) async => mockStreamedResponse);

        // Act
        final stream = apiClient.streamChatCompletion(
          model: 'openai/gpt-3.5-turbo',
          messages: [
            {'role': 'user', 'content': 'Hello'}
          ],
        );

        // Assert
        final results = await stream.toList();
        expect(results.length, 2); // 只有有效的响应
        expect(results[0].isSuccess(), true);
        expect(results[0].getOrNull(), 'Hello');
        expect(results[1].isSuccess(), true);
        expect(results[1].getOrNull(), ' World');
      });

      test('should handle network exception', () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(testApiKey);

        when(mockHttpClient.send(any)).thenThrow(Exception('Network error'));

        // Act
        final stream = apiClient.streamChatCompletion(
          model: 'openai/gpt-3.5-turbo',
          messages: [
            {'role': 'user', 'content': 'Hello'}
          ],
        );

        // Assert
        await expectLater(
          stream,
          emits(predicate<Result<String>>((result) =>
              result.isError() &&
              result.exceptionOrNull() is NetworkErrorException)),
        );
      });
    });

    group('chatCompletion Tests', () {
      test('should return ApiNotConfiguredException when not configured',
          () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey()).thenReturn('');

        // Act
        final result = await apiClient.chatCompletion(
          model: 'openai/gpt-3.5-turbo',
          messages: [
            {'role': 'user', 'content': 'Hello'}
          ],
        );

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull(), isA<ApiNotConfiguredException>());
      });

      test('should handle successful chat completion', () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(testApiKey);

        final mockResponse = {
          'choices': [
            {
              'message': {'content': 'Hello! How can I help you today?'}
            }
          ]
        };

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode(mockResponse),
              200,
            ));

        // Act
        final result = await apiClient.chatCompletion(
          model: 'openai/gpt-3.5-turbo',
          messages: [
            {'role': 'user', 'content': 'Hello'}
          ],
        );

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull(), 'Hello! How can I help you today?');
      });

      test('should handle HTTP error response', () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(testApiKey);

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              'Bad Request',
              400,
            ));

        // Act
        final result = await apiClient.chatCompletion(
          model: 'openai/gpt-3.5-turbo',
          messages: [
            {'role': 'user', 'content': 'Hello'}
          ],
        );

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull(), isA<NetworkErrorException>());
      });

      test('should handle malformed response', () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(testApiKey);

        final mockResponse = {'invalid': 'response'};

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode(mockResponse),
              200,
            ));

        // Act
        final result = await apiClient.chatCompletion(
          model: 'openai/gpt-3.5-turbo',
          messages: [
            {'role': 'user', 'content': 'Hello'}
          ],
        );

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull(), isA<Exception>());
      });

      test('should handle network exception', () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(testApiKey);

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenThrow(Exception('Network error'));

        // Act
        final result = await apiClient.chatCompletion(
          model: 'openai/gpt-3.5-turbo',
          messages: [
            {'role': 'user', 'content': 'Hello'}
          ],
        );

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull(), isA<NetworkErrorException>());
      });
    });

    group('streamCompletion Tests', () {
      test('should return ApiNotConfiguredException when not configured',
          () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey()).thenReturn('');

        // Act
        final stream = apiClient.streamCompletion(
          model: 'openai/gpt-3.5-turbo-instruct',
          prompt: 'Hello',
        );

        // Assert
        await expectLater(
          stream,
          emits(predicate<Result<String>>((result) =>
              result.isError() &&
              result.exceptionOrNull() is ApiNotConfiguredException)),
        );
      });

      test('should handle successful streaming completion', () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(testApiKey);

        final mockStreamedResponse = http.StreamedResponse(
          Stream.fromIterable([
            utf8.encode('data: {"choices":[{"text":"Hello"}]}\n\n'),
            utf8.encode('data: {"choices":[{"text":" World"}]}\n\n'),
            utf8.encode('data: [DONE]\n\n'),
          ]),
          200,
        );

        when(mockHttpClient.send(any))
            .thenAnswer((_) async => mockStreamedResponse);

        // Act
        final stream = apiClient.streamCompletion(
          model: 'openai/gpt-3.5-turbo-instruct',
          prompt: 'Hello',
        );

        // Assert
        final results = await stream.toList();
        expect(results.length, 2);
        expect(results[0].isSuccess(), true);
        expect(results[0].getOrNull(), 'Hello');
        expect(results[1].isSuccess(), true);
        expect(results[1].getOrNull(), ' World');
      });
    });

    group('completion Tests', () {
      test('should return ApiNotConfiguredException when not configured',
          () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey()).thenReturn('');

        // Act
        final result = await apiClient.completion(
          model: 'openai/gpt-3.5-turbo-instruct',
          prompt: 'Hello',
        );

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull(), isA<ApiNotConfiguredException>());
      });

      test('should handle successful completion', () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(testApiKey);

        final mockResponse = {
          'choices': [
            {'text': 'Hello! How can I help you today?'}
          ]
        };

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode(mockResponse),
              200,
            ));

        // Act
        final result = await apiClient.completion(
          model: 'openai/gpt-3.5-turbo-instruct',
          prompt: 'Hello',
        );

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull(), 'Hello! How can I help you today?');
      });
    });

    group('Parameter Tests', () {
      test('should include all optional parameters in chat completion request',
          () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(testApiKey);

        final mockResponse = {
          'choices': [
            {
              'message': {'content': 'Response'}
            }
          ]
        };

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode(mockResponse),
              200,
            ));

        // Act
        await apiClient.chatCompletion(
          model: 'openai/gpt-3.5-turbo',
          messages: [
            {'role': 'user', 'content': 'Hello'}
          ],
          temperature: 0.7,
          maxTokens: 100,
          topP: 0.9,
          frequencyPenalty: 0.1,
          presencePenalty: 0.2,
        );

        // Assert
        final verification = verify(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: captureAnyNamed('body'),
        ));

        final captured = verification.captured;
        final requestBody = jsonDecode(captured.first as String);
        expect(requestBody['temperature'], 0.7);
        expect(requestBody['max_tokens'], 100);
        expect(requestBody['top_p'], 0.9);
        expect(requestBody['frequency_penalty'], 0.1);
        expect(requestBody['presence_penalty'], 0.2);
        expect(requestBody['stream'], false);
      });

      test('should include stop parameter in completion request', () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(testApiKey);

        final mockResponse = {
          'choices': [
            {'text': 'Response'}
          ]
        };

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode(mockResponse),
              200,
            ));

        // Act
        await apiClient.completion(
          model: 'openai/gpt-3.5-turbo-instruct',
          prompt: 'Hello',
          stop: ['\n', '###'],
        );

        // Assert
        final verification = verify(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: captureAnyNamed('body'),
        ));

        final captured = verification.captured;
        final requestBody = jsonDecode(captured.first as String);
        expect(requestBody['stop'], ['\n', '###']);
      });
    });

    group('Headers Tests', () {
      test('should include correct headers in requests', () async {
        // Arrange
        when(mockSettingsRepository.getOpenRouterApiKey())
            .thenReturn(testApiKey);

        final mockResponse = {
          'choices': [
            {
              'message': {'content': 'Response'}
            }
          ]
        };

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              jsonEncode(mockResponse),
              200,
            ));

        // Act
        await apiClient.chatCompletion(
          model: 'openai/gpt-3.5-turbo',
          messages: [
            {'role': 'user', 'content': 'Hello'}
          ],
        );

        // Assert
        final verification = verify(mockHttpClient.post(
          any,
          headers: captureAnyNamed('headers'),
          body: anyNamed('body'),
        ));

        final captured = verification.captured;
        final headers = captured.first as Map<String, String>;
        expect(headers['Authorization'], 'Bearer $testApiKey');
        expect(headers['Content-Type'], 'application/json');
        expect(headers['X-Title'], 'ReadeckApp');
      });
    });
  });
}
