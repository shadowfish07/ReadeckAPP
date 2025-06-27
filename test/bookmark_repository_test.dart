import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../lib/data/repository/bookmark/bookmark_repository.dart';
import '../lib/data/api/readeck_api_client.dart';
import '../lib/data/api/open_router_api_client.dart';
import '../lib/data/database/database_service.dart';
import '../lib/data/models/bookmark.dart';
import '../lib/core/types/async_result.dart';
import '../lib/core/types/result.dart';

// Generate mocks for dependencies
@GenerateMocks([
  ReadeckApiClient,
  DatabaseService,
  OpenRouterApiClient,
])
import 'bookmark_repository_test.mocks.dart';

void main() {
  group('BookmarkRepository', () {
    late BookmarkRepository repository;
    late MockReadeckApiClient mockReadeckApiClient;
    late MockDatabaseService mockDatabaseService;
    late MockOpenRouterApiClient mockOpenRouterApiClient;

    setUp(() {
      mockReadeckApiClient = MockReadeckApiClient();
      mockDatabaseService = MockDatabaseService();
      mockOpenRouterApiClient = MockOpenRouterApiClient();
      repository = BookmarkRepository(
        mockReadeckApiClient,
        mockDatabaseService,
        mockOpenRouterApiClient,
      );
    });

    tearDown(() {
      reset(mockReadeckApiClient);
      reset(mockDatabaseService);
      reset(mockOpenRouterApiClient);
    });

    group('getBookmarksByIds', () {
      test('should return bookmarks when API call succeeds', () async {
        // Arrange
        final bookmarkIds = ['1', '2', '3'];
        final expectedBookmarks = [
          Bookmark(
            id: '1',
            title: 'Test Bookmark 1',
            url: 'https://example1.com',
            description: 'Description 1',
            tags: ['tag1', 'tag2'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isArchived: false,
          ),
          Bookmark(
            id: '2',
            title: 'Test Bookmark 2',
            url: 'https://example2.com',
            description: 'Description 2',
            tags: ['tag3'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isArchived: false,
          ),
        ];

        when(mockReadeckApiClient.getBookmarks(ids: bookmarkIds))
            .thenAnswer((_) async => Result.success(expectedBookmarks));

        // Act
        final result = await repository.getBookmarksByIds(bookmarkIds);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, hasLength(2));
        expect(result.data?.first.id, equals('1'));
        verify(mockReadeckApiClient.getBookmarks(ids: bookmarkIds)).called(1);
      });

      test('should return error when API call fails', () async {
        // Arrange
        final bookmarkIds = ['1', '2'];
        final expectedError = Exception('Network error');

        when(mockReadeckApiClient.getBookmarks(ids: bookmarkIds))
            .thenAnswer((_) async => Result.failure(expectedError));

        // Act
        final result = await repository.getBookmarksByIds(bookmarkIds);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, equals(expectedError));
        verify(mockReadeckApiClient.getBookmarks(ids: bookmarkIds)).called(1);
      });

      test('should handle empty ID list', () async {
        // Arrange
        final emptyIds = <String>[];

        when(mockReadeckApiClient.getBookmarks(ids: emptyIds))
            .thenAnswer((_) async => Result.success([]));

        // Act
        final result = await repository.getBookmarksByIds(emptyIds);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
        verify(mockReadeckApiClient.getBookmarks(ids: emptyIds)).called(1);
      });

      test('should handle null values in ID list', () async {
        // Arrange
        final idsWithNull = ['1', null, '3'];

        // Act & Assert
        expect(() => repository.getBookmarksByIds(idsWithNull.cast<String>()),
            throwsA(isA<ArgumentError>()));
      });

      test('should handle very large ID list', () async {
        // Arrange
        final largeIdList = List.generate(1000, (index) => index.toString());
        final expectedBookmarks = <Bookmark>[];

        when(mockReadeckApiClient.getBookmarks(ids: largeIdList))
            .thenAnswer((_) async => Result.success(expectedBookmarks));

        // Act
        final result = await repository.getBookmarksByIds(largeIdList);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
        verify(mockReadeckApiClient.getBookmarks(ids: largeIdList)).called(1);
      });

      test('should handle API timeout', () async {
        // Arrange
        final bookmarkIds = ['1', '2'];

        when(mockReadeckApiClient.getBookmarks(ids: bookmarkIds))
            .thenAnswer((_) async {
          await Future.delayed(Duration(seconds: 30)); // Simulate timeout
          return Result.failure(Exception('Timeout'));
        });

        // Act & Assert
        expect(() => repository.getBookmarksByIds(bookmarkIds).timeout(Duration(seconds: 5)),
            throwsA(isA<Exception>()));
      });

      test('should handle duplicate IDs in list', () async {
        // Arrange
        final duplicateIds = ['1', '2', '1', '3', '2'];
        final expectedBookmarks = [
          Bookmark(
            id: '1',
            title: 'Bookmark 1',
            url: 'https://example1.com',
            description: 'Description',
            tags: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isArchived: false,
          ),
        ];

        when(mockReadeckApiClient.getBookmarks(ids: duplicateIds))
            .thenAnswer((_) async => Result.success(expectedBookmarks));

        // Act
        final result = await repository.getBookmarksByIds(duplicateIds);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockReadeckApiClient.getBookmarks(ids: duplicateIds)).called(1);
      });
    });

    group('getUnarchivedBookmarks', () {
      test('should return unarchived bookmarks with default parameters', () async {
        // Arrange
        final expectedBookmarks = [
          Bookmark(
            id: '1',
            title: 'Active Bookmark',
            url: 'https://active.com',
            description: 'Active description',
            tags: ['active'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isArchived: false,
          ),
        ];

        when(mockReadeckApiClient.getBookmarks(
          isArchived: false,
          limit: 10,
          offset: 0,
        )).thenAnswer((_) async => Result.success(expectedBookmarks));

        // Act
        final result = await repository.getUnarchivedBookmarks();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, hasLength(1));
        expect(result.data?.first.isArchived, isFalse);
        verify(mockReadeckApiClient.getBookmarks(
          isArchived: false,
          limit: 10,
          offset: 0,
        )).called(1);
      });

      test('should handle custom limit and page parameters', () async {
        // Arrange
        final limit = 25;
        final page = 3;
        final expectedOffset = (page - 1) * limit; // 50

        when(mockReadeckApiClient.getBookmarks(
          isArchived: false,
          limit: limit,
          offset: expectedOffset,
        )).thenAnswer((_) async => Result.success([]));

        // Act
        final result = await repository.getUnarchivedBookmarks(
          limit: limit,
          page: page,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockReadeckApiClient.getBookmarks(
          isArchived: false,
          limit: limit,
          offset: expectedOffset,
        )).called(1);
      });

      test('should handle zero limit parameter', () async {
        // Arrange & Act & Assert
        expect(() => repository.getUnarchivedBookmarks(limit: 0),
            throwsA(isA<ArgumentError>()));
      });

      test('should handle negative limit parameter', () async {
        // Arrange & Act & Assert
        expect(() => repository.getUnarchivedBookmarks(limit: -5),
            throwsA(isA<ArgumentError>()));
      });

      test('should handle zero page parameter', () async {
        // Arrange & Act & Assert
        expect(() => repository.getUnarchivedBookmarks(page: 0),
            throwsA(isA<ArgumentError>()));
      });

      test('should handle negative page parameter', () async {
        // Arrange & Act & Assert
        expect(() => repository.getUnarchivedBookmarks(page: -1),
            throwsA(isA<ArgumentError>()));
      });

      test('should handle API error for unarchived bookmarks', () async {
        // Arrange
        final apiError = Exception('Server error');

        when(mockReadeckApiClient.getBookmarks(
          isArchived: false,
          limit: 10,
          offset: 0,
        )).thenAnswer((_) async => Result.failure(apiError));

        // Act
        final result = await repository.getUnarchivedBookmarks();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, equals(apiError));
      });

      test('should handle very large limit parameter', () async {
        // Arrange
        final veryLargeLimit = 10000;

        when(mockReadeckApiClient.getBookmarks(
          isArchived: false,
          limit: veryLargeLimit,
          offset: 0,
        )).thenAnswer((_) async => Result.success([]));

        // Act
        final result = await repository.getUnarchivedBookmarks(limit: veryLargeLimit);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockReadeckApiClient.getBookmarks(
          isArchived: false,
          limit: veryLargeLimit,
          offset: 0,
        )).called(1);
      });

      test('should handle very large page parameter', () async {
        // Arrange
        final veryLargePage = 1000000;
        final limit = 10;
        final expectedOffset = (veryLargePage - 1) * limit;

        when(mockReadeckApiClient.getBookmarks(
          isArchived: false,
          limit: limit,
          offset: expectedOffset,
        )).thenAnswer((_) async => Result.success([]));

        // Act
        final result = await repository.getUnarchivedBookmarks(
          limit: limit,
          page: veryLargePage,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockReadeckApiClient.getBookmarks(
          isArchived: false,
          limit: limit,
          offset: expectedOffset,
        )).called(1);
      });

      test('should return empty list when no unarchived bookmarks exist', () async {
        // Arrange
        when(mockReadeckApiClient.getBookmarks(
          isArchived: false,
          limit: 10,
          offset: 0,
        )).thenAnswer((_) async => Result.success([]));

        // Act
        final result = await repository.getUnarchivedBookmarks();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle API client throwing unexpected exceptions', () async {
        // Arrange
        when(mockReadeckApiClient.getBookmarks(ids: any))
            .thenThrow(UnimplementedError('Unexpected error'));

        // Act & Assert
        expect(() => repository.getBookmarksByIds(['1']),
            throwsA(isA<UnimplementedError>()));
      });

      test('should handle malformed bookmark data from API', () async {
        // Arrange
        when(mockReadeckApiClient.getBookmarks(ids: any))
            .thenAnswer((_) async => Result.success(null)); // Malformed response

        // Act
        final result = await repository.getBookmarksByIds(['1']);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });

      test('should handle concurrent requests properly', () async {
        // Arrange
        final ids1 = ['1', '2'];
        final ids2 = ['3', '4'];
        final bookmarks1 = [
          Bookmark(
            id: '1',
            title: 'Bookmark 1',
            url: 'https://example1.com',
            description: 'Description 1',
            tags: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isArchived: false,
          ),
        ];
        final bookmarks2 = [
          Bookmark(
            id: '3',
            title: 'Bookmark 3',
            url: 'https://example3.com',
            description: 'Description 3',
            tags: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isArchived: false,
          ),
        ];

        when(mockReadeckApiClient.getBookmarks(ids: ids1))
            .thenAnswer((_) async => Result.success(bookmarks1));
        when(mockReadeckApiClient.getBookmarks(ids: ids2))
            .thenAnswer((_) async => Result.success(bookmarks2));

        // Act
        final futures = [
          repository.getBookmarksByIds(ids1),
          repository.getBookmarksByIds(ids2),
        ];
        final results = await Future.wait(futures);

        // Assert
        expect(results[0].isSuccess, isTrue);
        expect(results[1].isSuccess, isTrue);
        expect(results[0].data?.first.id, equals('1'));
        expect(results[1].data?.first.id, equals('3'));
        verify(mockReadeckApiClient.getBookmarks(ids: ids1)).called(1);
        verify(mockReadeckApiClient.getBookmarks(ids: ids2)).called(1);
      });

      test('should handle network connectivity issues', () async {
        // Arrange
        when(mockReadeckApiClient.getBookmarks(ids: any))
            .thenAnswer((_) async => Result.failure(
                Exception('Network connectivity error')));

        // Act
        final result = await repository.getBookmarksByIds(['1']);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error.toString(), contains('Network connectivity'));
      });

      test('should handle API rate limiting', () async {
        // Arrange
        when(mockReadeckApiClient.getBookmarks(ids: any))
            .thenAnswer((_) async => Result.failure(
                Exception('Rate limit exceeded')));

        // Act
        final result = await repository.getBookmarksByIds(['1']);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error.toString(), contains('Rate limit'));
      });

      test('should handle authentication failures', () async {
        // Arrange
        when(mockReadeckApiClient.getBookmarks(ids: any))
            .thenAnswer((_) async => Result.failure(
                Exception('Authentication failed')));

        // Act
        final result = await repository.getBookmarksByIds(['1']);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error.toString(), contains('Authentication'));
      });

      test('should handle server internal errors', () async {
        // Arrange
        when(mockReadeckApiClient.getBookmarks(ids: any))
            .thenAnswer((_) async => Result.failure(
                Exception('Internal server error')));

        // Act
        final result = await repository.getBookmarksByIds(['1']);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error.toString(), contains('Internal server'));
      });
    });

    group('Performance and Stress Tests', () {
      test('should handle large number of concurrent requests', () async {
        // Arrange
        const numberOfRequests = 100;
        final bookmarks = [
          Bookmark(
            id: '1',
            title: 'Test Bookmark',
            url: 'https://example.com',
            description: 'Description',
            tags: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isArchived: false,
          ),
        ];

        when(mockReadeckApiClient.getBookmarks(ids: any))
            .thenAnswer((_) async => Result.success(bookmarks));

        // Act
        final futures = List.generate(numberOfRequests,
            (_) => repository.getBookmarksByIds(['1']));
        final results = await Future.wait(futures);

        // Assert
        expect(results, hasLength(numberOfRequests));
        expect(results.every((result) => result.isSuccess), isTrue);
        verify(mockReadeckApiClient.getBookmarks(ids: any))
            .called(numberOfRequests);
      });

      test('should handle memory-intensive bookmark data', () async {
        // Arrange
        final largeBookmark = Bookmark(
          id: '1',
          title: 'Large Bookmark',
          url: 'https://example.com',
          description: 'A' * 10000, // Large description
          tags: List.generate(1000, (index) => 'tag$index'), // Many tags
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isArchived: false,
        );

        when(mockReadeckApiClient.getBookmarks(ids: any))
            .thenAnswer((_) async => Result.success([largeBookmark]));

        // Act
        final result = await repository.getBookmarksByIds(['1']);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data?.first.description.length, equals(10000));
        expect(result.data?.first.tags, hasLength(1000));
      });
    });

    group('Input Validation', () {
      test('should validate bookmark IDs format', () async {
        // Arrange
        final invalidIds = ['', '   ', '\n', '\t'];

        // Act & Assert
        expect(() => repository.getBookmarksByIds(invalidIds),
            throwsA(isA<ArgumentError>()));
      });

      test('should handle special characters in bookmark IDs', () async {
        // Arrange
        final specialCharIds = ['bookmark-1', 'bookmark_2', 'bookmark.3', 'bookmark@4'];

        when(mockReadeckApiClient.getBookmarks(ids: specialCharIds))
            .thenAnswer((_) async => Result.success([]));

        // Act
        final result = await repository.getBookmarksByIds(specialCharIds);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockReadeckApiClient.getBookmarks(ids: specialCharIds)).called(1);
      });

      test('should handle unicode characters in bookmark IDs', () async {
        // Arrange
        final unicodeIds = ['📚bookmark1', '🔖bookmark2', '中文bookmark3'];

        when(mockReadeckApiClient.getBookmarks(ids: unicodeIds))
            .thenAnswer((_) async => Result.success([]));

        // Act
        final result = await repository.getBookmarksByIds(unicodeIds);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockReadeckApiClient.getBookmarks(ids: unicodeIds)).called(1);
      });

      test('should handle extremely long bookmark IDs', () async {
        // Arrange
        final longId = 'a' * 1000; // Very long ID
        final longIds = [longId];

        when(mockReadeckApiClient.getBookmarks(ids: longIds))
            .thenAnswer((_) async => Result.success([]));

        // Act
        final result = await repository.getBookmarksByIds(longIds);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockReadeckApiClient.getBookmarks(ids: longIds)).called(1);
      });
    });

    group('Repository State Management', () {
      test('should maintain consistent state across multiple calls', () async {
        // Arrange
        final bookmarks = [
          Bookmark(
            id: '1',
            title: 'Consistent Bookmark',
            url: 'https://consistent.com',
            description: 'Description',
            tags: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isArchived: false,
          ),
        ];

        when(mockReadeckApiClient.getBookmarks(ids: any))
            .thenAnswer((_) async => Result.success(bookmarks));
        when(mockReadeckApiClient.getBookmarks(
          isArchived: false,
          limit: 10,
          offset: 0,
        )).thenAnswer((_) async => Result.success(bookmarks));

        // Act
        final result1 = await repository.getBookmarksByIds(['1']);
        final result2 = await repository.getUnarchivedBookmarks();

        // Assert
        expect(result1.isSuccess, isTrue);
        expect(result2.isSuccess, isTrue);
        // Repository should not maintain internal state between calls
        verifyInOrder([
          mockReadeckApiClient.getBookmarks(ids: any),
          mockReadeckApiClient.getBookmarks(
            isArchived: false,
            limit: 10,
            offset: 0,
          ),
        ]);
      });

      test('should not cache results between calls', () async {
        // Arrange
        final firstCallBookmarks = [
          Bookmark(
            id: '1',
            title: 'First Call',
            url: 'https://first.com',
            description: 'Description',
            tags: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isArchived: false,
          ),
        ];
        final secondCallBookmarks = [
          Bookmark(
            id: '1',
            title: 'Second Call',
            url: 'https://second.com',
            description: 'Description',
            tags: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isArchived: false,
          ),
        ];

        when(mockReadeckApiClient.getBookmarks(ids: ['1']))
            .thenAnswer((_) async => Result.success(firstCallBookmarks))
            .thenAnswer((_) async => Result.success(secondCallBookmarks));

        // Act
        final result1 = await repository.getBookmarksByIds(['1']);
        final result2 = await repository.getBookmarksByIds(['1']);

        // Assert
        expect(result1.data?.first.title, equals('First Call'));
        expect(result2.data?.first.title, equals('Second Call'));
        verify(mockReadeckApiClient.getBookmarks(ids: ['1'])).called(2);
      });
    });
  });
}