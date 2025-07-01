import 'package:flutter_test/flutter_test.dart';
import 'package:readeck_app/domain/models/daily_read_history/daily_read_history.dart';
import '../../../helpers/test_database_helper.dart';
import '../../../fixtures/test_data.dart';

void main() {
  group('DatabaseService Tests', () {
    late TestDatabaseService databaseService;

    setUpAll(() {
      setupTestEnvironment();
    });

    setUp(() async {
      databaseService = TestDatabaseService();
      await databaseService.open();
    });

    tearDown(() async {
      if (databaseService.isOpen()) {
        await databaseService.clearAllData();
      }
    });

    group('Database Connection', () {
      test('should open database successfully', () async {
        expect(databaseService.isOpen(), true);
      });

      test('should handle operations when database is not open', () async {
        final closedService = TestDatabaseService();
        // 不调用 open()

        final result =
            await closedService.insertDailyReadHistory(TestBookmarkIds.sample1);

        expect(result.isError(), true);
        expect(result.exceptionOrNull()!.toString(),
            contains('Database is not open'));
      });
    });

    group('Daily Read History Operations', () {
      test('should insert daily read history successfully', () async {
        // Arrange
        const bookmarkIds = TestBookmarkIds.sample1;

        // Act
        final result =
            await databaseService.insertDailyReadHistory(bookmarkIds);

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull(), isA<int>());
        expect(result.getOrNull()! > 0, true);
      });

      test('should insert empty bookmark ids list', () async {
        // Arrange
        const bookmarkIds = TestBookmarkIds.empty;

        // Act
        final result =
            await databaseService.insertDailyReadHistory(bookmarkIds);

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull(), isA<int>());
      });

      test('should insert large bookmark ids list', () async {
        // Arrange
        const bookmarkIds = TestBookmarkIds.large;

        // Act
        final result =
            await databaseService.insertDailyReadHistory(bookmarkIds);

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull(), isA<int>());
      });

      test('should retrieve daily read histories', () async {
        // Arrange
        await databaseService.insertDailyReadHistory(TestBookmarkIds.sample1);
        await databaseService.insertDailyReadHistory(TestBookmarkIds.sample2);

        // Act
        final result = await databaseService.getDailyReadHistories();

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull()!.length, 2);
        expect(result.getOrNull()![0], isA<DailyReadHistory>());
        expect(result.getOrNull()![1], isA<DailyReadHistory>());
      });

      test('should retrieve daily read histories with limit', () async {
        // Arrange
        await databaseService.insertDailyReadHistory(TestBookmarkIds.sample1);
        await databaseService.insertDailyReadHistory(TestBookmarkIds.sample2);
        await databaseService.insertDailyReadHistory(TestBookmarkIds.single);

        // Act
        final result = await databaseService.getDailyReadHistories(limit: 2);

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull()!.length, 2);
      });

      test('should retrieve daily read histories with order by', () async {
        // Arrange
        await databaseService.insertDailyReadHistory(TestBookmarkIds.sample1);
        await databaseService.insertDailyReadHistory(TestBookmarkIds.sample2);

        // Act
        final result = await databaseService.getDailyReadHistories(
          orderBy: 'id DESC',
        );

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull()!.length, 2);
        // 验证排序：最新插入的应该在前面
        expect(result.getOrNull()![0].id > result.getOrNull()![1].id, true);
      });

      test('should update daily read history successfully', () async {
        // Arrange
        final insertResult = await databaseService
            .insertDailyReadHistory(TestBookmarkIds.sample1);
        final insertedId = insertResult.getOrNull()!;

        final historyToUpdate = DailyReadHistory(
          id: insertedId,
          createdDate: DateTime.now(),
          bookmarkIds: TestBookmarkIds.sample2,
        );

        // Act
        final updateResult =
            await databaseService.updateDailyReadHistory(historyToUpdate);

        // Assert
        expect(updateResult.isSuccess(), true);
        expect(updateResult.getOrNull(), 1); // 应该更新1行

        // 验证更新后的数据
        final getResult = await databaseService.getDailyReadHistories(
          where: 'id = ?',
          whereArgs: [insertedId],
        );
        expect(getResult.isSuccess(), true);
        expect(getResult.getOrNull()!.length, 1);
        expect(getResult.getOrNull()![0].bookmarkIds, TestBookmarkIds.sample2);
      });

      test('should return empty list when no histories exist', () async {
        // Act
        final result = await databaseService.getDailyReadHistories();

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull()!.isEmpty, true);
      });
    });

    group('Bookmark Article Operations', () {
      test('should insert bookmark article successfully', () async {
        // Arrange
        final article = TestBookmarkArticleData.createSample();

        // Act
        final result =
            await databaseService.insertOrUpdateBookmarkArticle(article);

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull(), isA<int>());
        expect(result.getOrNull()! > 0, true);
      });

      test('should update existing bookmark article', () async {
        // Arrange
        final article = TestBookmarkArticleData.createSample(
          bookmarkId: 'test-bookmark-1',
          article: 'Original content',
        );
        await databaseService.insertOrUpdateBookmarkArticle(article);

        final updatedArticle = TestBookmarkArticleData.createSample(
          bookmarkId: 'test-bookmark-1',
          article: 'Updated content',
          translate: 'Translated content',
        );

        // Act
        final result =
            await databaseService.insertOrUpdateBookmarkArticle(updatedArticle);

        // Assert
        expect(result.isSuccess(), true);

        // 验证更新后的数据
        final getResult = await databaseService
            .getBookmarkArticleByBookmarkId('test-bookmark-1');
        expect(getResult.isSuccess(), true);
        expect(getResult.getOrNull()!.article, 'Updated content');
        expect(getResult.getOrNull()!.translate, 'Translated content');
      });

      test('should retrieve bookmark article by id', () async {
        // Arrange
        final article = TestBookmarkArticleData.createSample(
          bookmarkId: 'test-bookmark-1',
          article: 'Test article content',
          translate: 'Translated content',
        );
        await databaseService.insertOrUpdateBookmarkArticle(article);

        // Act
        final result = await databaseService
            .getBookmarkArticleByBookmarkId('test-bookmark-1');

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull()!.bookmarkId, 'test-bookmark-1');
        expect(result.getOrNull()!.article, 'Test article content');
        expect(result.getOrNull()!.translate, 'Translated content');
        expect(result.getOrNull()!.id, isA<int>());
        expect(result.getOrNull()!.createdDate, isA<DateTime>());
      });

      test('should return failure when bookmark article not found', () async {
        // Act
        final result = await databaseService
            .getBookmarkArticleByBookmarkId('non-existent');

        // Assert
        expect(result.isError(), true);
        expect(result.exceptionOrNull()!.toString(),
            contains('No cached article found'));
      });

      test('should delete bookmark article successfully', () async {
        // Arrange
        final article = TestBookmarkArticleData.createSample(
          bookmarkId: 'test-bookmark-1',
        );
        await databaseService.insertOrUpdateBookmarkArticle(article);

        // Act
        final deleteResult =
            await databaseService.deleteBookmarkArticle('test-bookmark-1');

        // Assert
        expect(deleteResult.isSuccess(), true);
        expect(deleteResult.getOrNull(), 1); // 应该删除1行

        // 验证文章已被删除
        final getResult = await databaseService
            .getBookmarkArticleByBookmarkId('test-bookmark-1');
        expect(getResult.isError(), true);
      });

      test('should return 0 when deleting non-existent bookmark article',
          () async {
        // Act
        final result =
            await databaseService.deleteBookmarkArticle('non-existent');

        // Assert
        expect(result.isSuccess(), true);
        expect(result.getOrNull(), 0); // 应该删除0行
      });

      test('should handle article without translate field', () async {
        // Arrange
        final article = TestBookmarkArticleData.createSample(
          bookmarkId: 'test-bookmark-1',
          article: 'Test content',
          translate: null,
        );

        // Act
        final insertResult =
            await databaseService.insertOrUpdateBookmarkArticle(article);
        final getResult = await databaseService
            .getBookmarkArticleByBookmarkId('test-bookmark-1');

        // Assert
        expect(insertResult.isSuccess(), true);
        expect(getResult.isSuccess(), true);
        expect(getResult.getOrNull()!.translate, null);
      });
    });

    group('Data Management Operations', () {
      test('should clear all data successfully', () async {
        // Arrange
        await databaseService.insertDailyReadHistory(TestBookmarkIds.sample1);
        await databaseService.insertDailyReadHistory(TestBookmarkIds.sample2);

        final article1 =
            TestBookmarkArticleData.createSample(bookmarkId: 'bookmark1');
        final article2 =
            TestBookmarkArticleData.createSample(bookmarkId: 'bookmark2');
        await databaseService.insertOrUpdateBookmarkArticle(article1);
        await databaseService.insertOrUpdateBookmarkArticle(article2);

        // Act
        final result = await databaseService.clearAllData();

        // Assert
        expect(result.isSuccess(), true);

        // 验证所有数据已被清空
        final historiesResult = await databaseService.getDailyReadHistories();
        expect(historiesResult.isSuccess(), true);
        expect(historiesResult.getOrNull()!.isEmpty, true);

        final articleResult =
            await databaseService.getBookmarkArticleByBookmarkId('bookmark1');
        expect(articleResult.isError(), true);
      });

      test('should clear empty database without error', () async {
        // Act
        final result = await databaseService.clearAllData();

        // Assert
        expect(result.isSuccess(), true);
      });
    });

    group('Concurrent Operations', () {
      test('should handle multiple concurrent inserts', () async {
        // Arrange
        final futures = <Future>[];

        // Act
        for (int i = 0; i < 10; i++) {
          futures.add(databaseService.insertDailyReadHistory(['bookmark$i']));
        }

        final results = await Future.wait(futures);

        // Assert
        for (final result in results) {
          expect(result.isSuccess(), true);
        }

        final getResult = await databaseService.getDailyReadHistories();
        expect(getResult.isSuccess(), true);
        expect(getResult.getOrNull()!.length, 10);
      });

      test('should handle concurrent bookmark article operations', () async {
        // Arrange
        final futures = <Future>[];

        // Act
        for (int i = 0; i < 5; i++) {
          final article = TestBookmarkArticleData.createSample(
            bookmarkId: 'bookmark$i',
            article: 'Content $i',
          );
          futures.add(databaseService.insertOrUpdateBookmarkArticle(article));
        }

        final results = await Future.wait(futures);

        // Assert
        for (final result in results) {
          expect(result.isSuccess(), true);
        }

        // 验证所有文章都已插入
        for (int i = 0; i < 5; i++) {
          final getResult = await databaseService
              .getBookmarkArticleByBookmarkId('bookmark$i');
          expect(getResult.isSuccess(), true);
          expect(getResult.getOrNull()!.article, 'Content $i');
        }
      });
    });

    group('Database Schema and Migration Tests', () {
      test('should create all tables on first installation', () async {
        // Arrange - 创建一个新的数据库服务实例来模拟首次安装
        final newDatabaseService = TestDatabaseService();

        // Act - 打开数据库（触发onCreate）
        await newDatabaseService.open();

        // Assert - 验证数据库已打开
        expect(newDatabaseService.isOpen(), true);

        // 验证可以执行基本操作（间接验证表已创建）
        final historyResult =
            await newDatabaseService.insertDailyReadHistory(['test']);
        expect(historyResult.isSuccess(), true);

        final article = TestBookmarkArticleData.createSample();
        final articleResult =
            await newDatabaseService.insertOrUpdateBookmarkArticle(article);
        expect(articleResult.isSuccess(), true);

        // 清理
        await newDatabaseService.clearAllData();
      });

      test('should handle database schema validation', () async {
        // Arrange
        final service = TestDatabaseService();
        await service.open();

        // Act & Assert - 验证表结构通过执行各种操作

        // 测试每日阅读历史表
        final historyResult =
            await service.insertDailyReadHistory(TestBookmarkIds.sample1);
        expect(historyResult.isSuccess(), true);

        final getHistoryResult = await service.getDailyReadHistories();
        expect(getHistoryResult.isSuccess(), true);
        expect(getHistoryResult.getOrNull()!.isNotEmpty, true);

        // 测试书签文章表
        final article = TestBookmarkArticleData.createSample();
        final articleResult =
            await service.insertOrUpdateBookmarkArticle(article);
        expect(articleResult.isSuccess(), true);

        final getArticleResult =
            await service.getBookmarkArticleByBookmarkId(article.bookmarkId);
        expect(getArticleResult.isSuccess(), true);

        // 清理
        await service.clearAllData();
      });

      test('should maintain data integrity during operations', () async {
        // Arrange
        final service = TestDatabaseService();
        await service.open();

        // 插入测试数据
        await service.insertDailyReadHistory(TestBookmarkIds.sample1);
        await service.insertDailyReadHistory(TestBookmarkIds.sample2);

        final article1 =
            TestBookmarkArticleData.createSample(bookmarkId: 'test1');
        final article2 =
            TestBookmarkArticleData.createSample(bookmarkId: 'test2');
        await service.insertOrUpdateBookmarkArticle(article1);
        await service.insertOrUpdateBookmarkArticle(article2);

        // Act - 验证数据完整性
        final historiesResult = await service.getDailyReadHistories();
        expect(historiesResult.isSuccess(), true);
        expect(historiesResult.getOrNull()!.length, 2);

        final article1Result =
            await service.getBookmarkArticleByBookmarkId('test1');
        expect(article1Result.isSuccess(), true);

        final article2Result =
            await service.getBookmarkArticleByBookmarkId('test2');
        expect(article2Result.isSuccess(), true);

        // 清理
        await service.clearAllData();
      });

      test('should handle database constraints properly', () async {
        // Arrange
        final service = TestDatabaseService();
        await service.open();

        final article =
            TestBookmarkArticleData.createSample(bookmarkId: 'unique-test');

        // Act - 插入相同bookmarkId的文章（测试UNIQUE约束）
        final firstInsert =
            await service.insertOrUpdateBookmarkArticle(article);
        expect(firstInsert.isSuccess(), true);

        final updatedArticle = TestBookmarkArticleData.createSample(
          bookmarkId: 'unique-test',
          article: 'Updated content',
        );

        // 应该更新而不是插入新记录
        final secondInsert =
            await service.insertOrUpdateBookmarkArticle(updatedArticle);
        expect(secondInsert.isSuccess(), true);

        // 验证只有一条记录且内容已更新
        final getResult =
            await service.getBookmarkArticleByBookmarkId('unique-test');
        expect(getResult.isSuccess(), true);
        expect(getResult.getOrNull()!.article, 'Updated content');

        // 清理
        await service.clearAllData();
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle very long article content', () async {
        // Arrange
        final longContent = 'A' * 10000; // 10KB 的内容
        final article = TestBookmarkArticleData.createSample(
          bookmarkId: 'long-content',
          article: longContent,
        );

        // Act
        final insertResult =
            await databaseService.insertOrUpdateBookmarkArticle(article);
        final getResult = await databaseService
            .getBookmarkArticleByBookmarkId('long-content');

        // Assert
        expect(insertResult.isSuccess(), true);
        expect(getResult.isSuccess(), true);
        expect(getResult.getOrNull()!.article.length, 10000);
      });

      test('should handle special characters in content', () async {
        // Arrange
        const specialContent =
            'Content with special chars: 中文, émojis 🎉, quotes "test", newlines\nand tabs\t';
        final article = TestBookmarkArticleData.createSample(
          bookmarkId: 'special-chars',
          article: specialContent,
        );

        // Act
        final insertResult =
            await databaseService.insertOrUpdateBookmarkArticle(article);
        final getResult = await databaseService
            .getBookmarkArticleByBookmarkId('special-chars');

        // Assert
        expect(insertResult.isSuccess(), true);
        expect(getResult.isSuccess(), true);
        expect(getResult.getOrNull()!.article, specialContent);
      });

      test('should handle large number of bookmark ids', () async {
        // Arrange
        final largeBookmarkIds =
            List.generate(1000, (index) => 'bookmark$index');

        // Act
        final result =
            await databaseService.insertDailyReadHistory(largeBookmarkIds);

        // Assert
        expect(result.isSuccess(), true);

        final getResult = await databaseService.getDailyReadHistories();
        expect(getResult.isSuccess(), true);
        expect(getResult.getOrNull()!.length, 1);
        expect(getResult.getOrNull()![0].bookmarkIds.length, 1000);
      });
    });
  });
}
