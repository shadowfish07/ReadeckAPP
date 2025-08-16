import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/reading_stats/reading_stats_repository.dart';
import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';
import 'package:logger/logger.dart';
import 'package:readeck_app/main.dart';
import 'package:result_dart/result_dart.dart';

import 'bookmark_repository_test.mocks.dart';

@GenerateMocks([
  ReadeckApiClient,
  ReadingStatsRepository,
])
void main() {
  late MockReadeckApiClient mockReadeckApiClient;
  late MockReadingStatsRepository mockReadingStatsRepository;
  late BookmarkRepository bookmarkRepository;

  setUpAll(() {
    appLogger = Logger();
    provideDummy<ResultDart<List<Bookmark>, Exception>>(
      const Success([]),
    );
    // Provide dummy for ReadingStatsForView Result
    provideDummy<ResultDart<ReadingStatsForView, Exception>>(
      Failure(Exception('Dummy')),
    );
  });

  setUp(() {
    mockReadeckApiClient = MockReadeckApiClient();
    mockReadingStatsRepository = MockReadingStatsRepository();
    bookmarkRepository = BookmarkRepository(
      mockReadeckApiClient,
      mockReadingStatsRepository,
    );
  });

  tearDown(() {
    bookmarkRepository.dispose();
  });

  group('BookmarkRepository loadReadingBookmarks', () {
    test('should call API with correct parameters for reading bookmarks',
        () async {
      // Arrange
      final readingBookmarks = [
        Bookmark(
          id: '1',
          url: 'https://example.com/1',
          title: 'Reading Book 1',
          isArchived: false,
          isMarked: false,
          labels: [],
          created: DateTime.now(),
          readProgress: 25,
        ),
        Bookmark(
          id: '2',
          url: 'https://example.com/2',
          title: 'Reading Book 2',
          isArchived: false,
          isMarked: false,
          labels: [],
          created: DateTime.now(),
          readProgress: 75,
        ),
      ];

      when(mockReadeckApiClient.getBookmarks(
        readStatus: 'reading',
        isArchived: false,
        limit: 15,
        offset: 15,
      )).thenAnswer((_) async => Success(readingBookmarks));

      when(mockReadingStatsRepository.getReadingStats(any))
          .thenAnswer((_) async => Failure(Exception('No stats')));

      // Act
      final result = await bookmarkRepository.loadReadingBookmarks(
        limit: 15,
        page: 2,
      );

      // Assert
      expect(result.isSuccess(), true);
      expect(result.getOrNull()!.length, 2);
      verify(mockReadeckApiClient.getBookmarks(
        readStatus: 'reading',
        isArchived: false,
        limit: 15,
        offset: 15, // (page - 1) * limit = (2 - 1) * 15
      )).called(1);
    });

    test('should return empty list when API returns no reading bookmarks',
        () async {
      // Arrange
      when(mockReadeckApiClient.getBookmarks(
        readStatus: 'reading',
        isArchived: false,
        limit: 10,
        offset: 0,
      )).thenAnswer((_) async => const Success([]));

      // Act
      final result = await bookmarkRepository.loadReadingBookmarks();

      // Assert
      expect(result.isSuccess(), true);
      expect(result.getOrNull()!.isEmpty, true);
      verify(mockReadeckApiClient.getBookmarks(
        readStatus: 'reading',
        isArchived: false,
        limit: 10,
        offset: 0,
      )).called(1);
    });

    test('should return failure when API call fails', () async {
      // Arrange
      final exception = Exception('Network error');
      when(mockReadeckApiClient.getBookmarks(
        readStatus: anyNamed('readStatus'),
        isArchived: anyNamed('isArchived'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => Failure(exception));

      // Act
      final result = await bookmarkRepository.loadReadingBookmarks();

      // Assert
      expect(result.isError(), true);
      expect(result.exceptionOrNull(), exception);
    });

    test('should use default pagination parameters when not specified',
        () async {
      // Arrange
      when(mockReadeckApiClient.getBookmarks(
        readStatus: 'reading',
        isArchived: false,
        limit: 10,
        offset: 0,
      )).thenAnswer((_) async => const Success([]));

      // Act
      await bookmarkRepository.loadReadingBookmarks();

      // Assert
      verify(mockReadeckApiClient.getBookmarks(
        readStatus: 'reading',
        isArchived: false,
        limit: 10, // default limit
        offset: 0, // default offset for page 1
      )).called(1);
    });
  });
}
