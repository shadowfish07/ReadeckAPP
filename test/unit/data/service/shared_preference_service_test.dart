import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:readeck_app/data/service/shared_preference_service.dart';

void main() {
  group('SharedPreferencesService Tests', () {
    late SharedPreferencesService service;

    setUp(() async {
      // 清空 SharedPreferences 并初始化服务
      SharedPreferences.setMockInitialValues({});
      service = SharedPreferencesService();
    });

    group('Theme Mode Operations', () {
      test('should set and get theme mode successfully', () async {
        // Arrange
        final themeModeIndex = ThemeMode.dark.index;

        // Act
        final setResult = await service.setThemeMode(themeModeIndex);
        final getResult = await service.getThemeMode();

        // Assert
        expect(setResult.isSuccess(), true);
        expect(getResult.isSuccess(), true);
        expect(getResult.getOrNull(), themeModeIndex);
      });

      test('should return system theme mode as default', () async {
        // Act
        final result = await service.getThemeMode();

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull(), ThemeMode.system.index);
      });

      test('should handle all theme mode values', () async {
        // Test all theme modes
        for (final themeMode in ThemeMode.values) {
          // Act
          final setResult = await service.setThemeMode(themeMode.index);
          final getResult = await service.getThemeMode();

          // Assert
          expect(setResult.isSuccess(), true);
          expect(getResult.isSuccess(), true);
          expect(getResult.getOrNull(), themeMode.index);
        }
      });
    });

    group('Readeck API Host Operations', () {
      test('should set and get API host successfully', () async {
        // Arrange
        const apiHost = 'https://api.readeck.example.com';

        // Act
        final setResult = await service.setReadeckApiHost(apiHost);
        final getResult = await service.getReadeckApiHost();

        // Assert
        expect(setResult.isSuccess(), true);
        expect(getResult.isSuccess(), true);
        expect(getResult.getOrNull(), apiHost);
      });

      test('should return empty string as default API host', () async {
        // Act
        final result = await service.getReadeckApiHost();

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull(), '');
      });

      test('should handle empty API host', () async {
        // Arrange
        const apiHost = '';

        // Act
        final setResult = await service.setReadeckApiHost(apiHost);
        final getResult = await service.getReadeckApiHost();

        // Assert
        expect(setResult.isSuccess(), true);
        expect(getResult.isSuccess(), true);
        expect(getResult.getOrNull(), apiHost);
      });

      test('should handle special characters in API host', () async {
        // Arrange
        const apiHost = 'https://api-test.readeck.com:8080/v1';

        // Act
        final setResult = await service.setReadeckApiHost(apiHost);
        final getResult = await service.getReadeckApiHost();

        // Assert
        expect(setResult.isSuccess(), true);
        expect(getResult.isSuccess(), true);
        expect(getResult.getOrNull(), apiHost);
      });
    });

    group('Readeck API Token Operations', () {
      test('should set and get API token successfully', () async {
        // Arrange
        const apiToken = 'test-api-token-12345';

        // Act
        final setResult = await service.setReadeckApiToken(apiToken);
        final getResult = await service.getReadeckApiToken();

        // Assert
        expect(setResult.isSuccess(), true);
        expect(getResult.isSuccess(), true);
        expect(getResult.getOrNull(), apiToken);
      });

      test('should return empty string as default API token', () async {
        // Act
        final result = await service.getReadeckApiToken();

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull(), '');
      });

      test('should handle empty API token', () async {
        // Arrange
        const apiToken = '';

        // Act
        final setResult = await service.setReadeckApiToken(apiToken);
        final getResult = await service.getReadeckApiToken();

        // Assert
        expect(setResult.isSuccess(), true);
        expect(getResult.isSuccess(), true);
        expect(getResult.getOrNull(), apiToken);
      });

      test('should handle long API token', () async {
        // Arrange
        final apiToken = 'very-long-api-token-' * 10; // 200+ characters

        // Act
        final setResult = await service.setReadeckApiToken(apiToken);
        final getResult = await service.getReadeckApiToken();

        // Assert
        expect(setResult.isSuccess(), true);
        expect(getResult.isSuccess(), true);
        expect(getResult.getOrNull(), apiToken);
      });
    });

    group('OpenRouter API Key Operations', () {
      test('should set and get OpenRouter API key successfully', () async {
        // Arrange
        const apiKey = 'sk-or-test-key-12345';

        // Act
        final setResult = await service.setOpenRouterApiKey(apiKey);
        final getResult = await service.getOpenRouterApiKey();

        // Assert
        expect(setResult.isSuccess(), true);
        expect(getResult.isSuccess(), true);
        expect(getResult.getOrNull(), apiKey);
      });

      test('should return empty string as default OpenRouter API key',
          () async {
        // Act
        final result = await service.getOpenRouterApiKey();

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull(), '');
      });

      test('should handle empty OpenRouter API key', () async {
        // Arrange
        const apiKey = '';

        // Act
        final setResult = await service.setOpenRouterApiKey(apiKey);
        final getResult = await service.getOpenRouterApiKey();

        // Assert
        expect(setResult.isSuccess(), true);
        expect(getResult.isSuccess(), true);
        expect(getResult.getOrNull(), apiKey);
      });
    });

    group('Data Persistence', () {
      test('should persist data across service instances', () async {
        // Arrange
        const apiHost = 'https://persistent.test.com';
        const apiToken = 'persistent-token';
        final themeModeIndex = ThemeMode.dark.index;

        // Act - Set data with first service instance
        await service.setReadeckApiHost(apiHost);
        await service.setReadeckApiToken(apiToken);
        await service.setThemeMode(themeModeIndex);

        // Create new service instance
        final newService = SharedPreferencesService();

        // Get data with new service instance
        final hostResult = await newService.getReadeckApiHost();
        final tokenResult = await newService.getReadeckApiToken();
        final themeResult = await newService.getThemeMode();

        // Assert
        expect(hostResult.isSuccess(), true);
        expect(hostResult.getOrNull(), apiHost);

        expect(tokenResult.isSuccess(), true);
        expect(tokenResult.getOrNull(), apiToken);

        expect(themeResult.isSuccess(), true);
        expect(themeResult.getOrNull(), themeModeIndex);
      });
    });
  });
}
