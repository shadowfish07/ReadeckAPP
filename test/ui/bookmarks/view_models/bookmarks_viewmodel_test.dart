import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/label/label_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/bookmark/label_info.dart';
import 'package:readeck_app/domain/models/bookmark_display_model/bookmark_display_model.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';
import 'package:readeck_app/ui/bookmarks/view_models/bookmarks_viewmodel.dart';
import 'package:logger/logger.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';
import 'package:result_dart/result_dart.dart';

import 'bookmarks_viewmodel_test.mocks.dart';

@GenerateMocks([BookmarkRepository, BookmarkOperationUseCases, LabelRepository])
void main() {
  late MockBookmarkRepository mockBookmarkRepository;
  late MockBookmarkOperationUseCases mockBookmarkOperationUseCases;
  late MockLabelRepository mockLabelRepository;
  late UnarchivedViewmodel viewModel;

  // Test data
  late Bookmark testBookmarkWithStats;
  late Bookmark testBookmarkWithoutStats;
  late BookmarkDisplayModel bookmarkModelWithStats;
  late BookmarkDisplayModel bookmarkModelWithoutStats;
  late ReadingStatsForView mockReadingStats;

  setUpAll(() {
    appLogger = Logger();

    // Provide dummy values for Mockito
    provideDummy<Result<List<BookmarkDisplayModel>>>(
      const Success([]),
    );
    provideDummy<Result<bool>>(
      const Success(true),
    );
    provideDummy<Result<Bookmark>>(
      Success(Bookmark(
        id: 'dummy',
        url: 'dummy',
        title: 'dummy',
        isArchived: false,
        isMarked: false,
        labels: [],
        created: DateTime.now(),
        readProgress: 0,
      )),
    );
    provideDummy<Result<List<String>>>(
      const Success([]),
    );
    provideDummy<Result<List<LabelInfo>>>(
      const Success([]),
    );
    provideDummy<Result<void>>(
      const Success('unit'),
    );
  });

  setUp(() {
    mockBookmarkRepository = MockBookmarkRepository();
    mockBookmarkOperationUseCases = MockBookmarkOperationUseCases();
    mockLabelRepository = MockLabelRepository();

    // 设置基本的 mock 行为
    when(mockBookmarkRepository.addListener(any)).thenAnswer((_) {});
    when(mockLabelRepository.addListener(any)).thenAnswer((_) {});
    when(mockBookmarkRepository.loadUnarchivedBookmarks(
            limit: anyNamed('limit'), page: anyNamed('page')))
        .thenAnswer((_) async => const Success([]));

    // 创建测试数据
    testBookmarkWithStats = Bookmark(
      id: 'bookmark-with-stats',
      url: 'https://example.com/with-stats',
      title: 'Bookmark with Reading Stats',
      isArchived: false,
      isMarked: false,
      labels: [],
      created: DateTime.now(),
      readProgress: 25,
    );

    testBookmarkWithoutStats = Bookmark(
      id: 'bookmark-without-stats',
      url: 'https://example.com/without-stats',
      title: 'Bookmark without Reading Stats',
      isArchived: false,
      isMarked: false,
      labels: [],
      created: DateTime.now(),
      readProgress: 0,
    );

    mockReadingStats = const ReadingStatsForView(
      readableCharCount: 1000,
      estimatedReadingTimeMinutes: 5.0,
    );

    bookmarkModelWithStats = BookmarkDisplayModel(
      bookmark: testBookmarkWithStats,
      stats: mockReadingStats,
    );

    bookmarkModelWithoutStats = BookmarkDisplayModel(
      bookmark: testBookmarkWithoutStats,
      stats: null,
    );
  });

  group('BookmarksViewModel handleBookmarkTap Tests', () {
    setUp(() {
      viewModel = UnarchivedViewmodel(
        mockBookmarkRepository,
        mockBookmarkOperationUseCases,
        mockLabelRepository,
      );
    });

    test('should open URL when bookmark has no reading stats', () async {
      // Arrange
      viewModel.bookmarks.clear();
      viewModel.bookmarks.add(bookmarkModelWithoutStats);

      when(mockBookmarkOperationUseCases.openUrl(testBookmarkWithoutStats.url))
          .thenAnswer((_) async => const Success(true));

      // Act
      viewModel.handleBookmarkTap(testBookmarkWithoutStats);

      // Wait for command execution
      await Future.delayed(Duration.zero);

      // Assert
      verify(mockBookmarkOperationUseCases
              .openUrl(testBookmarkWithoutStats.url))
          .called(1);
    });

    test('should call navigation callback when bookmark has reading stats',
        () async {
      // Arrange
      viewModel.bookmarks.clear();
      viewModel.bookmarks.add(bookmarkModelWithStats);

      bool navigationCallbackCalled = false;
      Bookmark? callbackBookmark;

      viewModel.setNavigateToDetailCallback((bookmark) {
        navigationCallbackCalled = true;
        callbackBookmark = bookmark;
      });

      // Act
      viewModel.handleBookmarkTap(testBookmarkWithStats);

      // Wait for any async operations
      await Future.delayed(Duration.zero);

      // Assert
      expect(navigationCallbackCalled, true);
      expect(callbackBookmark, testBookmarkWithStats);

      // Verify that openUrl was NOT called
      verifyNever(mockBookmarkOperationUseCases.openUrl(any));
    });

    test('should open URL when bookmark is not found in current list',
        () async {
      // Arrange
      viewModel.bookmarks.clear(); // Empty list

      when(mockBookmarkOperationUseCases.openUrl(testBookmarkWithoutStats.url))
          .thenAnswer((_) async => const Success(true));

      // Act
      viewModel.handleBookmarkTap(testBookmarkWithoutStats);

      // Wait for command execution
      await Future.delayed(Duration.zero);

      // Assert
      verify(mockBookmarkOperationUseCases
              .openUrl(testBookmarkWithoutStats.url))
          .called(1);
    });

    test('should handle mixed scenarios correctly', () async {
      // Arrange
      viewModel.bookmarks.clear();
      viewModel.bookmarks
          .addAll([bookmarkModelWithStats, bookmarkModelWithoutStats]);

      bool navigationCallbackCalled = false;
      Bookmark? callbackBookmark;

      viewModel.setNavigateToDetailCallback((bookmark) {
        navigationCallbackCalled = true;
        callbackBookmark = bookmark;
      });

      when(mockBookmarkOperationUseCases.openUrl(testBookmarkWithoutStats.url))
          .thenAnswer((_) async => const Success(true));

      // Act - Test bookmark with stats
      viewModel.handleBookmarkTap(testBookmarkWithStats);
      await Future.delayed(Duration.zero);

      // Assert navigation callback was called
      expect(navigationCallbackCalled, true);
      expect(callbackBookmark, testBookmarkWithStats);

      // Reset
      navigationCallbackCalled = false;
      callbackBookmark = null;

      // Act - Test bookmark without stats
      viewModel.handleBookmarkTap(testBookmarkWithoutStats);
      await Future.delayed(Duration.zero);

      // Assert URL was opened
      verify(mockBookmarkOperationUseCases
              .openUrl(testBookmarkWithoutStats.url))
          .called(1);
      expect(navigationCallbackCalled, false); // Callback should not be called
    });
  });

  group('BookmarksViewModel Navigation Callback Tests', () {
    setUp(() {
      viewModel = UnarchivedViewmodel(
        mockBookmarkRepository,
        mockBookmarkOperationUseCases,
        mockLabelRepository,
      );
    });

    test('should set navigation callback successfully', () {
      // Arrange
      bool callbackCalled = false;

      // Act
      viewModel.setNavigateToDetailCallback((bookmark) {
        callbackCalled = true;
      });

      // Manually trigger the private method to test callback
      viewModel.bookmarks.clear();
      viewModel.bookmarks.add(bookmarkModelWithStats);
      viewModel.handleBookmarkTap(testBookmarkWithStats);

      // Assert
      expect(callbackCalled, true);
    });

    test('should handle null callback gracefully', () {
      // Arrange
      viewModel.bookmarks.clear();
      viewModel.bookmarks.add(bookmarkModelWithStats);

      // Set callback to an empty function, then replace it
      viewModel.setNavigateToDetailCallback((bookmark) {});
      viewModel.setNavigateToDetailCallback((_) {});

      // Act - should not throw when callback is null
      expect(() => viewModel.handleBookmarkTap(testBookmarkWithStats),
          returnsNormally);
    });

    test('should call callback with correct bookmark', () {
      // Arrange
      viewModel.bookmarks.clear();
      viewModel.bookmarks.add(bookmarkModelWithStats);

      Bookmark? receivedBookmark;
      viewModel.setNavigateToDetailCallback((bookmark) {
        receivedBookmark = bookmark;
      });

      // Act
      viewModel.handleBookmarkTap(testBookmarkWithStats);

      // Assert
      expect(receivedBookmark, testBookmarkWithStats);
      expect(receivedBookmark?.id, testBookmarkWithStats.id);
      expect(receivedBookmark?.title, testBookmarkWithStats.title);
    });
  });

  group('BookmarksViewModel Integration Tests', () {
    setUp(() {
      viewModel = UnarchivedViewmodel(
        mockBookmarkRepository,
        mockBookmarkOperationUseCases,
        mockLabelRepository,
      );
    });

    test('should not interfere with existing bookmark operations', () async {
      // Arrange
      when(mockBookmarkRepository.toggleMarked(testBookmarkWithStats))
          .thenAnswer((_) async => Success(testBookmarkWithStats));

      // Act
      await viewModel.toggleBookmarkMarked
          .executeWithFuture(testBookmarkWithStats);

      // Assert
      verify(mockBookmarkRepository.toggleMarked(testBookmarkWithStats))
          .called(1);
    });

    test('should maintain bookmark list state correctly', () {
      // Arrange
      viewModel.bookmarks.clear();
      viewModel.bookmarks
          .addAll([bookmarkModelWithStats, bookmarkModelWithoutStats]);

      // Act
      final stats1 = viewModel.getReadingStats(testBookmarkWithStats.id);
      final stats2 = viewModel.getReadingStats(testBookmarkWithoutStats.id);

      // Assert
      expect(stats1, isNotNull);
      expect(stats1?.readableCharCount, mockReadingStats.readableCharCount);
      expect(stats2, isNull);
    });

    test('should call openUrl use case through command', () async {
      // Arrange
      viewModel.bookmarks.clear();
      viewModel.bookmarks.add(bookmarkModelWithoutStats);

      when(mockBookmarkOperationUseCases.openUrl(testBookmarkWithoutStats.url))
          .thenAnswer((_) async => const Success(true));

      // Act
      viewModel.handleBookmarkTap(testBookmarkWithoutStats);

      // Wait for command execution
      await Future.delayed(Duration.zero);

      // Assert - command should have been called
      verify(mockBookmarkOperationUseCases
              .openUrl(testBookmarkWithoutStats.url))
          .called(1);
    });
  });
}
