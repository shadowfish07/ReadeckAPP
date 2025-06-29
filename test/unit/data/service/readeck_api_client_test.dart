import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';

import 'package:readeck_app/main.dart';
import 'package:readeck_app/utils/api_not_configured_exception.dart';
import 'package:readeck_app/utils/article_empty_exception.dart';
import 'package:readeck_app/utils/network_error_exception.dart';
import 'package:readeck_app/utils/resource_not_found_exception.dart';

import 'readeck_api_client_test.mocks.dart';

// 生成 Mock 类
@GenerateMocks([http.Client])
void main() {
  group('ReadeckApiClient Tests', () {
    late ReadeckApiClient apiClient;
    late MockClient mockHttpClient;
    const testHost = 'https://api.readeck.test';
    const testToken = 'test-token-123';

    setUp(() {
      // 初始化全局 appLogger
      appLogger = Logger();

      mockHttpClient = MockClient();
      apiClient =
          ReadeckApiClient(testHost, testToken, httpClient: mockHttpClient);
    });

    tearDown(() {
      // dispose will be called in individual tests if needed
    });

    group('Configuration Tests', () {
      test('should handle unconfigured API', () async {
        // Arrange
        final unconfiguredClient =
            ReadeckApiClient(null, null, httpClient: mockHttpClient);

        // Act
        final result = await unconfiguredClient.getBookmarks();

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull(), isA<ApiNotConfiguredException>());
      });

      test('should handle empty host configuration', () async {
        // Arrange
        final emptyHostClient =
            ReadeckApiClient('', testToken, httpClient: mockHttpClient);

        // Act
        final result = await emptyHostClient.getBookmarks();

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull(), isA<ApiNotConfiguredException>());
      });

      test('should handle empty token configuration', () async {
        // Arrange
        final emptyTokenClient =
            ReadeckApiClient(testHost, '', httpClient: mockHttpClient);

        // Act
        final result = await emptyTokenClient.getBookmarks();

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull(), isA<ApiNotConfiguredException>());
      });

      test('should update configuration successfully', () async {
        // Arrange
        final unconfiguredClient =
            ReadeckApiClient(null, null, httpClient: mockHttpClient);
        const newHost = 'https://new.api.test';
        const newToken = 'new-token-456';

        // Mock successful response
        when(mockHttpClient.get(
          Uri.parse('$newHost/api/bookmarks'),
          headers: {
            'Authorization': 'Bearer $newToken',
            'Content-Type': 'application/json',
          },
        )).thenAnswer((_) async => http.Response('[]', 200));

        // Act
        unconfiguredClient.updateConfig(newHost, newToken);
        final result = await unconfiguredClient.getBookmarks();

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull(), isA<List<Bookmark>>());
      });
    });

    group('getBookmarks Tests', () {
      test('should get bookmarks successfully', () async {
        // Arrange
        final mockBookmarks = [
          {
            'id': 'bookmark-1',
            'title': 'Test Bookmark 1',
            'url': 'https://example.com/1',
            'site_name': 'example.com',
            'description': 'Test description 1',
            'is_marked': false,
            'is_archived': false,
            'read_progress': 0,
            'labels': ['tech', 'flutter'],
            'created': '2024-01-01T00:00:00Z',
            'image_url': 'https://example.com/image1.jpg',
          },
          {
            'id': 'bookmark-2',
            'title': 'Test Bookmark 2',
            'url': 'https://example.com/2',
            'site_name': 'example.com',
            'description': 'Test description 2',
            'is_marked': true,
            'is_archived': false,
            'read_progress': 50,
            'labels': ['video'],
            'created': '2024-01-02T00:00:00Z',
            'image_url': 'https://example.com/image2.jpg',
          },
        ];

        when(mockHttpClient.get(
          Uri.parse('$testHost/api/bookmarks'),
          headers: {
            'Authorization': 'Bearer $testToken',
            'Content-Type': 'application/json',
          },
        )).thenAnswer(
            (_) async => http.Response(json.encode(mockBookmarks), 200));

        // Act
        final result = await apiClient.getBookmarks();

        // Assert
        expect(result.isSuccess(), true);
        final bookmarks = result.getOrNull()!;
        expect(bookmarks.length, 2);
        expect(bookmarks[0].id, 'bookmark-1');
        expect(bookmarks[0].title, 'Test Bookmark 1');
        expect(bookmarks[1].id, 'bookmark-2');
        expect(bookmarks[1].isMarked, true);
      });

      test('should handle query parameters correctly', () async {
        // Arrange
        when(mockHttpClient.get(
          Uri.parse(
              '$testHost/api/bookmarks?search=flutter&is_marked=true&limit=10'),
          headers: {
            'Authorization': 'Bearer $testToken',
            'Content-Type': 'application/json',
          },
        )).thenAnswer((_) async => http.Response('[]', 200));

        // Act
        final result = await apiClient.getBookmarks(
          search: 'flutter',
          isMarked: true,
          limit: 10,
        );

        // Assert
        expect(result.isSuccess(), true);
        verify(mockHttpClient.get(
          Uri.parse(
              '$testHost/api/bookmarks?search=flutter&is_marked=true&limit=10'),
          headers: {
            'Authorization': 'Bearer $testToken',
            'Content-Type': 'application/json',
          },
        )).called(1);
      });

      test('should handle multiple labels parameter', () async {
        // Arrange
        when(mockHttpClient.get(
          Uri.parse(
              '$testHost/api/bookmarks?labels=tech&labels=flutter&labels=mobile'),
          headers: {
            'Authorization': 'Bearer $testToken',
            'Content-Type': 'application/json',
          },
        )).thenAnswer((_) async => http.Response('[]', 200));

        // Act
        final result = await apiClient.getBookmarks(
          labels: ['tech', 'flutter', 'mobile'],
        );

        // Assert
        expect(result.isSuccess(), true);
      });

      test('should handle empty response', () async {
        // Arrange
        when(mockHttpClient.get(
          Uri.parse('$testHost/api/bookmarks'),
          headers: {
            'Authorization': 'Bearer $testToken',
            'Content-Type': 'application/json',
          },
        )).thenAnswer((_) async => http.Response('', 200));

        // Act
        final result = await apiClient.getBookmarks();

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull(), isA<NetworkErrorException>());
      });

      test('should handle invalid JSON response', () async {
        // Arrange
        when(mockHttpClient.get(
          Uri.parse('$testHost/api/bookmarks'),
          headers: {
            'Authorization': 'Bearer $testToken',
            'Content-Type': 'application/json',
          },
        )).thenAnswer((_) async => http.Response('invalid json', 200));

        // Act
        final result = await apiClient.getBookmarks();

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull(), isA<NetworkErrorException>());
      });

      test('should handle HTTP error status codes', () async {
        // Arrange
        when(mockHttpClient.get(
          Uri.parse('$testHost/api/bookmarks'),
          headers: {
            'Authorization': 'Bearer $testToken',
            'Content-Type': 'application/json',
          },
        )).thenAnswer((_) async => http.Response('Unauthorized', 401));

        // Act
        final result = await apiClient.getBookmarks();

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull(), isA<NetworkErrorException>());
      });

      test('should handle network exceptions', () async {
        // Arrange
        when(mockHttpClient.get(
          Uri.parse('$testHost/api/bookmarks'),
          headers: {
            'Authorization': 'Bearer $testToken',
            'Content-Type': 'application/json',
          },
        )).thenThrow(Exception('Network error'));

        // Act
        final result = await apiClient.getBookmarks();

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull(), isA<NetworkErrorException>());
      });
    });

    group('updateBookmark Tests', () {
      const bookmarkId = 'test-bookmark-1';

      test('should update bookmark successfully', () async {
        // Arrange
        final mockResponse = {
          'id': bookmarkId,
          'title': 'Updated Title',
          'is_marked': true,
        };

        when(mockHttpClient.patch(
          Uri.parse('$testHost/api/bookmarks/$bookmarkId'),
          headers: {
            'Authorization': 'Bearer $testToken',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'title': 'Updated Title',
            'is_marked': true,
          }),
        )).thenAnswer(
            (_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await apiClient.updateBookmark(
          bookmarkId,
          title: 'Updated Title',
          isMarked: true,
        );

        // Assert
        expect(result.isSuccess(), true);
        final response = result.getOrNull()!;
        expect(response['id'], bookmarkId);
        expect(response['title'], 'Updated Title');
        expect(response['is_marked'], true);
      });

      test('should validate read progress range', () async {
        // Act
        final result = await apiClient.updateBookmark(
          bookmarkId,
          readProgress: 150, // Invalid: > 100
        );

        // Assert
        expect(result.isError(), true);
        expect(
            result.exceptionOrNull().toString(), contains('阅读进度必须在 0-100 范围内'));
      });

      test('should require at least one update parameter', () async {
        // Act
        final result = await apiClient.updateBookmark(bookmarkId);

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull().toString(), contains('至少需要提供一个更新参数'));
      });

      test('should handle labels operations', () async {
        // Arrange
        when(mockHttpClient.patch(
          Uri.parse('$testHost/api/bookmarks/$bookmarkId'),
          headers: {
            'Authorization': 'Bearer $testToken',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'labels': ['tech', 'flutter'],
            'add_labels': ['mobile'],
            'remove_labels': ['old'],
          }),
        )).thenAnswer((_) async => http.Response('{}', 200));

        // Act
        final result = await apiClient.updateBookmark(
          bookmarkId,
          labels: ['tech', 'flutter'],
          addLabels: ['mobile'],
          removeLabels: ['old'],
        );

        // Assert
        expect(result.isSuccess(), true);
      });
    });

    group('getLabels Tests', () {
      test('should get labels successfully', () async {
        // Arrange
        final mockLabels = [
          {
            'name': 'tech',
            'count': 10,
            'href': '/api/labels/tech',
            'href_bookmarks': '/api/bookmarks?labels=tech',
          },
          {
            'name': 'flutter',
            'count': 5,
            'href': '/api/labels/flutter',
            'href_bookmarks': '/api/bookmarks?labels=flutter',
          },
        ];

        when(mockHttpClient.get(
          Uri.parse('$testHost/api/bookmarks/labels'),
          headers: {
            'Authorization': 'Bearer $testToken',
            'Content-Type': 'application/json',
          },
        )).thenAnswer((_) async => http.Response(json.encode(mockLabels), 200));

        // Act
        final result = await apiClient.getLabels();

        // Assert
        expect(result.isSuccess(), true);
        final labels = result.getOrNull()!;
        expect(labels.length, 2);
        expect(labels[0].name, 'tech');
        expect(labels[0].count, 10);
        expect(labels[1].name, 'flutter');
        expect(labels[1].count, 5);
      });

      test('should handle empty labels response', () async {
        // Arrange
        when(mockHttpClient.get(
          Uri.parse('$testHost/api/bookmarks/labels'),
          headers: {
            'Authorization': 'Bearer $testToken',
            'Content-Type': 'application/json',
          },
        )).thenAnswer((_) async => http.Response('[]', 200));

        // Act
        final result = await apiClient.getLabels();

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull()!.length, 0);
      });
    });

    group('getBookmarkArticle Tests', () {
      const bookmarkId = 'test-bookmark-1';

      test('should get bookmark article successfully', () async {
        // Arrange
        const articleContent =
            '<html><body><h1>Test Article</h1><p>Content</p></body></html>';

        when(mockHttpClient.get(
          Uri.parse('$testHost/api/bookmarks/$bookmarkId/article'),
          headers: {
            'Authorization': 'Bearer $testToken',
            'Accept': 'text/html',
          },
        )).thenAnswer((_) async => http.Response(articleContent, 200));

        // Act
        final result = await apiClient.getBookmarkArticle(bookmarkId);

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull(), articleContent);
      });

      test('should handle empty article content', () async {
        // Arrange
        when(mockHttpClient.get(
          Uri.parse('$testHost/api/bookmarks/$bookmarkId/article'),
          headers: {
            'Authorization': 'Bearer $testToken',
            'Accept': 'text/html',
          },
        )).thenAnswer((_) async => http.Response('', 200));

        // Act
        final result = await apiClient.getBookmarkArticle(bookmarkId);

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull(), isA<ArticleEmptyException>());
      });

      test('should handle bookmark not found', () async {
        // Arrange
        when(mockHttpClient.get(
          Uri.parse('$testHost/api/bookmarks/$bookmarkId/article'),
          headers: {
            'Authorization': 'Bearer $testToken',
            'Accept': 'text/html',
          },
        )).thenAnswer((_) async => http.Response('Not Found', 404));

        // Act
        final result = await apiClient.getBookmarkArticle(bookmarkId);

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull(), isA<ResourceNotFoundException>());
      });
    });

    group('deleteBookmark Tests', () {
      const bookmarkId = 'test-bookmark-1';

      test('should delete bookmark successfully', () async {
        // Arrange
        when(mockHttpClient.delete(
          Uri.parse('$testHost/api/bookmarks/$bookmarkId'),
          headers: {
            'Authorization': 'Bearer $testToken',
            'Content-Type': 'application/json',
          },
        )).thenAnswer((_) async => http.Response('', 204));

        // Act
        final result = await apiClient.deleteBookmark(bookmarkId);

        // Assert
        expect(result.isSuccess(), true);
      });

      test('should handle delete failure', () async {
        // Arrange
        when(mockHttpClient.delete(
          Uri.parse('$testHost/api/bookmarks/$bookmarkId'),
          headers: {
            'Authorization': 'Bearer $testToken',
            'Content-Type': 'application/json',
          },
        )).thenAnswer((_) async => http.Response('Internal Server Error', 500));

        // Act
        final result = await apiClient.deleteBookmark(bookmarkId);

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull(), isA<NetworkErrorException>());
      });
    });

    group('Resource Management Tests', () {
      test('should dispose HTTP client', () {
        // Act
        apiClient.dispose();

        // Assert
        verify(mockHttpClient.close()).called(1);
      });
    });
  });
}
