import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:readeck_app/data/service/shared_preference_service.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';

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

    group('Reading Stats Operations', () {
      test('should set and get reading stats successfully', () async {
        // Arrange
        const bookmarkId = 'bookmark-123';
        const stats = ReadingStats(
          readableCharCount: 1500,
          estimatedReadingTimeMinutes: 6.0,
        );

        // Act
        final setResult = await service.setReadingStats(bookmarkId, stats);
        final getResult = await service.getReadingStats(bookmarkId);

        // Assert
        expect(setResult.isSuccess(), true);
        expect(getResult.isSuccess(), true);

        final retrievedStats = getResult.getOrNull()!;
        expect(retrievedStats.readableCharCount, stats.readableCharCount);
        expect(retrievedStats.estimatedReadingTimeMinutes,
            stats.estimatedReadingTimeMinutes);
      });

      test('should handle zero reading stats', () async {
        // Arrange
        const bookmarkId = 'bookmark-zero';
        const stats = ReadingStats(
          readableCharCount: 0,
          estimatedReadingTimeMinutes: 0.0,
        );

        // Act
        final setResult = await service.setReadingStats(bookmarkId, stats);
        final getResult = await service.getReadingStats(bookmarkId);

        // Assert
        expect(setResult.isSuccess(), true);
        expect(getResult.isSuccess(), true);

        final retrievedStats = getResult.getOrNull()!;
        expect(retrievedStats.readableCharCount, 0);
        expect(retrievedStats.estimatedReadingTimeMinutes, 0.0);
      });

      test('should handle large reading stats', () async {
        // Arrange
        const bookmarkId = 'bookmark-large';
        const stats = ReadingStats(
          readableCharCount: 999999,
          estimatedReadingTimeMinutes: 4166.66,
        );

        // Act
        final setResult = await service.setReadingStats(bookmarkId, stats);
        final getResult = await service.getReadingStats(bookmarkId);

        // Assert
        expect(setResult.isSuccess(), true);
        expect(getResult.isSuccess(), true);

        final retrievedStats = getResult.getOrNull()!;
        expect(retrievedStats.readableCharCount, stats.readableCharCount);
        expect(retrievedStats.estimatedReadingTimeMinutes,
            stats.estimatedReadingTimeMinutes);
      });

      test('should handle decimal reading time', () async {
        // Arrange
        const bookmarkId = 'bookmark-decimal';
        const stats = ReadingStats(
          readableCharCount: 750,
          estimatedReadingTimeMinutes: 3.14159,
        );

        // Act
        final setResult = await service.setReadingStats(bookmarkId, stats);
        final getResult = await service.getReadingStats(bookmarkId);

        // Assert
        expect(setResult.isSuccess(), true);
        expect(getResult.isSuccess(), true);

        final retrievedStats = getResult.getOrNull()!;
        expect(retrievedStats.readableCharCount, stats.readableCharCount);
        expect(retrievedStats.estimatedReadingTimeMinutes,
            closeTo(stats.estimatedReadingTimeMinutes, 0.00001));
      });

      test('should return failure when reading stats not found', () async {
        // Arrange
        const bookmarkId = 'non-existent-bookmark';

        // Act
        final result = await service.getReadingStats(bookmarkId);

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull()!.toString(), contains('未找到书签的阅读统计数据'));
      });

      test('should overwrite existing reading stats', () async {
        // Arrange
        const bookmarkId = 'bookmark-overwrite';
        const initialStats = ReadingStats(
          readableCharCount: 1000,
          estimatedReadingTimeMinutes: 4.0,
        );
        const updatedStats = ReadingStats(
          readableCharCount: 2000,
          estimatedReadingTimeMinutes: 8.0,
        );

        // Act
        await service.setReadingStats(bookmarkId, initialStats);
        final setResult =
            await service.setReadingStats(bookmarkId, updatedStats);
        final getResult = await service.getReadingStats(bookmarkId);

        // Assert
        expect(setResult.isSuccess(), true);
        expect(getResult.isSuccess(), true);

        final retrievedStats = getResult.getOrNull()!;
        expect(
            retrievedStats.readableCharCount, updatedStats.readableCharCount);
        expect(retrievedStats.estimatedReadingTimeMinutes,
            updatedStats.estimatedReadingTimeMinutes);
      });

      test('should handle multiple bookmarks with different stats', () async {
        // Arrange
        const bookmark1 = 'bookmark-1';
        const bookmark2 = 'bookmark-2';
        const stats1 = ReadingStats(
          readableCharCount: 1000,
          estimatedReadingTimeMinutes: 4.0,
        );
        const stats2 = ReadingStats(
          readableCharCount: 2000,
          estimatedReadingTimeMinutes: 8.0,
        );

        // Act
        await service.setReadingStats(bookmark1, stats1);
        await service.setReadingStats(bookmark2, stats2);

        final result1 = await service.getReadingStats(bookmark1);
        final result2 = await service.getReadingStats(bookmark2);

        // Assert
        expect(result1.isSuccess(), true);
        expect(result2.isSuccess(), true);

        final retrievedStats1 = result1.getOrNull()!;
        final retrievedStats2 = result2.getOrNull()!;

        expect(retrievedStats1.readableCharCount, stats1.readableCharCount);
        expect(retrievedStats1.estimatedReadingTimeMinutes,
            stats1.estimatedReadingTimeMinutes);

        expect(retrievedStats2.readableCharCount, stats2.readableCharCount);
        expect(retrievedStats2.estimatedReadingTimeMinutes,
            stats2.estimatedReadingTimeMinutes);
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
