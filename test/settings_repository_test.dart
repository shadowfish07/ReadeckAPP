import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/data/service/shared_preference_service.dart';
import 'package:result_dart/result_dart.dart';

// Generate mocks for dependencies
@GenerateMocks([ReadeckApiClient, SharedPreferencesService])
import 'settings_repository_test.mocks.dart';

void main() {
  group('SettingsRepository', () {
    late SettingsRepository repository;
    late MockReadeckApiClient mockApiClient;
    late MockSharedPreferencesService mockPrefsService;

    setUp(() {
      mockApiClient = MockReadeckApiClient();
      mockPrefsService = MockSharedPreferencesService();
      repository = SettingsRepository(mockApiClient, mockPrefsService);
    });

    group('isApiConfigured', () {
      test('should return false when host is empty', () async {
        // Arrange
        when(mockPrefsService.getReadeckApiHost())
            .thenAnswer((_) async => const Success(''));
        when(mockPrefsService.getReadeckApiToken())
            .thenAnswer((_) async => const Success('some-token'));

        // Act
        final result = await repository.isApiConfigured();

        // Assert
        expect(result.isSuccess(), isTrue);
        expect(result.getOrThrow(), isFalse);
        verify(mockPrefsService.getReadeckApiHost()).called(1);
        verifyNever(mockPrefsService.getReadeckApiToken());
      });

      test('should return false when token is empty', () async {
        // Arrange
        when(mockPrefsService.getReadeckApiHost())
            .thenAnswer((_) async => const Success('https://api.example.com'));
        when(mockPrefsService.getReadeckApiToken())
            .thenAnswer((_) async => const Success(''));

        // Act
        final result = await repository.isApiConfigured();

        // Assert
        expect(result.isSuccess(), isTrue);
        expect(result.getOrThrow(), isFalse);
        verify(mockPrefsService.getReadeckApiHost()).called(1);
        verify(mockPrefsService.getReadeckApiToken()).called(1);
      });

      test('should return false when both host and token are empty', () async {
        // Arrange
        when(mockPrefsService.getReadeckApiHost())
            .thenAnswer((_) async => const Success(''));
        when(mockPrefsService.getReadeckApiToken())
            .thenAnswer((_) async => const Success(''));

        // Act
        final result = await repository.isApiConfigured();

        // Assert
        expect(result.isSuccess(), isTrue);
        expect(result.getOrThrow(), isFalse);
        verify(mockPrefsService.getReadeckApiHost()).called(1);
        verifyNever(mockPrefsService.getReadeckApiToken());
      });

      test('should return true when both host and token are provided', () async {
        // Arrange
        when(mockPrefsService.getReadeckApiHost())
            .thenAnswer((_) async => const Success('https://api.example.com'));
        when(mockPrefsService.getReadeckApiToken())
            .thenAnswer((_) async => const Success('valid-token'));

        // Act
        final result = await repository.isApiConfigured();

        // Assert
        expect(result.isSuccess(), isTrue);
        expect(result.getOrThrow(), isTrue);
        verify(mockPrefsService.getReadeckApiHost()).called(1);
        verify(mockPrefsService.getReadeckApiToken()).called(1);
      });

      test('should handle host retrieval failure gracefully', () async {
        // Arrange
        when(mockPrefsService.getReadeckApiHost())
            .thenAnswer((_) async => Failure(Exception('Host retrieval failed')));

        // Act
        final result = await repository.isApiConfigured();

        // Assert
        expect(result.isSuccess(), isTrue);
        expect(result.getOrThrow(), isFalse);
        verify(mockPrefsService.getReadeckApiHost()).called(1);
        verifyNever(mockPrefsService.getReadeckApiToken());
      });

      test('should handle token retrieval failure gracefully', () async {
        // Arrange
        when(mockPrefsService.getReadeckApiHost())
            .thenAnswer((_) async => const Success('https://api.example.com'));
        when(mockPrefsService.getReadeckApiToken())
            .thenAnswer((_) async => Failure(Exception('Token retrieval failed')));

        // Act
        final result = await repository.isApiConfigured();

        // Assert
        expect(result.isSuccess(), isTrue);
        expect(result.getOrThrow(), isFalse);
        verify(mockPrefsService.getReadeckApiHost()).called(1);
        verify(mockPrefsService.getReadeckApiToken()).called(1);
      });
    });

    group('saveApiConfig', () {
      const testHost = 'https://api.example.com';
      const testToken = 'test-token-123';

      test('should save both host and token successfully', () async {
        // Arrange
        when(mockPrefsService.setReadeckApiHost(testHost))
            .thenAnswer((_) async => const Success(unit));
        when(mockPrefsService.setReadeckApiToken(testToken))
            .thenAnswer((_) async => const Success(unit));

        // Act
        final result = await repository.saveApiConfig(testHost, testToken);

        // Assert
        expect(result.isSuccess(), isTrue);
        verify(mockPrefsService.setReadeckApiHost(testHost)).called(1);
        verify(mockPrefsService.setReadeckApiToken(testToken)).called(1);
        verify(mockApiClient.updateConfig(testHost, testToken)).called(1);
      });

      test('should return failure when host saving fails', () async {
        // Arrange
        final hostError = Exception('Failed to save host');
        when(mockPrefsService.setReadeckApiHost(testHost))
            .thenAnswer((_) async => Failure(hostError));

        // Act
        final result = await repository.saveApiConfig(testHost, testToken);

        // Assert
        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), equals(hostError));
        verify(mockPrefsService.setReadeckApiHost(testHost)).called(1);
        verifyNever(mockPrefsService.setReadeckApiToken(any));
        verifyNever(mockApiClient.updateConfig(any, any));
      });

      test('should return failure when token saving fails', () async {
        // Arrange
        final tokenError = Exception('Failed to save token');
        when(mockPrefsService.setReadeckApiHost(testHost))
            .thenAnswer((_) async => const Success(unit));
        when(mockPrefsService.setReadeckApiToken(testToken))
            .thenAnswer((_) async => Failure(tokenError));

        // Act
        final result = await repository.saveApiConfig(testHost, testToken);

        // Assert
        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), equals(tokenError));
        verify(mockPrefsService.setReadeckApiHost(testHost)).called(1);
        verify(mockPrefsService.setReadeckApiToken(testToken)).called(1);
        verifyNever(mockApiClient.updateConfig(any, any));
      });

      test('should handle empty host parameter', () async {
        // Arrange
        when(mockPrefsService.setReadeckApiHost(''))
            .thenAnswer((_) async => const Success(unit));
        when(mockPrefsService.setReadeckApiToken(testToken))
            .thenAnswer((_) async => const Success(unit));

        // Act
        final result = await repository.saveApiConfig('', testToken);

        // Assert
        expect(result.isSuccess(), isTrue);
        verify(mockPrefsService.setReadeckApiHost('')).called(1);
        verify(mockPrefsService.setReadeckApiToken(testToken)).called(1);
        verify(mockApiClient.updateConfig('', testToken)).called(1);
      });

      test('should handle empty token parameter', () async {
        // Arrange
        when(mockPrefsService.setReadeckApiHost(testHost))
            .thenAnswer((_) async => const Success(unit));
        when(mockPrefsService.setReadeckApiToken(''))
            .thenAnswer((_) async => const Success(unit));

        // Act
        final result = await repository.saveApiConfig(testHost, '');

        // Assert
        expect(result.isSuccess(), isTrue);
        verify(mockPrefsService.setReadeckApiHost(testHost)).called(1);
        verify(mockPrefsService.setReadeckApiToken('')).called(1);
        verify(mockApiClient.updateConfig(testHost, '')).called(1);
      });

      test('should handle extremely long host and token values', () async {
        // Arrange
        final longHost = 'https://${'a' * 1000}.example.com';
        final longToken = 'token-${'x' * 2000}';
        when(mockPrefsService.setReadeckApiHost(longHost))
            .thenAnswer((_) async => const Success(unit));
        when(mockPrefsService.setReadeckApiToken(longToken))
            .thenAnswer((_) async => const Success(unit));

        // Act
        final result = await repository.saveApiConfig(longHost, longToken);

        // Assert
        expect(result.isSuccess(), isTrue);
        verify(mockPrefsService.setReadeckApiHost(longHost)).called(1);
        verify(mockPrefsService.setReadeckApiToken(longToken)).called(1);
        verify(mockApiClient.updateConfig(longHost, longToken)).called(1);
      });
    });

    group('getApiConfig', () {
      const testHost = 'https://api.example.com';
      const testToken = 'test-token-123';

      test('should return both host and token successfully', () async {
        // Arrange
        when(mockPrefsService.getReadeckApiHost())
            .thenAnswer((_) async => const Success(testHost));
        when(mockPrefsService.getReadeckApiToken())
            .thenAnswer((_) async => const Success(testToken));

        // Act
        final result = await repository.getApiConfig();

        // Assert
        expect(result.isSuccess(), isTrue);
        final (host, token) = result.getOrThrow();
        expect(host, equals(testHost));
        expect(token, equals(testToken));
        verify(mockPrefsService.getReadeckApiHost()).called(1);
        verify(mockPrefsService.getReadeckApiToken()).called(1);
      });

      test('should return failure when host retrieval fails', () async {
        // Arrange
        final hostError = Exception('Failed to get host');
        when(mockPrefsService.getReadeckApiHost())
            .thenAnswer((_) async => Failure(hostError));

        // Act
        final result = await repository.getApiConfig();

        // Assert
        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), isA<Exception>());
        verify(mockPrefsService.getReadeckApiHost()).called(1);
        verifyNever(mockPrefsService.getReadeckApiToken());
      });

      test('should return failure when token retrieval fails', () async {
        // Arrange
        final tokenError = Exception('Failed to get token');
        when(mockPrefsService.getReadeckApiHost())
            .thenAnswer((_) async => const Success(testHost));
        when(mockPrefsService.getReadeckApiToken())
            .thenAnswer((_) async => Failure(tokenError));

        // Act
        final result = await repository.getApiConfig();

        // Assert
        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), isA<Exception>());
        verify(mockPrefsService.getReadeckApiHost()).called(1);
        verify(mockPrefsService.getReadeckApiToken()).called(1);
      });

      test('should handle empty host and token values', () async {
        // Arrange
        when(mockPrefsService.getReadeckApiHost())
            .thenAnswer((_) async => const Success(''));
        when(mockPrefsService.getReadeckApiToken())
            .thenAnswer((_) async => const Success(''));

        // Act
        final result = await repository.getApiConfig();

        // Assert
        expect(result.isSuccess(), isTrue);
        final (host, token) = result.getOrThrow();
        expect(host, equals(''));
        expect(token, equals(''));
      });
    });

    group('saveOpenRouterApiKey', () {
      const testApiKey = 'or-api-key-123';

      test('should save OpenRouter API key successfully', () async {
        // Arrange