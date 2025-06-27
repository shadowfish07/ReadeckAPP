import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:result_dart/result_dart.dart';

import '../lib/data/service/openrouter_api_client.dart';
import '../lib/data/service/shared_preference_service.dart';

// Generate mocks for dependencies
@GenerateMocks([SharedPreferencesService, http.Client])
import 'openrouter_api_client_test.mocks.dart';

void main() {
  group('OpenRouterApiClient', () {
    late OpenRouterApiClient client;
    late MockSharedPreferencesService mockPrefsService;
    late MockClient mockHttpClient;
    
    const String testApiKey = 'or-test-api-key-12345';
    const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';
    
    setUp(() {
      mockPrefsService = MockSharedPreferencesService();
      mockHttpClient = MockClient();
      client = OpenRouterApiClient(mockPrefsService);
      
      // Inject mock HTTP client for testing
      client.httpClient = mockHttpClient;
    });
    
    tearDown(() {
      reset(mockPrefsService);
      reset(mockHttpClient);
    });

    group('Constructor and Initialization', () {
      test('should initialize with SharedPreferencesService', () {
        final client = OpenRouterApiClient(mockPrefsService);
        expect(client, isNotNull);
      });

      test('should throw error with null SharedPreferencesService', () {
        expect(
          () => OpenRouterApiClient(null),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('API Key Management', () {
      test('should retrieve API key from SharedPreferences successfully', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        // Act
        final result = await client.getApiKey();

        // Assert
        expect(result.isSuccess(), isTrue);
        expect(result.getOrThrow(), equals(testApiKey));
        verify(mockPrefsService.getOpenRouterApiKey()).called(1);
      });

      test('should handle missing API key gracefully', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Failure(Exception('API key not found')));

        // Act
        final result = await client.getApiKey();

        // Assert
        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull().toString(), contains('API key not found'));
      });

      test('should cache API key after first retrieval', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        // Act
        await client.getApiKey();
        await client.getApiKey(); // Second call should use cache

        // Assert
        verify(mockPrefsService.getOpenRouterApiKey()).called(1); // Only called once
      });
    });

    group('streamChatCompletion - Happy Path', () {
      test('should stream chat completion successfully', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        const streamResponse = '''data: {"id":"chatcmpl-123","object":"chat.completion.chunk","choices":[{"delta":{"content":"Hello"}}]}

data: {"id":"chatcmpl-123","object":"chat.completion.chunk","choices":[{"delta":{"content":" world!"}}]}

data: [DONE]

''';

        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          streamResponse,
          200,
          headers: {'content-type': 'text/plain; charset=utf-8'},
        ));

        final messages = [
          {'role': 'user', 'content': 'Hello'}
        ];

        // Act
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: messages,
          temperature: 0.7,
        );

        final results = <String>[];
        await for (final result in stream) {
          if (result.isSuccess()) {
            results.add(result.getOrThrow());
          }
        }

        // Assert
        expect(results.length, equals(2));
        expect(results[0], equals('Hello'));
        expect(results[1], equals(' world!'));
        
        // Verify API call was made correctly
        final captured = verify(mockHttpClient.post(
          captureAny,
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;
        
        final url = captured[0] as Uri;
        final headers = captured[1] as Map<String, String>;
        final body = captured[2] as String;
        
        expect(url.toString(), equals('$openRouterBaseUrl/chat/completions'));
        expect(headers['Authorization'], equals('Bearer $testApiKey'));
        expect(headers['Content-Type'], equals('application/json'));
        
        final bodyJson = json.decode(body) as Map<String, dynamic>;
        expect(bodyJson['model'], equals('google/gemini-2.5-flash'));
        expect(bodyJson['messages'], equals(messages));
        expect(bodyJson['temperature'], equals(0.7));
        expect(bodyJson['stream'], equals(true));
      });

      test('should handle various model types', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('data: [DONE]\n\n', 200));

        final testModels = [
          'google/gemini-2.5-flash',
          'openai/gpt-4',
          'anthropic/claude-3',
          'meta-llama/llama-3.1-8b',
        ];

        // Act & Assert
        for (final model in testModels) {
          final stream = client.streamChatCompletion(
            model: model,
            messages: [{'role': 'user', 'content': 'Test'}],
          );

          await for (final result in stream) {
            // Stream should complete without errors
            expect(result.isSuccess(), isTrue);
            break; // Only need to test that it starts successfully
          }
        }
      });
    });

    group('streamChatCompletion - Parameter Validation', () {
      test('should validate required parameters', () async {
        expect(
          () => client.streamChatCompletion(
            model: '',
            messages: [{'role': 'user', 'content': 'Hello'}],
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('Model cannot be empty'))),
        );

        expect(
          () => client.streamChatCompletion(
            model: 'valid-model',
            messages: [],
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('Messages cannot be empty'))),
        );

        expect(
          () => client.streamChatCompletion(
            model: 'valid-model',
            messages: [{'role': 'user'}], // missing content
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('Message missing required fields'))),
        );
      });

      test('should validate temperature parameter', () async {
        expect(
          () => client.streamChatCompletion(
            model: 'valid-model',
            messages: [{'role': 'user', 'content': 'Hello'}],
            temperature: -0.5, // Invalid: below 0
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('Temperature must be between 0 and 2'))),
        );

        expect(
          () => client.streamChatCompletion(
            model: 'valid-model',
            messages: [{'role': 'user', 'content': 'Hello'}],
            temperature: 2.5, // Invalid: above 2
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('Temperature must be between 0 and 2'))),
        );
      });

      test('should validate maxTokens parameter', () async {
        expect(
          () => client.streamChatCompletion(
            model: 'valid-model',
            messages: [{'role': 'user', 'content': 'Hello'}],
            maxTokens: -1, // Invalid: negative
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('maxTokens must be positive'))),
        );

        expect(
          () => client.streamChatCompletion(
            model: 'valid-model',
            messages: [{'role': 'user', 'content': 'Hello'}],
            maxTokens: 0, // Invalid: zero
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message, 'message', contains('maxTokens must be positive'))),
        );
      });

      test('should validate message structure', () async {
        final invalidMessages = [
          [{'content': 'Hello'}], // missing role
          [{'role': 'user'}], // missing content
          [{'role': 'invalid', 'content': 'Hello'}], // invalid role
          [{'role': 'user', 'content': ''}], // empty content
        ];

        for (final messages in invalidMessages) {
          expect(
            () => client.streamChatCompletion(
              model: 'valid-model',
              messages: messages,
            ),
            throwsA(isA<ArgumentError>()),
          );
        }
      });
    });

    group('streamChatCompletion - Error Handling', () {
      test('should handle API key retrieval failure', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Failure(Exception('Failed to get API key')));

        // Act
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: [{'role': 'user', 'content': 'Hello'}],
        );

        // Assert
        await expectLater(
          stream,
          emitsInOrder([
            predicate<Result<String>>((r) => r.isError() && 
              r.exceptionOrNull().toString().contains('Failed to get API key')),
          ]),
        );
      });

      test('should handle 401 Unauthorized', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(
              json.encode({'error': {'message': 'Invalid API key'}}),
              401,
            ));

        // Act
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: [{'role': 'user', 'content': 'Hello'}],
        );

        // Assert
        await expectLater(
          stream,
          emitsInOrder([
            predicate<Result<String>>((r) => r.isError() && 
              r.exceptionOrNull().toString().contains('401')),
          ]),
        );
      });

      test('should handle 429 Rate Limit', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(
              json.encode({'error': {'message': 'Rate limit exceeded'}}),
              429,
              headers: {'retry-after': '60'},
            ));

        // Act
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: [{'role': 'user', 'content': 'Hello'}],
        );

        // Assert
        await expectLater(
          stream,
          emitsInOrder([
            predicate<Result<String>>((r) => r.isError() && 
              r.exceptionOrNull().toString().contains('429')),
          ]),
        );
      });

      test('should handle 500 Internal Server Error', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(
              'Internal Server Error',
              500,
            ));

        // Act
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: [{'role': 'user', 'content': 'Hello'}],
        );

        // Assert
        await expectLater(
          stream,
          emitsInOrder([
            predicate<Result<String>>((r) => r.isError() && 
              r.exceptionOrNull().toString().contains('500')),
          ]),
        );
      });

      test('should handle network timeout', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenThrow(const SocketException('Connection timeout'));

        // Act
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: [{'role': 'user', 'content': 'Hello'}],
        );

        // Assert
        await expectLater(
          stream,
          emitsInOrder([
            predicate<Result<String>>((r) => r.isError() && 
              r.exceptionOrNull() is SocketException),
          ]),
        );
      });

      test('should handle malformed streaming response', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        const malformedResponse = '''data: {"invalid json"}}

data: [DONE]

''';

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(malformedResponse, 200));

        // Act
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: [{'role': 'user', 'content': 'Hello'}],
        );

        // Assert
        await expectLater(
          stream,
          emitsInOrder([
            predicate<Result<String>>((r) => r.isError() && 
              r.exceptionOrNull() is FormatException),
          ]),
        );
      });

      test('should handle connection lost during streaming', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        const partialResponse = '''data: {"id":"chatcmpl-123","object":"chat.completion.chunk","choices":[{"delta":{"content":"Hello"}}]}

'''; // Missing [DONE] - connection lost

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(partialResponse, 200));

        // Act
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: [{'role': 'user', 'content': 'Hello'}],
        );

        final results = <Result<String>>[];
        await for (final result in stream) {
          results.add(result);
        }

        // Assert
        expect(results.length, greaterThan(0));
        expect(results.last.isError(), isTrue);
        expect(results.last.exceptionOrNull().toString(), 
               contains('Stream ended unexpectedly'));
      });
    });

    group('Stream Response Parsing', () {
      test('should parse valid SSE chunks correctly', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        const streamResponse = '''data: {"id":"chatcmpl-123","object":"chat.completion.chunk","choices":[{"delta":{"content":"Hello"}}]}

data: {"id":"chatcmpl-123","object":"chat.completion.chunk","choices":[{"delta":{"content":" "}}]}

data: {"id":"chatcmpl-123","object":"chat.completion.chunk","choices":[{"delta":{"content":"world!"}}]}

data: [DONE]

''';

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(streamResponse, 200));

        // Act
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: [{'role': 'user', 'content': 'Hello'}],
        );

        final contents = <String>[];
        await for (final result in stream) {
          if (result.isSuccess()) {
            contents.add(result.getOrThrow());
          }
        }

        // Assert
        expect(contents, equals(['Hello', ' ', 'world!']));
      });

      test('should handle empty delta content', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        const streamResponse = '''data: {"id":"chatcmpl-123","object":"chat.completion.chunk","choices":[{"delta":{}}]}

data: {"id":"chatcmpl-123","object":"chat.completion.chunk","choices":[{"delta":{"content":"Hello"}}]}

data: [DONE]

''';

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(streamResponse, 200));

        // Act
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: [{'role': 'user', 'content': 'Hello'}],
        );

        final contents = <String>[];
        await for (final result in stream) {
          if (result.isSuccess()) {
            contents.add(result.getOrThrow());
          }
        }

        // Assert
        expect(contents, equals(['Hello'])); // Empty delta should be skipped
      });

      test('should handle finish_reason in stream', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        const streamResponse = '''data: {"id":"chatcmpl-123","object":"chat.completion.chunk","choices":[{"delta":{"content":"Done"},"finish_reason":"stop"}]}

data: [DONE]

''';

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(streamResponse, 200));

        // Act
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: [{'role': 'user', 'content': 'Hello'}],
        );

        final contents = <String>[];
        await for (final result in stream) {
          if (result.isSuccess()) {
            contents.add(result.getOrThrow());
          }
        }

        // Assert
        expect(contents, equals(['Done']));
      });
    });

    group('Request Building', () {
      test('should build request with all optional parameters', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('data: [DONE]\n\n', 200));

        final messages = [
          {'role': 'system', 'content': 'You are a helpful assistant'},
          {'role': 'user', 'content': 'Hello'}
        ];

        // Act
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: messages,
          temperature: 0.8,
          maxTokens: 150,
          topP: 0.95,
          frequencyPenalty: 0.5,
          presencePenalty: 0.3,
        );

        // Consume stream to trigger request
        await for (final _ in stream) {
          break;
        }

        // Assert
        final captured = verify(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured.single as String;

        final bodyJson = json.decode(captured) as Map<String, dynamic>;
        expect(bodyJson['model'], equals('google/gemini-2.5-flash'));
        expect(bodyJson['messages'], equals(messages));
        expect(bodyJson['temperature'], equals(0.8));
        expect(bodyJson['max_tokens'], equals(150));
        expect(bodyJson['top_p'], equals(0.95));
        expect(bodyJson['frequency_penalty'], equals(0.5));
        expect(bodyJson['presence_penalty'], equals(0.3));
        expect(bodyJson['stream'], equals(true));
      });

      test('should exclude null optional parameters from request', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('data: [DONE]\n\n', 200));

        // Act
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: [{'role': 'user', 'content': 'Hello'}],
          // Not providing optional parameters - they should be excluded
        );

        // Consume stream to trigger request
        await for (final _ in stream) {
          break;
        }

        // Assert
        final captured = verify(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured.single as String;

        final bodyJson = json.decode(captured) as Map<String, dynamic>;
        expect(bodyJson, isNot(contains('temperature')));
        expect(bodyJson, isNot(contains('max_tokens')));
        expect(bodyJson, isNot(contains('top_p')));
        expect(bodyJson, isNot(contains('frequency_penalty')));
        expect(bodyJson, isNot(contains('presence_penalty')));
      });

      test('should set correct headers', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('data: [DONE]\n\n', 200));

        // Act
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: [{'role': 'user', 'content': 'Hello'}],
        );

        // Consume stream to trigger request
        await for (final _ in stream) {
          break;
        }

        // Assert
        final captured = verify(mockHttpClient.post(
          any,
          headers: captureAnyNamed('headers'),
          body: anyNamed('body'),
        )).captured.single as Map<String, String>;

        expect(captured['Authorization'], equals('Bearer $testApiKey'));
        expect(captured['Content-Type'], equals('application/json'));
        expect(captured['Accept'], equals('text/event-stream'));
        expect(captured['Cache-Control'], equals('no-cache'));
      });
    });

    group('Edge Cases and Boundary Conditions', () {
      test('should handle very long content in messages', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('data: [DONE]\n\n', 200));

        final longContent = 'A' * 10000; // 10k characters
        final messages = [
          {'role': 'user', 'content': longContent}
        ];

        // Act & Assert - should not throw
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: messages,
        );

        await for (final result in stream) {
          expect(result.isSuccess(), isTrue);
          break;
        }
      });

      test('should handle special characters in content', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('data: [DONE]\n\n', 200));

        final specialContent = 'Test with emoji 🚀 and unicode ñáéíóú and symbols @#\$%^&*()';
        final messages = [
          {'role': 'user', 'content': specialContent}
        ];

        // Act & Assert - should not throw
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: messages,
        );

        await for (final result in stream) {
          expect(result.isSuccess(), isTrue);
          break;
        }

        // Verify content was properly encoded
        final captured = verify(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured.single as String;

        final bodyJson = json.decode(captured) as Map<String, dynamic>;
        expect(bodyJson['messages'][0]['content'], equals(specialContent));
      });

      test('should handle boundary temperature values', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('data: [DONE]\n\n', 200));

        final boundaryTemperatures = [0.0, 1.0, 2.0];

        // Act & Assert
        for (final temp in boundaryTemperatures) {
          final stream = client.streamChatCompletion(
            model: 'google/gemini-2.5-flash',
            messages: [{'role': 'user', 'content': 'Hello'}],
            temperature: temp,
          );

          await for (final result in stream) {
            expect(result.isSuccess(), isTrue);
            break;
          }
        }
      });

      test('should handle maximum token values', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('data: [DONE]\n\n', 200));

        // Act & Assert
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: [{'role': 'user', 'content': 'Hello'}],
          maxTokens: 100000, // Very large value
        );

        await for (final result in stream) {
          expect(result.isSuccess(), isTrue);
          break;
        }
      });
    });

    group('Performance and Concurrency', () {
      test('should handle multiple concurrent streams', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async {
              await Future.delayed(Duration(milliseconds: 10));
              return http.Response('data: {"choices":[{"delta":{"content":"test"}}]}\n\ndata: [DONE]\n\n', 200);
            });

        // Act
        final futures = List.generate(3, (index) async {
          final stream = client.streamChatCompletion(
            model: 'google/gemini-2.5-flash',
            messages: [{'role': 'user', 'content': 'Request $index'}],
          );

          final results = <String>[];
          await for (final result in stream) {
            if (result.isSuccess()) {
              results.add(result.getOrThrow());
            }
          }
          return results;
        });

        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(3));
        for (final result in results) {
          expect(result, isNotEmpty);
        }
      });

      test('should handle rapid successive requests', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('data: [DONE]\n\n', 200));

        // Act
        for (int i = 0; i < 5; i++) {
          final stream = client.streamChatCompletion(
            model: 'google/gemini-2.5-flash',
            messages: [{'role': 'user', 'content': 'Rapid request $i'}],
          );

          await for (final result in stream) {
            expect(result.isSuccess(), isTrue);
            break;
          }
        }

        // Assert
        verify(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .called(5);
      });
    });

    group('Integration Scenarios', () {
      test('should work with real-world conversation flow', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(
              'data: {"choices":[{"delta":{"content":"I understand you want to discuss"}}]}\n\n'
              'data: {"choices":[{"delta":{"content":" artificial intelligence."}}]}\n\n'
              'data: [DONE]\n\n',
              200));

        final conversationMessages = [
          {'role': 'system', 'content': 'You are a helpful AI assistant.'},
          {'role': 'user', 'content': 'Tell me about AI'},
          {'role': 'assistant', 'content': 'AI is fascinating...'},
          {'role': 'user', 'content': 'Can you elaborate?'},
        ];

        // Act
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: conversationMessages,
          temperature: 0.7,
          maxTokens: 500,
        );

        final fullResponse = StringBuffer();
        await for (final result in stream) {
          if (result.isSuccess()) {
            fullResponse.write(result.getOrThrow());
          }
        }

        // Assert
        expect(fullResponse.toString(), contains('understand'));
        expect(fullResponse.toString(), contains('artificial intelligence'));
        
        // Verify request included full conversation
        final captured = verify(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured.single as String;

        final bodyJson = json.decode(captured) as Map<String, dynamic>;
        expect(bodyJson['messages'], equals(conversationMessages));
      });

      test('should handle translation use case scenario', () async {
        // Arrange
        when(mockPrefsService.getOpenRouterApiKey())
            .thenAnswer((_) async => const Success(testApiKey));

        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(
              'data: {"choices":[{"delta":{"content":"这是翻译的内容"}}]}\n\n'
              'data: [DONE]\n\n',
              200));

        final translationMessages = [
          {
            'role': 'system',
            'content': '你是一个专业的翻译助手。请将用户提供的HTML内容翻译成中文，保持HTML标签结构不变，只翻译文本内容。'
          },
          {
            'role': 'user',
            'content': '<h1>Welcome to our website</h1><p>This is some content to translate.</p>'
          }
        ];

        // Act
        final stream = client.streamChatCompletion(
          model: 'google/gemini-2.5-flash',
          messages: translationMessages,
          temperature: 0.3, // Lower temperature for more consistent translations
        );

        final translation = StringBuffer();
        await for (final result in stream) {
          if (result.isSuccess()) {
            translation.write(result.getOrThrow());
          }
        }

        // Assert
        expect(translation.toString(), isNotEmpty);
        expect(translation.toString(), contains('翻译'));
        
        // Verify translation-specific parameters
        final captured = verify(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured.single as String;

        final bodyJson = json.decode(captured) as Map<String, dynamic>;
        expect(bodyJson['temperature'], equals(0.3));
        expect(bodyJson['messages'][0]['content'], contains('翻译助手'));
      });
    });
  });
}