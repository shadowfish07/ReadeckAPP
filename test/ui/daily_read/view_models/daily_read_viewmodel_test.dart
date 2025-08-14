import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/daily_read_history/daily_read_history_repository.dart';
import 'package:readeck_app/data/repository/label/label_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/bookmark_display_model/bookmark_display_model.dart';
import 'package:readeck_app/domain/models/daily_read_history/daily_read_history.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';
import 'package:readeck_app/ui/daily_read/view_models/daily_read_viewmodel.dart';
import 'package:logger/logger.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/utils/option_data.dart';
import 'package:result_dart/result_dart.dart';

import 'daily_read_viewmodel_test.mocks.dart';

@GenerateMocks([
  BookmarkRepository,
  DailyReadHistoryRepository,
  BookmarkOperationUseCases,
  LabelRepository
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
  });
}
