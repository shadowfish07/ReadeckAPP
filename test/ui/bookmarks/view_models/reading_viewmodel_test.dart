import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/label/label_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/bookmark_display_model/bookmark_display_model.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';
import 'package:readeck_app/ui/bookmarks/view_models/bookmarks_viewmodel.dart';
import 'package:logger/logger.dart';
import 'package:readeck_app/main.dart';
import 'package:result_dart/result_dart.dart';
import 'package:flutter_command/flutter_command.dart';

import 'reading_viewmodel_test.mocks.dart';

@GenerateMocks([BookmarkRepository, BookmarkOperationUseCases, LabelRepository])
void main() {
  late MockBookmarkRepository mockBookmarkRepository;
  late MockBookmarkOperationUseCases mockBookmarkOperationUseCases;
  late MockLabelRepository mockLabelRepository;
  late ReadingViewmodel readingViewmodel;

  setUpAll(() {
    appLogger = Logger();
    // 设置 flutter_command 全局异常处理器
    Command.globalExceptionHandler = (_, exception) {
      // 在测试中忽略异常，只为了满足 flutter_command 的要求
    };

    provideDummy<ResultDart<List<BookmarkDisplayModel>, Exception>>(
      const Success([]),
    );
    provideDummy<ResultDart<void, Exception>>(
      const Success(unit),
    );
    provideDummy<ResultDart<List<String>, Exception>>(
      const Success([]),
    );
  });

  setUp(() {
    mockBookmarkRepository = MockBookmarkRepository();
    mockBookmarkOperationUseCases = MockBookmarkOperationUseCases();
    mockLabelRepository = MockLabelRepository();

    // Setup default mock behaviors
    when(mockBookmarkRepository.addListener(any)).thenAnswer((_) {});
    when(mockBookmarkRepository.removeListener(any)).thenAnswer((_) {});
    when(mockBookmarkRepository.bookmarks).thenReturn([]);
    when(mockLabelRepository.addListener(any)).thenAnswer((_) {});
    when(mockLabelRepository.removeListener(any)).thenAnswer((_) {});
    when(mockLabelRepository.labelNames).thenReturn([]);
  });

  group('ReadingViewmodel', () {
    test('should load reading bookmarks on initialization', () async {
      // Arrange
      final readingBookmarks = [
        BookmarkDisplayModel(
          bookmark: Bookmark(
            id: '1',
            url: 'https://example.com/1',
            title: 'Reading Book 1',
            isArchived: false,
            isMarked: false,
            labels: [],
            created: DateTime.now(),
            readProgress: 25,
          ),
        ),
        BookmarkDisplayModel(
          bookmark: Bookmark(
            id: '2',
            url: 'https://example.com/2',
            title: 'Reading Book 2',
            isArchived: false,
            isMarked: false,
            labels: [],
            created: DateTime.now(),
            readProgress: 75,
          ),
        ),
      ];

      when(mockBookmarkRepository.loadReadingBookmarks(
              limit: anyNamed('limit'), page: anyNamed('page')))
          .thenAnswer((_) async => Success(readingBookmarks));

      // Mock bookmarks getter to return the data we want to test
      when(mockBookmarkRepository.bookmarks).thenReturn(readingBookmarks);

      // Act
      readingViewmodel = ReadingViewmodel(
        mockBookmarkRepository,
        mockBookmarkOperationUseCases,
        mockLabelRepository,
      );

      // Wait for the load command to complete
      await Future.delayed(Duration.zero);

      // Assert
      expect(readingViewmodel.bookmarks, readingBookmarks);
      verify(mockBookmarkRepository.loadReadingBookmarks(limit: 10, page: 1))
          .called(1);
    });

    test('should load more reading bookmarks when loadNextPage is called',
        () async {
      // Arrange
      final additionalBookmarks = [
        BookmarkDisplayModel(
          bookmark: Bookmark(
            id: '11',
            url: 'https://example.com/11',
            title: 'Reading Book 11',
            isArchived: false,
            isMarked: false,
            labels: [],
            created: DateTime.now(),
            readProgress: 75,
          ),
        ),
      ];

      // Make sure initial load returns 10 items to set hasMoreData = true
      final initialBookmarksWithFullPage = List.generate(
        10,
        (index) => BookmarkDisplayModel(
          bookmark: Bookmark(
            id: '${index + 1}',
            url: 'https://example.com/${index + 1}',
            title: 'Reading Book ${index + 1}',
            isArchived: false,
            isMarked: false,
            labels: [],
            created: DateTime.now(),
            readProgress: 25,
          ),
        ),
      );

      // Combined bookmarks for the final state
      final allBookmarks = [
        ...initialBookmarksWithFullPage,
        ...additionalBookmarks
      ];

      when(mockBookmarkRepository.loadReadingBookmarks(limit: 10, page: 1))
          .thenAnswer((_) async => Success(initialBookmarksWithFullPage));
      when(mockBookmarkRepository.loadReadingBookmarks(limit: 10, page: 2))
          .thenAnswer((_) async => Success(additionalBookmarks));

      // Mock bookmarks getter to return all bookmarks (Repository handles the caching internally)
      when(mockBookmarkRepository.bookmarks).thenReturn(allBookmarks);

      readingViewmodel = ReadingViewmodel(
        mockBookmarkRepository,
        mockBookmarkOperationUseCases,
        mockLabelRepository,
      );

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      readingViewmodel.loadNextPage();

      // Wait for loadMore command to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(
          readingViewmodel.bookmarks.length, 11); // 10 initial + 1 additional
      verify(mockBookmarkRepository.loadReadingBookmarks(limit: 10, page: 2))
          .called(1);
    });

    test('should call loadReadingBookmarks method from repository', () async {
      // Arrange
      when(mockBookmarkRepository.loadReadingBookmarks(
              limit: anyNamed('limit'), page: anyNamed('page')))
          .thenAnswer((_) async => const Success([]));

      // Act
      readingViewmodel = ReadingViewmodel(
        mockBookmarkRepository,
        mockBookmarkOperationUseCases,
        mockLabelRepository,
      );

      // Wait for initial load
      await Future.delayed(Duration.zero);

      // Assert
      verify(mockBookmarkRepository.loadReadingBookmarks(limit: 10, page: 1))
          .called(1);
    });
  });
}
