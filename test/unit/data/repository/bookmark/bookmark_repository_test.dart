import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/article/article_repository.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/reading_stats/reading_stats_repository.dart';
import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';
import 'package:result_dart/result_dart.dart';

import 'bookmark_repository_test.mocks.dart';

@GenerateMocks([
  ReadeckApiClient,
  ReadingStatsRepository,
  ArticleRepository,
])
void main() {
  group('BookmarkRepository', () {
    late BookmarkRepository repository;
    late MockReadeckApiClient mockApiClient;
    late MockReadingStatsRepository mockReadingStatsRepository;
    late MockArticleRepository mockArticleRepository;

    setUpAll(() {
      // 初始化全局logger，避免LateInitializationError
      appLogger = Logger(level: Level.off);

      // 为Mockito提供dummy值
      provideDummy<Result<List<Bookmark>>>(const Success(<Bookmark>[]));
      provideDummy<Result<ReadingStatsForView>>(
        const Success(ReadingStatsForView(
          readableCharCount: 0,
          estimatedReadingTimeMinutes: 0,
        )),
      );
      provideDummy<Result<String>>(const Success(''));
    });

    setUp(() {
      mockApiClient = MockReadeckApiClient();
      mockReadingStatsRepository = MockReadingStatsRepository();
      mockArticleRepository = MockArticleRepository();
      repository = BookmarkRepository(
        mockApiClient,
        mockReadingStatsRepository,
        mockArticleRepository,
      );
    });

    group('loadReadingBookmarks', () {
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

        when(mockApiClient.getBookmarks(
          readStatus: 'reading',
          isArchived: false,
          limit: 15,
          offset: 15,
        )).thenAnswer((_) async => Success(readingBookmarks));

        when(mockReadingStatsRepository.getReadingStats(any))
            .thenAnswer((_) async => Failure(Exception('No stats')));

        when(mockArticleRepository.getBookmarkArticle(any))
            .thenAnswer((_) async => Failure(Exception('No article')));

        // Act
        final result = await repository.loadReadingBookmarks(
          limit: 15,
          page: 2,
        );

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull()!.length, 2);
        verify(mockApiClient.getBookmarks(
          readStatus: 'reading',
          isArchived: false,
          limit: 15,
          offset: 15, // (page - 1) * limit = (2 - 1) * 15
        )).called(1);
      });

      test('should return empty list when API returns no reading bookmarks',
          () async {
        // Arrange
        when(mockApiClient.getBookmarks(
          readStatus: 'reading',
          isArchived: false,
          limit: 10,
          offset: 0,
        )).thenAnswer((_) async => const Success([]));

        // Act
        final result = await repository.loadReadingBookmarks();

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull()!.isEmpty, true);
        verify(mockApiClient.getBookmarks(
          readStatus: 'reading',
          isArchived: false,
          limit: 10,
          offset: 0,
        )).called(1);
      });

      test('should return failure when API call fails', () async {
        // Arrange
        final exception = Exception('Network error');
        when(mockApiClient.getBookmarks(
          readStatus: 'reading',
          isArchived: false,
          limit: 10,
          offset: 0,
        )).thenAnswer((_) async => Failure(exception));

        // Act
        final result = await repository.loadReadingBookmarks();

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull(), exception);
      });

      test('should use default pagination parameters when not specified',
          () async {
        // Arrange
        when(mockApiClient.getBookmarks(
          readStatus: 'reading',
          isArchived: false,
          limit: 10,
          offset: 0,
        )).thenAnswer((_) async => const Success([]));

        // Act
        await repository.loadReadingBookmarks();

        // Assert
        verify(mockApiClient.getBookmarks(
          readStatus: 'reading',
          isArchived: false,
          limit: 10, // default limit
          offset: 0, // default offset for page 1
        )).called(1);
      });
    });

    group('_wrapBookmarksWithStats', () {
      late Bookmark testBookmark;

      setUp(() {
        testBookmark = Bookmark(
          id: 'bookmark-1',
          title: 'Test Bookmark',
          url: 'https://example.com',
          siteName: 'example.com',
          description: 'Test description',
          isMarked: false,
          isArchived: false,
          readProgress: 0,
          labels: const [],
          created: DateTime.parse('2024-01-01T00:00:00Z'),
          imageUrl: null,
        );
      });

      test('should return bookmark with existing reading stats from database',
          () async {
        // Arrange
        const existingStats = ReadingStatsForView(
          readableCharCount: 1000,
          estimatedReadingTimeMinutes: 2.5,
        );

        // Mock API返回书签数据
        when(mockApiClient.getBookmarks(ids: ['bookmark-1']))
            .thenAnswer((_) async => Success([testBookmark]));

        when(mockReadingStatsRepository.getReadingStats('bookmark-1'))
            .thenAnswer((_) async => const Success(existingStats));

        // Act
        final result = await repository.loadBookmarksByIds(['bookmark-1']);

        // Assert
        expect(result.isSuccess(), true);
        final bookmarks = result.getOrNull()!;
        expect(bookmarks.length, 1);
        expect(bookmarks[0].stats, existingStats);
        expect(bookmarks[0].bookmark, testBookmark);

        // Verify that article content was not fetched since stats existed
        verifyNever(mockArticleRepository.getBookmarkArticle(any));
        verifyNever(
            mockReadingStatsRepository.calculateAndSaveReadingStats(any, any));
      });

      test('should calculate and save reading stats when not in database',
          () async {
        // Arrange
        const htmlContent =
            '<html><body><p>这是一篇测试文章，包含一些中文内容。This is test content with some English words.</p></body></html>';
        const calculatedStats = ReadingStatsForView(
          readableCharCount: 800,
          estimatedReadingTimeMinutes: 2.0,
        );

        // Mock API返回书签数据
        when(mockApiClient.getBookmarks(ids: ['bookmark-1']))
            .thenAnswer((_) async => Success([testBookmark]));

        // Mock数据库中没有统计数据
        when(mockReadingStatsRepository.getReadingStats('bookmark-1'))
            .thenAnswer((_) async => Failure(Exception('Stats not found')));

        // Mock文章内容获取成功
        when(mockArticleRepository.getBookmarkArticle('bookmark-1'))
            .thenAnswer((_) async => const Success(htmlContent));

        // Mock计算并保存统计数据成功
        when(mockReadingStatsRepository.calculateAndSaveReadingStats(
                'bookmark-1', htmlContent))
            .thenAnswer((_) async => const Success(calculatedStats));

        // Act
        final result = await repository.loadBookmarksByIds(['bookmark-1']);

        // Assert
        expect(result.isSuccess(), true);
        final bookmarks = result.getOrNull()!;
        expect(bookmarks.length, 1);
        expect(bookmarks[0].stats, calculatedStats);
        expect(bookmarks[0].bookmark, testBookmark);

        // Verify interaction sequence
        verify(mockReadingStatsRepository.getReadingStats('bookmark-1'))
            .called(1);
        verify(mockArticleRepository.getBookmarkArticle('bookmark-1'))
            .called(1);
        verify(mockReadingStatsRepository.calculateAndSaveReadingStats(
                'bookmark-1', htmlContent))
            .called(1);
      });

      test(
          'should return bookmark without stats when article content fetch fails',
          () async {
        // Arrange
        when(mockApiClient.getBookmarks(ids: ['bookmark-1']))
            .thenAnswer((_) async => Success([testBookmark]));

        when(mockReadingStatsRepository.getReadingStats('bookmark-1'))
            .thenAnswer((_) async => Failure(Exception('Stats not found')));

        when(mockArticleRepository.getBookmarkArticle('bookmark-1'))
            .thenAnswer((_) async => Failure(Exception('Article not found')));

        // Act
        final result = await repository.loadBookmarksByIds(['bookmark-1']);

        // Assert
        expect(result.isSuccess(), true);
        final bookmarks = result.getOrNull()!;
        expect(bookmarks.length, 1);
        expect(bookmarks[0].stats, null);
        expect(bookmarks[0].bookmark, testBookmark);

        // Verify interaction sequence
        verify(mockReadingStatsRepository.getReadingStats('bookmark-1'))
            .called(1);
        verify(mockArticleRepository.getBookmarkArticle('bookmark-1'))
            .called(1);
        verifyNever(
            mockReadingStatsRepository.calculateAndSaveReadingStats(any, any));
      });

      test('should return bookmark without stats when stats calculation fails',
          () async {
        // Arrange
        const htmlContent = '<html><body><p>Test content</p></body></html>';

        when(mockApiClient.getBookmarks(ids: ['bookmark-1']))
            .thenAnswer((_) async => Success([testBookmark]));

        when(mockReadingStatsRepository.getReadingStats('bookmark-1'))
            .thenAnswer((_) async => Failure(Exception('Stats not found')));

        when(mockArticleRepository.getBookmarkArticle('bookmark-1'))
            .thenAnswer((_) async => const Success(htmlContent));

        when(mockReadingStatsRepository.calculateAndSaveReadingStats(
                'bookmark-1', htmlContent))
            .thenAnswer((_) async => Failure(Exception('Calculation failed')));

        // Act
        final result = await repository.loadBookmarksByIds(['bookmark-1']);

        // Assert
        expect(result.isSuccess(), true);
        final bookmarks = result.getOrNull()!;
        expect(bookmarks.length, 1);
        expect(bookmarks[0].stats, null);
        expect(bookmarks[0].bookmark, testBookmark);

        // Verify interaction sequence
        verify(mockReadingStatsRepository.getReadingStats('bookmark-1'))
            .called(1);
        verify(mockArticleRepository.getBookmarkArticle('bookmark-1'))
            .called(1);
        verify(mockReadingStatsRepository.calculateAndSaveReadingStats(
                'bookmark-1', htmlContent))
            .called(1);
      });

      test('should handle multiple bookmarks with mixed stats availability',
          () async {
        // Arrange
        final bookmark1 = testBookmark;
        final bookmark2 =
            testBookmark.copyWith(id: 'bookmark-2', title: 'Bookmark 2');
        final bookmark3 =
            testBookmark.copyWith(id: 'bookmark-3', title: 'Bookmark 3');

        const stats1 = ReadingStatsForView(
          readableCharCount: 1000,
          estimatedReadingTimeMinutes: 2.5,
        );
        const stats3 = ReadingStatsForView(
          readableCharCount: 1500,
          estimatedReadingTimeMinutes: 3.0,
        );
        const htmlContent3 =
            '<html><body><p>Content for bookmark 3</p></body></html>';

        when(mockApiClient.getBookmarks(ids: [
          'bookmark-1',
          'bookmark-2',
          'bookmark-3'
        ])).thenAnswer((_) async => Success([bookmark1, bookmark2, bookmark3]));

        // Bookmark 1: has existing stats
        when(mockReadingStatsRepository.getReadingStats('bookmark-1'))
            .thenAnswer((_) async => const Success(stats1));

        // Bookmark 2: no stats, article fetch fails
        when(mockReadingStatsRepository.getReadingStats('bookmark-2'))
            .thenAnswer((_) async => Failure(Exception('Stats not found')));
        when(mockArticleRepository.getBookmarkArticle('bookmark-2'))
            .thenAnswer((_) async => Failure(Exception('Article not found')));

        // Bookmark 3: no stats, successful calculation
        when(mockReadingStatsRepository.getReadingStats('bookmark-3'))
            .thenAnswer((_) async => Failure(Exception('Stats not found')));
        when(mockArticleRepository.getBookmarkArticle('bookmark-3'))
            .thenAnswer((_) async => const Success(htmlContent3));
        when(mockReadingStatsRepository.calculateAndSaveReadingStats(
                'bookmark-3', htmlContent3))
            .thenAnswer((_) async => const Success(stats3));

        // Act
        final result = await repository
            .loadBookmarksByIds(['bookmark-1', 'bookmark-2', 'bookmark-3']);

        // Assert
        expect(result.isSuccess(), true);
        final bookmarks = result.getOrNull()!;
        expect(bookmarks.length, 3);

        // Bookmark 1 has stats
        expect(bookmarks[0].bookmark.id, 'bookmark-1');
        expect(bookmarks[0].stats, stats1);

        // Bookmark 2 has no stats
        expect(bookmarks[1].bookmark.id, 'bookmark-2');
        expect(bookmarks[1].stats, null);

        // Bookmark 3 has calculated stats
        expect(bookmarks[2].bookmark.id, 'bookmark-3');
        expect(bookmarks[2].stats, stats3);
      });

      test('should handle exception during article fetch gracefully', () async {
        // Arrange
        when(mockApiClient.getBookmarks(ids: ['bookmark-1']))
            .thenAnswer((_) async => Success([testBookmark]));

        when(mockReadingStatsRepository.getReadingStats('bookmark-1'))
            .thenAnswer((_) async => Failure(Exception('Stats not found')));

        when(mockArticleRepository.getBookmarkArticle('bookmark-1'))
            .thenThrow(Exception('Network error'));

        // Act
        final result = await repository.loadBookmarksByIds(['bookmark-1']);

        // Assert
        expect(result.isSuccess(), true);
        final bookmarks = result.getOrNull()!;
        expect(bookmarks.length, 1);
        expect(bookmarks[0].stats, null);
        expect(bookmarks[0].bookmark, testBookmark);
      });
    });

    group('loadUnarchivedBookmarks', () {
      test('should load unarchived bookmarks with stats calculation', () async {
        // Arrange
        final testBookmark = Bookmark(
          id: 'bookmark-1',
          title: 'Test Bookmark',
          url: 'https://example.com',
          siteName: 'example.com',
          description: 'Test description',
          isMarked: false,
          isArchived: false,
          readProgress: 0,
          labels: const [],
          created: DateTime.parse('2024-01-01T00:00:00Z'),
          imageUrl: null,
        );
        final bookmarks = [testBookmark];
        const stats = ReadingStatsForView(
          readableCharCount: 1200,
          estimatedReadingTimeMinutes: 3.0,
        );
        const htmlContent = '<html><body><p>Test content</p></body></html>';

        when(mockApiClient.getBookmarks(
          isArchived: false,
          limit: 10,
          offset: 0,
        )).thenAnswer((_) async => Success(bookmarks));

        when(mockReadingStatsRepository.getReadingStats('bookmark-1'))
            .thenAnswer((_) async => Failure(Exception('Stats not found')));

        when(mockArticleRepository.getBookmarkArticle('bookmark-1'))
            .thenAnswer((_) async => const Success(htmlContent));

        when(mockReadingStatsRepository.calculateAndSaveReadingStats(
                'bookmark-1', htmlContent))
            .thenAnswer((_) async => const Success(stats));

        // Act
        final result = await repository.loadUnarchivedBookmarks();

        // Assert
        expect(result.isSuccess(), true);
        final displayModels = result.getOrNull()!;
        expect(displayModels.length, 1);
        expect(displayModels[0].stats, stats);
        expect(displayModels[0].bookmark, testBookmark);
      });
    });

    group('loadArchivedBookmarks', () {
      test('should load archived bookmarks with stats calculation', () async {
        // Arrange
        final testBookmark = Bookmark(
          id: 'bookmark-1',
          title: 'Test Bookmark',
          url: 'https://example.com',
          siteName: 'example.com',
          description: 'Test description',
          isMarked: false,
          isArchived: false,
          readProgress: 0,
          labels: const [],
          created: DateTime.parse('2024-01-01T00:00:00Z'),
          imageUrl: null,
        );
        final archivedBookmark = testBookmark.copyWith(isArchived: true);
        final bookmarks = [archivedBookmark];
        const stats = ReadingStatsForView(
          readableCharCount: 800,
          estimatedReadingTimeMinutes: 2.0,
        );

        when(mockApiClient.getBookmarks(
          isArchived: true,
          limit: 10,
          offset: 0,
        )).thenAnswer((_) async => Success(bookmarks));

        when(mockReadingStatsRepository.getReadingStats('bookmark-1'))
            .thenAnswer((_) async => const Success(stats));

        // Act
        final result = await repository.loadArchivedBookmarks();

        // Assert
        expect(result.isSuccess(), true);
        final displayModels = result.getOrNull()!;
        expect(displayModels.length, 1);
        expect(displayModels[0].stats, stats);
        expect(displayModels[0].bookmark, archivedBookmark);
      });
    });

    group('loadMarkedBookmarks', () {
      test('should load marked bookmarks with stats calculation', () async {
        // Arrange
        final testBookmark = Bookmark(
          id: 'bookmark-1',
          title: 'Test Bookmark',
          url: 'https://example.com',
          siteName: 'example.com',
          description: 'Test description',
          isMarked: false,
          isArchived: false,
          readProgress: 0,
          labels: const [],
          created: DateTime.parse('2024-01-01T00:00:00Z'),
          imageUrl: null,
        );
        final markedBookmark = testBookmark.copyWith(isMarked: true);
        final bookmarks = [markedBookmark];
        const stats = ReadingStatsForView(
          readableCharCount: 1500,
          estimatedReadingTimeMinutes: 3.5,
        );

        when(mockApiClient.getBookmarks(
          isMarked: true,
          limit: 10,
          offset: 0,
        )).thenAnswer((_) async => Success(bookmarks));

        when(mockReadingStatsRepository.getReadingStats('bookmark-1'))
            .thenAnswer((_) async => const Success(stats));

        // Act
        final result = await repository.loadMarkedBookmarks();

        // Assert
        expect(result.isSuccess(), true);
        final displayModels = result.getOrNull()!;
        expect(displayModels.length, 1);
        expect(displayModels[0].stats, stats);
        expect(displayModels[0].bookmark, markedBookmark);
      });
    });

    group('Reading Stats Auto-calculation (Bug Fix)', () {
      test('should automatically calculate reading stats when not in database',
          () async {
        // Arrange - 模拟一个书签没有预先计算的阅读统计数据 (bug场景)
        final testBookmark = Bookmark(
          id: 'bookmark-bug-test',
          title: 'Move on to ESM-only',
          url: 'https://antfu.me/posts/esm-only',
          siteName: 'antfu.me',
          description: "Let's move on to ESM-only",
          isMarked: false,
          isArchived: false,
          readProgress: 4, // 4% 阅读进度，如用户截图所示
          labels: const ['但是', '大声道'],
          created: DateTime.parse('2024-01-01T00:00:00Z'),
          imageUrl: null,
        );

        // 模拟HTML内容
        const htmlContent = '''
          <html>
            <body>
              <article>
                <h1>Move on to ESM-only</h1>
                <p>这是一篇关于ESM的技术文章，包含了详细的技术讨论。</p>
                <p>The article discusses the transition to ESM-only packages in the JavaScript ecosystem.</p>
                <p>文章深入分析了从CommonJS迁移到ESM的各种挑战和解决方案。</p>
              </article>
            </body>
          </html>
        ''';

        // 计算出的阅读统计数据
        const expectedStats = ReadingStatsForView(
          readableCharCount: 150,
          estimatedReadingTimeMinutes: 2.5,
        );

        // Mock设置
        when(mockApiClient.getBookmarks(ids: ['bookmark-bug-test']))
            .thenAnswer((_) async => Success([testBookmark]));

        // 数据库中没有预计算的统计数据 (这是bug的核心场景)
        when(mockReadingStatsRepository.getReadingStats('bookmark-bug-test'))
            .thenAnswer(
                (_) async => Failure(Exception('Stats not found in database')));

        // 文章内容获取成功
        when(mockArticleRepository.getBookmarkArticle('bookmark-bug-test'))
            .thenAnswer((_) async => const Success(htmlContent));

        // 计算并保存统计数据成功
        when(mockReadingStatsRepository.calculateAndSaveReadingStats(
                'bookmark-bug-test', htmlContent))
            .thenAnswer((_) async => const Success(expectedStats));

        // Act - 加载书签（这会触发阅读统计数据的自动计算）
        final result =
            await repository.loadBookmarksByIds(['bookmark-bug-test']);

        // Assert - 验证修复后的行为
        expect(result.isSuccess(), true, reason: '书签加载应该成功');

        final bookmarks = result.getOrNull()!;
        expect(bookmarks.length, 1, reason: '应该返回1个书签');

        final bookmarkDisplayModel = bookmarks[0];
        expect(bookmarkDisplayModel.bookmark, testBookmark, reason: '书签数据应该正确');
        expect(bookmarkDisplayModel.stats, expectedStats,
            reason: '阅读统计数据应该被自动计算并包含在结果中');

        // Verify - 验证自动计算的调用顺序
        verifyInOrder([
          // 1. 首先尝试从数据库获取已有的统计数据
          mockReadingStatsRepository.getReadingStats('bookmark-bug-test'),
          // 2. 获取失败后，获取文章内容
          mockArticleRepository.getBookmarkArticle('bookmark-bug-test'),
          // 3. 计算并保存新的统计数据
          mockReadingStatsRepository.calculateAndSaveReadingStats(
              'bookmark-bug-test', htmlContent),
        ]);
      });

      test('should not recalculate when reading stats already exist', () async {
        // Arrange
        final testBookmark = Bookmark(
          id: 'bookmark-existing-stats',
          title: 'Existing Stats Bookmark',
          url: 'https://example.com',
          siteName: 'example.com',
          description: 'A bookmark with existing stats',
          isMarked: false,
          isArchived: false,
          readProgress: 100,
          labels: const [],
          created: DateTime.parse('2024-01-01T00:00:00Z'),
          imageUrl: null,
        );

        const existingStats = ReadingStatsForView(
          readableCharCount: 1200,
          estimatedReadingTimeMinutes: 3.0,
        );

        // Mock设置
        when(mockApiClient.getBookmarks(ids: ['bookmark-existing-stats']))
            .thenAnswer((_) async => Success([testBookmark]));

        // 数据库中已有统计数据
        when(mockReadingStatsRepository
                .getReadingStats('bookmark-existing-stats'))
            .thenAnswer((_) async => const Success(existingStats));

        // Act
        final result =
            await repository.loadBookmarksByIds(['bookmark-existing-stats']);

        // Assert
        expect(result.isSuccess(), true);
        final bookmarks = result.getOrNull()!;
        expect(bookmarks[0].stats, existingStats);

        // Verify - 不应该尝试获取文章内容或重新计算
        verify(mockReadingStatsRepository
                .getReadingStats('bookmark-existing-stats'))
            .called(1);
        verifyNever(mockArticleRepository.getBookmarkArticle(any));
        verifyNever(
            mockReadingStatsRepository.calculateAndSaveReadingStats(any, any));
      });
    });

    tearDown(() {
      repository.dispose();
    });
  });
}
