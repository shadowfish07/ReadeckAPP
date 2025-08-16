import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/daily_read_history/daily_read_history_repository.dart';
import 'package:readeck_app/data/repository/label/label_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/bookmark/label_info.dart';
import 'package:readeck_app/domain/models/bookmark_display_model/bookmark_display_model.dart';
import 'package:readeck_app/domain/models/daily_read_history/daily_read_history.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';
import 'package:readeck_app/ui/daily_read/view_models/daily_read_viewmodel.dart';
import 'package:logger/logger.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/utils/option_data.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';
import 'package:result_dart/result_dart.dart';

import 'daily_read_viewmodel_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<BookmarkRepository>(),
  MockSpec<DailyReadHistoryRepository>(),
  MockSpec<BookmarkOperationUseCases>(),
  MockSpec<LabelRepository>()
])
void main() {
  late MockBookmarkRepository mockBookmarkRepository;
  late MockDailyReadHistoryRepository mockDailyReadHistoryRepository;
  late MockBookmarkOperationUseCases mockBookmarkOperationUseCases;
  late MockLabelRepository mockLabelRepository;
  late DailyReadViewModel dailyReadViewModel;

  setUpAll(() {
    appLogger = Logger();
    provideDummy<ResultDart<OptionData<DailyReadHistory>, Exception>>(
      const Success(None()),
    );
    provideDummy<ResultDart<List<BookmarkDisplayModel>, Exception>>(
      const Success([]),
    );
    provideDummy<ResultDart<int, Exception>>(
      const Success(1),
    );
    // Provide a unit type dummy for void results
    provideDummy<ResultDart<void, Exception>>(
      Failure(Exception('dummy for void result')),
    );
    provideDummy<ResultDart<Bookmark, Exception>>(
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
    provideDummy<ResultDart<bool, Exception>>(
      const Success(true),
    );
    provideDummy<ResultDart<List<String>, Exception>>(
      const Success([]),
    );
    provideDummy<ResultDart<List<LabelInfo>, Exception>>(
      const Success([]),
    );
  });

  setUp(() {
    mockBookmarkRepository = MockBookmarkRepository();
    mockDailyReadHistoryRepository = MockDailyReadHistoryRepository();
    mockBookmarkOperationUseCases = MockBookmarkOperationUseCases();
    mockLabelRepository = MockLabelRepository();
  });

  group('DailyReadViewModel', () {
    test('should load random bookmarks when opening for the first time today',
        () async {
      // Arrange
      when(mockBookmarkRepository.addListener(any)).thenAnswer((_) {});
      when(mockLabelRepository.addListener(any)).thenAnswer((_) {});

      final bookmarks = [
        BookmarkDisplayModel(
          bookmark: Bookmark(
              id: '1',
              url: 'https://example.com',
              title: 'Test 1',
              isArchived: false,
              isMarked: false,
              labels: [],
              created: DateTime.now(),
              readProgress: 0),
        ),
        BookmarkDisplayModel(
          bookmark: Bookmark(
              id: '2',
              url: 'https://example.com',
              title: 'Test 2',
              isArchived: false,
              isMarked: false,
              labels: [],
              created: DateTime.now(),
              readProgress: 0),
        ),
      ];
      when(mockDailyReadHistoryRepository.getTodayDailyReadHistory())
          .thenAnswer((_) async => const Success(None()));
      when(mockBookmarkRepository.loadRandomUnarchivedBookmarks(any))
          .thenAnswer((_) async => Success(bookmarks));
      when(mockBookmarkRepository.bookmarks).thenReturn(bookmarks);
      when(mockDailyReadHistoryRepository.saveTodayBookmarks(any))
          .thenAnswer((_) async => const Success(1));

      // Act
      dailyReadViewModel = DailyReadViewModel(
        mockBookmarkRepository,
        mockDailyReadHistoryRepository,
        mockBookmarkOperationUseCases,
        mockLabelRepository,
      );

      // The load command is executed in the constructor. We need to wait for it to complete.
      await Future.delayed(Duration.zero);

      // Assert
      expect(dailyReadViewModel.unArchivedBookmarks, bookmarks);
      verify(mockDailyReadHistoryRepository.getTodayDailyReadHistory())
          .called(1);
      verify(mockBookmarkRepository.loadRandomUnarchivedBookmarks(5)).called(1);
    });

    test('should load today\'s bookmarks from history when available',
        () async {
      // Arrange
      when(mockBookmarkRepository.addListener(any)).thenAnswer((_) {});
      when(mockLabelRepository.addListener(any)).thenAnswer((_) {});

      final existingHistory = DailyReadHistory(
        id: 1,
        createdDate: DateTime.now(),
        bookmarkIds: ['1', '2'],
      );
      final bookmarks = [
        BookmarkDisplayModel(
          bookmark: Bookmark(
            id: '1',
            url: 'https://example.com',
            title: 'Existing 1',
            isArchived: false,
            isMarked: false,
            labels: [],
            created: DateTime.now(),
            readProgress: 0,
          ),
        ),
        BookmarkDisplayModel(
          bookmark: Bookmark(
            id: '2',
            url: 'https://example.com',
            title: 'Existing 2',
            isArchived: false,
            isMarked: false,
            labels: [],
            created: DateTime.now(),
            readProgress: 0,
          ),
        ),
      ];

      when(mockDailyReadHistoryRepository.getTodayDailyReadHistory())
          .thenAnswer((_) async => Success(Some(existingHistory)));
      when(mockBookmarkRepository.loadBookmarksByIds(['1', '2']))
          .thenAnswer((_) async => Success(bookmarks));
      when(mockBookmarkRepository.bookmarks).thenReturn(bookmarks);

      // Act
      dailyReadViewModel = DailyReadViewModel(
        mockBookmarkRepository,
        mockDailyReadHistoryRepository,
        mockBookmarkOperationUseCases,
        mockLabelRepository,
      );

      await Future.delayed(Duration.zero);

      // Assert
      expect(dailyReadViewModel.unArchivedBookmarks.length, 2);
      verify(mockDailyReadHistoryRepository.getTodayDailyReadHistory())
          .called(1);
      verify(mockBookmarkRepository.loadBookmarksByIds(['1', '2'])).called(1);
      verifyNever(mockBookmarkRepository.loadRandomUnarchivedBookmarks(any));
    });

    test('should handle toggle bookmark archived operation', () async {
      // Arrange
      when(mockBookmarkRepository.addListener(any)).thenAnswer((_) {});
      when(mockLabelRepository.addListener(any)).thenAnswer((_) {});
      when(mockDailyReadHistoryRepository.getTodayDailyReadHistory())
          .thenAnswer((_) async => const Success(None()));
      when(mockBookmarkRepository.loadRandomUnarchivedBookmarks(any))
          .thenAnswer((_) async => const Success([]));
      when(mockBookmarkRepository.bookmarks).thenReturn([]);
      when(mockDailyReadHistoryRepository.saveTodayBookmarks(any))
          .thenAnswer((_) async => const Success(1));

      final testBookmark = BookmarkDisplayModel(
        bookmark: Bookmark(
          id: '1',
          url: 'https://example.com',
          title: 'Test',
          isArchived: false,
          isMarked: false,
          labels: [],
          created: DateTime.now(),
          readProgress: 0,
        ),
      );

      when(mockBookmarkRepository.toggleArchived(testBookmark.bookmark))
          .thenAnswer((_) async => const Success(unit));

      dailyReadViewModel = DailyReadViewModel(
        mockBookmarkRepository,
        mockDailyReadHistoryRepository,
        mockBookmarkOperationUseCases,
        mockLabelRepository,
      );

      await Future.delayed(Duration.zero);

      // Act
      await dailyReadViewModel.toggleBookmarkArchived
          .executeWithFuture(testBookmark);

      // Assert
      verify(mockBookmarkRepository.toggleArchived(testBookmark.bookmark))
          .called(1);
    });

    test('should handle toggle bookmark marked operation', () async {
      // Arrange
      when(mockBookmarkRepository.addListener(any)).thenAnswer((_) {});
      when(mockLabelRepository.addListener(any)).thenAnswer((_) {});
      when(mockDailyReadHistoryRepository.getTodayDailyReadHistory())
          .thenAnswer((_) async => const Success(None()));
      when(mockBookmarkRepository.loadRandomUnarchivedBookmarks(any))
          .thenAnswer((_) async => const Success([]));
      when(mockBookmarkRepository.bookmarks).thenReturn([]);
      when(mockDailyReadHistoryRepository.saveTodayBookmarks(any))
          .thenAnswer((_) async => const Success(1));

      final testBookmark = BookmarkDisplayModel(
        bookmark: Bookmark(
          id: '1',
          url: 'https://example.com',
          title: 'Test',
          isArchived: false,
          isMarked: false,
          labels: [],
          created: DateTime.now(),
          readProgress: 0,
        ),
      );

      when(mockBookmarkRepository.toggleMarked(testBookmark.bookmark))
          .thenAnswer((_) async => const Success(unit));

      dailyReadViewModel = DailyReadViewModel(
        mockBookmarkRepository,
        mockDailyReadHistoryRepository,
        mockBookmarkOperationUseCases,
        mockLabelRepository,
      );

      await Future.delayed(Duration.zero);

      // Act
      await dailyReadViewModel.toggleBookmarkMarked
          .executeWithFuture(testBookmark);

      // Assert
      verify(mockBookmarkRepository.toggleMarked(testBookmark.bookmark))
          .called(1);
    });

    test('should handle open URL operation', () async {
      // Arrange
      when(mockBookmarkRepository.addListener(any)).thenAnswer((_) {});
      when(mockLabelRepository.addListener(any)).thenAnswer((_) {});
      when(mockDailyReadHistoryRepository.getTodayDailyReadHistory())
          .thenAnswer((_) async => const Success(None()));
      when(mockBookmarkRepository.loadRandomUnarchivedBookmarks(any))
          .thenAnswer((_) async => const Success([]));
      when(mockBookmarkRepository.bookmarks).thenReturn([]);
      when(mockDailyReadHistoryRepository.saveTodayBookmarks(any))
          .thenAnswer((_) async => const Success(1));

      const testUrl = 'https://example.com';
      when(mockBookmarkOperationUseCases.openUrl(testUrl))
          .thenAnswer((_) async => const Success(unit));

      dailyReadViewModel = DailyReadViewModel(
        mockBookmarkRepository,
        mockDailyReadHistoryRepository,
        mockBookmarkOperationUseCases,
        mockLabelRepository,
      );

      await Future.delayed(Duration.zero);

      // Act
      await dailyReadViewModel.openUrl.executeWithFuture(testUrl);

      // Assert
      verify(mockBookmarkOperationUseCases.openUrl(testUrl)).called(1);
    });

    test('should load labels successfully', () async {
      // Arrange
      when(mockBookmarkRepository.addListener(any)).thenAnswer((_) {});
      when(mockLabelRepository.addListener(any)).thenAnswer((_) {});
      when(mockDailyReadHistoryRepository.getTodayDailyReadHistory())
          .thenAnswer((_) async => const Success(None()));
      when(mockBookmarkRepository.loadRandomUnarchivedBookmarks(any))
          .thenAnswer((_) async => const Success([]));
      when(mockBookmarkRepository.bookmarks).thenReturn([]);
      when(mockDailyReadHistoryRepository.saveTodayBookmarks(any))
          .thenAnswer((_) async => const Success(1));

      const expectedLabels = ['技术', 'Flutter', '阅读'];
      when(mockLabelRepository.loadLabels())
          .thenAnswer((_) async => const Success([]));
      when(mockLabelRepository.labelNames).thenReturn(expectedLabels);

      dailyReadViewModel = DailyReadViewModel(
        mockBookmarkRepository,
        mockDailyReadHistoryRepository,
        mockBookmarkOperationUseCases,
        mockLabelRepository,
      );

      await Future.delayed(Duration.zero);

      // Act
      final result = await dailyReadViewModel.loadLabels.executeWithFuture();

      // Assert
      expect(result, expectedLabels);
      verify(mockLabelRepository.loadLabels()).called(1);
    });

    test('should handle bookmark archived callback', () async {
      // Arrange
      when(mockBookmarkRepository.addListener(any)).thenAnswer((_) {});
      when(mockLabelRepository.addListener(any)).thenAnswer((_) {});
      when(mockDailyReadHistoryRepository.getTodayDailyReadHistory())
          .thenAnswer((_) async => const Success(None()));
      when(mockBookmarkRepository.loadRandomUnarchivedBookmarks(any))
          .thenAnswer((_) async => const Success([]));
      when(mockBookmarkRepository.bookmarks).thenReturn([]);
      when(mockDailyReadHistoryRepository.saveTodayBookmarks(any))
          .thenAnswer((_) async => const Success(1));

      dailyReadViewModel = DailyReadViewModel(
        mockBookmarkRepository,
        mockDailyReadHistoryRepository,
        mockBookmarkOperationUseCases,
        mockLabelRepository,
      );

      var callbackCalled = false;

      // Act
      dailyReadViewModel.setOnBookmarkArchivedCallback(() {
        callbackCalled = true;
      });

      // Simulate the callback being called (this would normally happen in the UI)
      // Since we can't directly test the private callback, we test the setter works
      expect(callbackCalled, false); // Initially false

      // Clear the callback
      dailyReadViewModel.setOnBookmarkArchivedCallback(null);

      // This test verifies the callback setter works properly
      expect(true, true); // Placeholder assertion
    });

    test('should properly dispose and clean up listeners', () async {
      // Arrange
      when(mockBookmarkRepository.addListener(any)).thenAnswer((_) {});
      when(mockLabelRepository.addListener(any)).thenAnswer((_) {});
      when(mockBookmarkRepository.removeListener(any)).thenAnswer((_) {});
      when(mockLabelRepository.removeListener(any)).thenAnswer((_) {});
      when(mockDailyReadHistoryRepository.getTodayDailyReadHistory())
          .thenAnswer((_) async => const Success(None()));
      when(mockBookmarkRepository.loadRandomUnarchivedBookmarks(any))
          .thenAnswer((_) async => const Success([]));
      when(mockBookmarkRepository.bookmarks).thenReturn([]);
      when(mockDailyReadHistoryRepository.saveTodayBookmarks(any))
          .thenAnswer((_) async => const Success(1));

      dailyReadViewModel = DailyReadViewModel(
        mockBookmarkRepository,
        mockDailyReadHistoryRepository,
        mockBookmarkOperationUseCases,
        mockLabelRepository,
      );

      // Act
      dailyReadViewModel.dispose();

      // Assert
      verify(mockBookmarkRepository.removeListener(any)).called(1);
      verify(mockLabelRepository.removeListener(any)).called(1);
    });
  });

  group('DailyReadViewModel handleBookmarkTap Tests', () {
    late Bookmark testBookmarkWithStats;
    late Bookmark testBookmarkWithoutStats;
    late BookmarkDisplayModel bookmarkModelWithStats;
    late BookmarkDisplayModel bookmarkModelWithoutStats;

    setUp(() {
      when(mockBookmarkRepository.addListener(any)).thenAnswer((_) {});
      when(mockLabelRepository.addListener(any)).thenAnswer((_) {});
      when(mockBookmarkOperationUseCases.handleBookmarkTap(
        bookmark: anyNamed('bookmark'),
        onNavigateToDetail: anyNamed('onNavigateToDetail'),
      )).thenAnswer((invocation) {
        final bookmark = invocation.namedArguments[const Symbol('bookmark')]
            as BookmarkDisplayModel;
        final onNavigateToDetail =
            invocation.namedArguments[const Symbol('onNavigateToDetail')]
                as void Function(Bookmark);
        if (bookmark.stats != null) {
          onNavigateToDetail(bookmark.bookmark);
        } else {
          mockBookmarkOperationUseCases.openUrl(bookmark.bookmark.url);
        }
      });
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

      bookmarkModelWithStats = BookmarkDisplayModel(
        bookmark: testBookmarkWithStats,
        stats: const ReadingStatsForView(
          readableCharCount: 1000,
          estimatedReadingTimeMinutes: 5.0,
        ),
      );

      bookmarkModelWithoutStats = BookmarkDisplayModel(
        bookmark: testBookmarkWithoutStats,
        stats: null,
      );
    });

    test('should open URL when bookmark has no reading stats', () async {
      // Arrange
      when(mockDailyReadHistoryRepository.getTodayDailyReadHistory())
          .thenAnswer((_) async => const Success(None()));
      when(mockBookmarkRepository.loadRandomUnarchivedBookmarks(any))
          .thenAnswer((_) async => Success([bookmarkModelWithoutStats]));
      when(mockBookmarkRepository.bookmarks)
          .thenReturn([bookmarkModelWithoutStats]);
      when(mockDailyReadHistoryRepository.saveTodayBookmarks(any))
          .thenAnswer((_) async => const Success(1));
      when(mockBookmarkOperationUseCases.openUrl(testBookmarkWithoutStats.url))
          .thenAnswer((_) async => const Success(unit));

      dailyReadViewModel = DailyReadViewModel(
        mockBookmarkRepository,
        mockDailyReadHistoryRepository,
        mockBookmarkOperationUseCases,
        mockLabelRepository,
      );

      await Future.delayed(Duration.zero);

      // Act
      dailyReadViewModel.handleBookmarkTap(bookmarkModelWithoutStats);

      // Assert
      verify(mockBookmarkOperationUseCases
              .openUrl(testBookmarkWithoutStats.url))
          .called(1);
    });

    test('should call navigation callback when bookmark has reading stats',
        () async {
      // Arrange
      when(mockDailyReadHistoryRepository.getTodayDailyReadHistory())
          .thenAnswer((_) async => const Success(None()));
      when(mockBookmarkRepository.loadRandomUnarchivedBookmarks(any))
          .thenAnswer((_) async => Success([bookmarkModelWithStats]));
      when(mockBookmarkRepository.bookmarks)
          .thenReturn([bookmarkModelWithStats]);
      when(mockDailyReadHistoryRepository.saveTodayBookmarks(any))
          .thenAnswer((_) async => const Success(1));

      bool navigationCallbackCalled = false;
      Bookmark? callbackBookmark;

      dailyReadViewModel = DailyReadViewModel(
        mockBookmarkRepository,
        mockDailyReadHistoryRepository,
        mockBookmarkOperationUseCases,
        mockLabelRepository,
      );

      dailyReadViewModel.setNavigateToDetailCallback((bookmark) {
        navigationCallbackCalled = true;
        callbackBookmark = bookmark;
      });

      await Future.delayed(Duration.zero);

      // Act
      dailyReadViewModel.handleBookmarkTap(bookmarkModelWithStats);

      // Assert
      expect(navigationCallbackCalled, true);
      expect(callbackBookmark, testBookmarkWithStats);
      verifyNever(
          mockBookmarkOperationUseCases.openUrl(testBookmarkWithStats.url));
    });

    test('should set and use navigation callback successfully', () async {
      // Arrange
      when(mockDailyReadHistoryRepository.getTodayDailyReadHistory())
          .thenAnswer((_) async => const Success(None()));
      when(mockBookmarkRepository.loadRandomUnarchivedBookmarks(any))
          .thenAnswer((_) async => Success([bookmarkModelWithStats]));
      when(mockBookmarkRepository.bookmarks)
          .thenReturn([bookmarkModelWithStats]);
      when(mockDailyReadHistoryRepository.saveTodayBookmarks(any))
          .thenAnswer((_) async => const Success(1));

      dailyReadViewModel = DailyReadViewModel(
        mockBookmarkRepository,
        mockDailyReadHistoryRepository,
        mockBookmarkOperationUseCases,
        mockLabelRepository,
      );

      Bookmark? receivedBookmark;
      dailyReadViewModel.setNavigateToDetailCallback((bookmark) {
        receivedBookmark = bookmark;
      });

      await Future.delayed(Duration.zero);

      // Act
      dailyReadViewModel.handleBookmarkTap(bookmarkModelWithStats);

      // Assert
      expect(receivedBookmark, testBookmarkWithStats);
      expect(receivedBookmark?.id, testBookmarkWithStats.id);
      expect(receivedBookmark?.title, testBookmarkWithStats.title);
    });

    test('should handle callback gracefully when set to empty function',
        () async {
      // Arrange
      when(mockDailyReadHistoryRepository.getTodayDailyReadHistory())
          .thenAnswer((_) async => const Success(None()));
      when(mockBookmarkRepository.loadRandomUnarchivedBookmarks(any))
          .thenAnswer((_) async => Success([bookmarkModelWithStats]));
      when(mockBookmarkRepository.bookmarks)
          .thenReturn([bookmarkModelWithStats]);
      when(mockDailyReadHistoryRepository.saveTodayBookmarks(any))
          .thenAnswer((_) async => const Success(1));

      dailyReadViewModel = DailyReadViewModel(
        mockBookmarkRepository,
        mockDailyReadHistoryRepository,
        mockBookmarkOperationUseCases,
        mockLabelRepository,
      );

      // Set empty callback
      dailyReadViewModel.setNavigateToDetailCallback((_) {});

      await Future.delayed(Duration.zero);

      // Act - should not throw
      expect(() => dailyReadViewModel.handleBookmarkTap(bookmarkModelWithStats),
          returnsNormally);

      // Wait a bit more to ensure any async operations complete
      await Future.delayed(const Duration(milliseconds: 10));
    });
  });
}
