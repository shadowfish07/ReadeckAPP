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

    // 设置Repository的bookmarks getter
    when(mockBookmarkRepository.bookmarks).thenReturn([]);

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

    test('should delegate tap handling to use case for bookmark without stats',
        () {
      // Arrange - Mock repository to return empty list
      when(mockBookmarkRepository.bookmarks).thenReturn([]);

      // Act
      viewModel.handleBookmarkTap(bookmarkModelWithoutStats);

      // Assert
      verify(mockBookmarkOperationUseCases.handleBookmarkTap(
        bookmark: bookmarkModelWithoutStats,
        onNavigateToDetail: anyNamed('onNavigateToDetail'),
      )).called(1);
    });

    test('should delegate tap handling to use case for bookmark with stats',
        () {
      // Arrange - Mock repository to contain the bookmark
      when(mockBookmarkRepository.bookmarks)
          .thenReturn([bookmarkModelWithStats]);

      // Act
      viewModel.handleBookmarkTap(bookmarkModelWithStats);

      // Assert
      verify(mockBookmarkOperationUseCases.handleBookmarkTap(
        bookmark: bookmarkModelWithStats,
        onNavigateToDetail: anyNamed('onNavigateToDetail'),
      )).called(1);
    });

    test('should delegate tap handling to use case for not-found bookmark', () {
      // Arrange - Mock repository to return empty list
      when(mockBookmarkRepository.bookmarks).thenReturn([]);

      // Act
      viewModel.handleBookmarkTap(bookmarkModelWithoutStats);

      // Assert
      verify(mockBookmarkOperationUseCases.handleBookmarkTap(
        bookmark: bookmarkModelWithoutStats,
        onNavigateToDetail: anyNamed('onNavigateToDetail'),
      )).called(1);
    });

    test('should delegate tap handling to use case in mixed scenarios', () {
      // Arrange - Mock repository to contain both bookmarks
      when(mockBookmarkRepository.bookmarks)
          .thenReturn([bookmarkModelWithStats, bookmarkModelWithoutStats]);

      // Act - Test bookmark with stats
      viewModel.handleBookmarkTap(bookmarkModelWithStats);

      // Assert
      verify(mockBookmarkOperationUseCases.handleBookmarkTap(
        bookmark: bookmarkModelWithStats,
        onNavigateToDetail: anyNamed('onNavigateToDetail'),
      )).called(1);

      // Act - Test bookmark without stats
      viewModel.handleBookmarkTap(bookmarkModelWithoutStats);

      // Assert
      verify(mockBookmarkOperationUseCases.handleBookmarkTap(
        bookmark: bookmarkModelWithoutStats,
        onNavigateToDetail: anyNamed('onNavigateToDetail'),
      )).called(1);
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
      viewModel.setNavigateToDetailCallback((bookmark) {
        callbackCalled = true;
      });

      when(mockBookmarkOperationUseCases.handleBookmarkTap(
        bookmark: anyNamed('bookmark'),
        onNavigateToDetail: anyNamed('onNavigateToDetail'),
      )).thenAnswer((realInvocation) {
        final onNavigateToDetail =
            realInvocation.namedArguments[const Symbol('onNavigateToDetail')]
                as void Function(Bookmark);
        onNavigateToDetail(bookmarkModelWithStats.bookmark);
      });

      // Act
      viewModel.handleBookmarkTap(bookmarkModelWithStats);

      // Assert
      expect(callbackCalled, true);
    });

    test('should handle null callback gracefully', () {
      // The _onNavigateToDetail callback is not set, so it's null.
      when(mockBookmarkOperationUseCases.handleBookmarkTap(
        bookmark: anyNamed('bookmark'),
        onNavigateToDetail: anyNamed('onNavigateToDetail'),
      )).thenAnswer((realInvocation) {
        final onNavigateToDetail =
            realInvocation.namedArguments[const Symbol('onNavigateToDetail')]
                as void Function(Bookmark);
        // This should trigger _navigateToDetail in the viewmodel, which should
        // handle the null _onNavigateToDetail callback gracefully.
        onNavigateToDetail(bookmarkModelWithStats.bookmark);
      });

      // Act & Assert
      expect(() => viewModel.handleBookmarkTap(bookmarkModelWithStats),
          returnsNormally);
    });

    test('should call callback with correct bookmark', () {
      // Arrange
      Bookmark? receivedBookmark;
      viewModel.setNavigateToDetailCallback((bookmark) {
        receivedBookmark = bookmark;
      });

      when(mockBookmarkOperationUseCases.handleBookmarkTap(
        bookmark: anyNamed('bookmark'),
        onNavigateToDetail: anyNamed('onNavigateToDetail'),
      )).thenAnswer((realInvocation) {
        final onNavigateToDetail =
            realInvocation.namedArguments[const Symbol('onNavigateToDetail')]
                as void Function(Bookmark);
        onNavigateToDetail(testBookmarkWithStats);
      });

      // Act
      viewModel.handleBookmarkTap(bookmarkModelWithStats);

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
          .executeWithFuture(bookmarkModelWithStats);

      // Assert
      verify(mockBookmarkRepository.toggleMarked(testBookmarkWithStats))
          .called(1);
    });

    test('should maintain bookmark list state correctly', () async {
      // Arrange - Mock repository to contain test bookmarks and setup bookmark IDs
      when(mockBookmarkRepository.bookmarks)
          .thenReturn([bookmarkModelWithStats, bookmarkModelWithoutStats]);

      // Mock getCachedBookmark for each bookmark ID
      when(mockBookmarkRepository.getCachedBookmark(testBookmarkWithStats.id))
          .thenReturn(bookmarkModelWithStats);
      when(mockBookmarkRepository
              .getCachedBookmark(testBookmarkWithoutStats.id))
          .thenReturn(bookmarkModelWithoutStats);

      // Simulate loading that populates _bookmarkIds
      when(mockBookmarkRepository.loadUnarchivedBookmarks(
              limit: anyNamed('limit'), page: anyNamed('page')))
          .thenAnswer((_) async =>
              Success([bookmarkModelWithStats, bookmarkModelWithoutStats]));

      // Trigger load to populate internal bookmark IDs
      await viewModel.load.executeWithFuture(1);

      // Act
      final stats1 = viewModel.getReadingStats(testBookmarkWithStats.id);
      final stats2 = viewModel.getReadingStats(testBookmarkWithoutStats.id);

      // Assert
      expect(stats1, isNotNull);
      expect(stats1?.readableCharCount, mockReadingStats.readableCharCount);
      expect(stats2, isNull);
    });
  });

  group('Delete Bookmark Command Tests', () {
    test('should successfully delete bookmark and trigger UI update', () async {
      // Arrange
      when(mockBookmarkRepository.deleteBookmark(testBookmarkWithStats.id))
          .thenAnswer((_) async => const Success(unit));

      // Act
      await viewModel.deleteBookmark.executeWithFuture(bookmarkModelWithStats);

      // Assert
      verify(mockBookmarkRepository.deleteBookmark(testBookmarkWithStats.id))
          .called(1);
      expect(viewModel.deleteBookmark.isExecuting.value, isFalse);
    });

    test('should handle delete bookmark failure and throw error', () async {
      // Arrange
      final exception = Exception('Network error');
      when(mockBookmarkRepository.deleteBookmark(testBookmarkWithStats.id))
          .thenAnswer((_) async => Failure(exception));

      // Act & Assert
      expect(
        () =>
            viewModel.deleteBookmark.executeWithFuture(bookmarkModelWithStats),
        throwsA(isA<Exception>()),
      );

      verify(mockBookmarkRepository.deleteBookmark(testBookmarkWithStats.id))
          .called(1);
    });

    test('should not execute delete when already executing', () async {
      // Arrange
      when(mockBookmarkRepository.deleteBookmark(any)).thenAnswer((_) async {
        // Simulate slow operation
        await Future.delayed(const Duration(milliseconds: 100));
        return const Success(unit);
      });

      // Act
      final future1 =
          viewModel.deleteBookmark.executeWithFuture(bookmarkModelWithStats);
      expect(viewModel.deleteBookmark.isExecuting.value, isTrue);

      // Try to execute again while first is still running
      viewModel.deleteBookmark.execute(bookmarkModelWithoutStats);

      // Wait for first to complete
      await future1;

      // Assert - only one call should have been made
      verify(mockBookmarkRepository.deleteBookmark(any)).called(1);
    });

    test('should clear errors when delete command is executed again', () async {
      // Arrange - first call fails
      final exception = Exception('Network error');
      when(mockBookmarkRepository.deleteBookmark(testBookmarkWithStats.id))
          .thenAnswer((_) async => Failure(exception));

      // First execution - should fail
      try {
        await viewModel.deleteBookmark
            .executeWithFuture(bookmarkModelWithStats);
      } catch (e) {
        // Expected to throw
      }

      // Arrange - second call succeeds
      when(mockBookmarkRepository.deleteBookmark(testBookmarkWithoutStats.id))
          .thenAnswer((_) async => const Success(unit));

      // Act - second execution should clear errors
      await viewModel.deleteBookmark
          .executeWithFuture(bookmarkModelWithoutStats);

      // Assert
      expect(viewModel.deleteBookmark.isExecuting.value, isFalse);
    });

    test('should log deletion attempts appropriately', () async {
      // Arrange
      when(mockBookmarkRepository.deleteBookmark(testBookmarkWithStats.id))
          .thenAnswer((_) async => const Success(unit));

      // Act
      await viewModel.deleteBookmark.executeWithFuture(bookmarkModelWithStats);

      // Assert - verify repository method was called with correct bookmark ID
      verify(mockBookmarkRepository.deleteBookmark(testBookmarkWithStats.id))
          .called(1);
    });
  });
}
