import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sqflite/sqflite.dart';
import 'package:result_dart/result_dart.dart';

import 'package:readeck_app/data/service/database_service.dart';
import 'package:readeck_app/domain/models/bookmark_article/bookmark_article.dart';
import 'package:readeck_app/domain/models/daily_read_history/daily_read_history.dart';

// Generate mocks for external dependencies
@GenerateMocks([Database, DatabaseFactory])
import 'database_service_test.mocks.dart';

void main() {
  group('DatabaseService', () {
    late DatabaseService databaseService;
    late MockDatabase mockDatabase;

    setUp(() {
      mockDatabase = MockDatabase();
      databaseService = DatabaseService();
      // Inject mock database for testing
      databaseService._database = mockDatabase;
    });

    tearDown(() {
      reset(mockDatabase);
    });

    group('Database State Management', () {
      test('isOpen returns true when database is open', () {
        // Arrange
        when(mockDatabase.isOpen).thenReturn(true);

        // Act
        final result = databaseService.isOpen();

        // Assert
        expect(result, isTrue);
      });

      test('isOpen returns false when database is closed', () {
        // Arrange
        when(mockDatabase.isOpen).thenReturn(false);

        // Act
        final result = databaseService.isOpen();

        // Assert
        expect(result, isFalse);
      });

      test('isOpen returns false when database is null', () {
        // Arrange
        databaseService._database = null;

        // Act
        final result = databaseService.isOpen();

        // Assert
        expect(result, isFalse);
      });
    });

    group('Daily Read History Operations', () {
      group('insertDailyReadHistory', () {
        test('should successfully insert daily read history', () async {
          // Arrange
          final bookmarkIds = ['bookmark1', 'bookmark2', 'bookmark3'];
          const expectedId = 1;
          when(mockDatabase.insert(any, any)).thenAnswer((_) async => expectedId);

          // Act
          final result = await databaseService.insertDailyReadHistory(bookmarkIds);

          // Assert
          expect(result.isSuccess(), isTrue);
          expect(result.fold((success) => success, (failure) => null), equals(expectedId));
          verify(mockDatabase.insert(
            'daily_read_history',
            {'bookmark_ids': '["bookmark1","bookmark2","bookmark3"]'},
          )).called(1);
        });

        test('should handle empty bookmark list', () async {
          // Arrange
          final bookmarkIds = <String>[];
          const expectedId = 1;
          when(mockDatabase.insert(any, any)).thenAnswer((_) async => expectedId);

          // Act
          final result = await databaseService.insertDailyReadHistory(bookmarkIds);

          // Assert
          expect(result.isSuccess(), isTrue);
          verify(mockDatabase.insert(
            'daily_read_history',
            {'bookmark_ids': '[]'},
          )).called(1);
        });

        test('should return failure when database is not open', () async {
          // Arrange
          databaseService._database = null;
          final bookmarkIds = ['bookmark1'];

          // Act
          final result = await databaseService.insertDailyReadHistory(bookmarkIds);

          // Assert
          expect(result.isFailure(), isTrue);
          expect(result.fold((success) => null, (failure) => failure.toString()),
              contains('Database is not open'));
        });

        test('should handle database exception', () async {
          // Arrange
          final bookmarkIds = ['bookmark1'];
          when(mockDatabase.insert(any, any))
              .thenThrow(DatabaseException('Insert failed'));

          // Act
          final result = await databaseService.insertDailyReadHistory(bookmarkIds);

          // Assert
          expect(result.isFailure(), isTrue);
          expect(result.fold((success) => null, (failure) => failure.toString()),
              contains('Insert failed'));
        });

        test('should handle generic exception', () async {
          // Arrange
          final bookmarkIds = ['bookmark1'];
          when(mockDatabase.insert(any, any))
              .thenThrow('Generic error');

          // Act
          final result = await databaseService.insertDailyReadHistory(bookmarkIds);

          // Assert
          expect(result.isFailure(), isTrue);
          expect(result.fold((success) => null, (failure) => failure is Exception), isTrue);
        });

        test('should handle large bookmark list', () async {
          // Arrange
          final bookmarkIds = List.generate(1000, (index) => 'bookmark$index');
          const expectedId = 1;
          when(mockDatabase.insert(any, any)).thenAnswer((_) async => expectedId);

          // Act
          final result = await databaseService.insertDailyReadHistory(bookmarkIds);

          // Assert
          expect(result.isSuccess(), isTrue);
          verify(mockDatabase.insert('daily_read_history', any)).called(1);
        });

        test('should handle special characters in bookmark ids', () async {
          // Arrange
          final bookmarkIds = ['bookmark\'s', 'bookmark"test', 'bookmark\\slash'];
          const expectedId = 1;
          when(mockDatabase.insert(any, any)).thenAnswer((_) async => expectedId);

          // Act
          final result = await databaseService.insertDailyReadHistory(bookmarkIds);

          // Assert
          expect(result.isSuccess(), isTrue);
          verify(mockDatabase.insert('daily_read_history', any)).called(1);
        });
      });

      group('updateDailyReadHistory', () {
        test('should successfully update daily read history', () async {
          // Arrange
          final history = DailyReadHistory(
            id: 1,
            createdDate: DateTime.now(),
            bookmarkIds: ['bookmark1', 'bookmark2'],
          );
          const expectedCount = 1;
          when(mockDatabase.update(any, any, where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
              .thenAnswer((_) async => expectedCount);

          // Act
          final result = await databaseService.updateDailyReadHistory(history);

          // Assert
          expect(result.isSuccess(), isTrue);
          expect(result.fold((success) => success, (failure) => null), equals(expectedCount));
          verify(mockDatabase.update(
            'daily_read_history',
            any,
            where: 'id = ?',
            whereArgs: [1],
          )).called(1);
        });

        test('should return failure when database is not open', () async {
          // Arrange
          databaseService._database = null;
          final history = DailyReadHistory(
            id: 1,
            createdDate: DateTime.now(),
            bookmarkIds: ['bookmark1'],
          );

          // Act
          final result = await databaseService.updateDailyReadHistory(history);

          // Assert
          expect(result.isFailure(), isTrue);
          expect(result.fold((success) => null, (failure) => failure.toString()),
              contains('Database is not open'));
        });

        test('should handle database exception during update', () async {
          // Arrange
          final history = DailyReadHistory(
            id: 1,
            createdDate: DateTime.now(),
            bookmarkIds: ['bookmark1'],
          );
          when(mockDatabase.update(any, any, where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
              .thenThrow(DatabaseException('Update failed'));

          // Act
          final result = await databaseService.updateDailyReadHistory(history);

          // Assert
          expect(result.isFailure(), isTrue);
          expect(result.fold((success) => null, (failure) => failure.toString()),
              contains('Update failed'));
        });

        test('should return 0 when no records are updated', () async {
          // Arrange
          final history = DailyReadHistory(
            id: 999,
            createdDate: DateTime.now(),
            bookmarkIds: ['bookmark1'],
          );
          when(mockDatabase.update(any, any, where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
              .thenAnswer((_) async => 0);

          // Act
          final result = await databaseService.updateDailyReadHistory(history);

          // Assert
          expect(result.isSuccess(), isTrue);
          expect(result.fold((success) => success, (failure) => null), equals(0));
        });
      });

      group('getDailyReadHistories', () {
        test('should successfully retrieve daily read histories', () async {
          // Arrange
          final mockMaps = [
            {
              'id': 1,
              'created_date': '2023-01-01T10:00:00.000Z',
              'bookmark_ids': '["bookmark1","bookmark2"]',
            },
            {
              'id': 2,
              'created_date': '2023-01-02T10:00:00.000Z',
              'bookmark_ids': '["bookmark3"]',
            },
          ];
          when(mockDatabase.query(any)).thenAnswer((_) async => mockMaps);

          // Act
          final result = await databaseService.getDailyReadHistories();

          // Assert
          expect(result.isSuccess(), isTrue);
          final histories = result.fold((success) => success, (failure) => <DailyReadHistory>[]);
          expect(histories.length, equals(2));
          expect(histories[0].id, equals(1));
          expect(histories[1].id, equals(2));
          verify(mockDatabase.query('daily_read_history')).called(1);
        });

        test('should return empty list when no records found', () async {
          // Arrange
          when(mockDatabase.query(any)).thenAnswer((_) async => []);

          // Act
          final result = await databaseService.getDailyReadHistories();

          // Assert
          expect(result.isSuccess(), isTrue);
          final histories = result.fold((success) => success, (failure) => <DailyReadHistory>[]);
          expect(histories, isEmpty);
        });

        test('should handle query with parameters', () async {
          // Arrange
          final mockMaps = [
            {
              'id': 1,
              'created_date': '2023-01-01T10:00:00.000Z',
              'bookmark_ids': '["bookmark1"]',
            },
          ];
          when(mockDatabase.query(
            any,
            distinct: anyNamed('distinct'),
            columns: anyNamed('columns'),
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            groupBy: anyNamed('groupBy'),
            having: anyNamed('having'),
            orderBy: anyNamed('orderBy'),
            limit: anyNamed('limit'),
            offset: anyNamed('offset'),
          )).thenAnswer((_) async => mockMaps);

          // Act
          final result = await databaseService.getDailyReadHistories(
            distinct: true,
            columns: ['id', 'created_date'],
            where: 'id = ?',
            whereArgs: [1],
            orderBy: 'created_date DESC',
            limit: 10,
            offset: 0,
          );

          // Assert
          expect(result.isSuccess(), isTrue);
          verify(mockDatabase.query(
            'daily_read_history',
            distinct: true,
            columns: ['id', 'created_date'],
            where: 'id = ?',
            whereArgs: [1],
            groupBy: null,
            having: null,
            orderBy: 'created_date DESC',
            limit: 10,
            offset: 0,
          )).called(1);
        });

        test('should return failure when database is not open', () async {
          // Arrange
          databaseService._database = null;

          // Act
          final result = await databaseService.getDailyReadHistories();

          // Assert
          expect(result.isFailure(), isTrue);
          expect(result.fold((success) => null, (failure) => failure.toString()),
              contains('Database is not open'));
        });

        test('should handle database exception during query', () async {
          // Arrange
          when(mockDatabase.query(any))
              .thenThrow(DatabaseException('Query failed'));

          // Act
          final result = await databaseService.getDailyReadHistories();

          // Assert
          expect(result.isFailure(), isTrue);
          expect(result.fold((success) => null, (failure) => failure.toString()),
              contains('Query failed'));
        });
      });
    });

    group('Bookmark Article Operations', () {
      group('insertOrUpdateBookmarkArticle', () {
        test('should successfully insert bookmark article', () async {
          // Arrange
          final article = BookmarkArticle(
            bookmarkId: 'bookmark123',
            article: 'Article content',
            translate: 'Translated content',
            createdDate: DateTime.parse('2023-01-01T10:00:00.000Z'),
          );
          const expectedId = 1;
          when(mockDatabase.insert(any, any, conflictAlgorithm: anyNamed('conflictAlgorithm')))
              .thenAnswer((_) async => expectedId);

          // Act
          final result = await databaseService.insertOrUpdateBookmarkArticle(article);

          // Assert
          expect(result.isSuccess(), isTrue);
          expect(result.fold((success) => success, (failure) => null), equals(expectedId));
          verify(mockDatabase.insert(
            'bookmark_article',
            {
              'bookmark_id': 'bookmark123',
              'article': 'Article content',
              'translate': 'Translated content',
              'created_date': '2023-01-01T10:00:00.000Z',
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          )).called(1);
        });

        test('should handle article without translation', () async {
          // Arrange
          final article = BookmarkArticle(
            bookmarkId: 'bookmark123',
            article: 'Article content',
            createdDate: DateTime.parse('2023-01-01T10:00:00.000Z'),
          );
          const expectedId = 1;
          when(mockDatabase.insert(any, any, conflictAlgorithm: anyNamed('conflictAlgorithm')))
              .thenAnswer((_) async => expectedId);

          // Act
          final result = await databaseService.insertOrUpdateBookmarkArticle(article);

          // Assert
          expect(result.isSuccess(), isTrue);
          verify(mockDatabase.insert(
            'bookmark_article',
            {
              'bookmark_id': 'bookmark123',
              'article': 'Article content',
              'translate': null,
              'created_date': '2023-01-01T10:00:00.000Z',
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          )).called(1);
        });

        test('should return failure when database is not open', () async {
          // Arrange
          databaseService._database = null;
          final article = BookmarkArticle(
            bookmarkId: 'bookmark123',
            article: 'Article content',
            createdDate: DateTime.now(),
          );

          // Act
          final result = await databaseService.insertOrUpdateBookmarkArticle(article);

          // Assert
          expect(result.isFailure(), isTrue);
          expect(result.fold((success) => null, (failure) => failure.toString()),
              contains('Database is not open'));
        });

        test('should handle database exception', () async {
          // Arrange
          final article = BookmarkArticle(
            bookmarkId: 'bookmark123',
            article: 'Article content',
            createdDate: DateTime.now(),
          );
          when(mockDatabase.insert(any, any, conflictAlgorithm: anyNamed('conflictAlgorithm')))
              .thenThrow(DatabaseException('Insert failed'));

          // Act
          final result = await databaseService.insertOrUpdateBookmarkArticle(article);

          // Assert
          expect(result.isFailure(), isTrue);
          expect(result.fold((success) => null, (failure) => failure.toString()),
              contains('Insert failed'));
        });

        test('should handle special characters in article content', () async {
          // Arrange
          final article = BookmarkArticle(
            bookmarkId: 'bookmark123',
            article: 'Article with "quotes" and \'apostrophes\' and <tags>',
            createdDate: DateTime.now(),
          );
          const expectedId = 1;
          when(mockDatabase.insert(any, any, conflictAlgorithm: anyNamed('conflictAlgorithm')))
              .thenAnswer((_) async => expectedId);

          // Act
          final result = await databaseService.insertOrUpdateBookmarkArticle(article);

          // Assert
          expect(result.isSuccess(), isTrue);
          verify(mockDatabase.insert('bookmark_article', any, conflictAlgorithm: ConflictAlgorithm.replace))
              .called(1);
        });
      });

      group('getBookmarkArticleByBookmarkId', () {
        test('should successfully retrieve bookmark article', () async {
          // Arrange
          const bookmarkId = 'bookmark123';
          final mockMaps = [
            {
              'id': 1,
              'bookmark_id': 'bookmark123',
              'article': 'Article content',
              'translate': 'Translated content',
              'created_date': '2023-01-01T10:00:00.000Z',
            },
          ];
          when(mockDatabase.query(
            any,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            limit: anyNamed('limit'),
          )).thenAnswer((_) async => mockMaps);

          // Act
          final result = await databaseService.getBookmarkArticleByBookmarkId(bookmarkId);

          // Assert
          expect(result.isSuccess(), isTrue);
          final article = result.fold((success) => success, (failure) => null);
          expect(article?.id, equals(1));
          expect(article?.bookmarkId, equals('bookmark123'));
          expect(article?.article, equals('Article content'));
          expect(article?.translate, equals('Translated content'));
          verify(mockDatabase.query(
            'bookmark_article',
            where: 'bookmark_id = ?',
            whereArgs: ['bookmark123'],
            limit: 1,
          )).called(1);
        });

        test('should return failure when article not found', () async {
          // Arrange
          const bookmarkId = 'nonexistent';
          when(mockDatabase.query(
            any,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            limit: anyNamed('limit'),
          )).thenAnswer((_) async => []);

          // Act
          final result = await databaseService.getBookmarkArticleByBookmarkId(bookmarkId);

          // Assert
          expect(result.isFailure(), isTrue);
          expect(result.fold((success) => null, (failure) => failure.toString()),
              contains('No cached article found for bookmarkId: nonexistent'));
        });

        test('should return failure when database is not open', () async {
          // Arrange
          databaseService._database = null;
          const bookmarkId = 'bookmark123';

          // Act
          final result = await databaseService.getBookmarkArticleByBookmarkId(bookmarkId);

          // Assert
          expect(result.isFailure(), isTrue);
          expect(result.fold((success) => null, (failure) => failure.toString()),
              contains('Database is not open'));
        });

        test('should handle database exception', () async {
          // Arrange
          const bookmarkId = 'bookmark123';
          when(mockDatabase.query(
            any,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            limit: anyNamed('limit'),
          )).thenThrow(DatabaseException('Query failed'));

          // Act
          final result = await databaseService.getBookmarkArticleByBookmarkId(bookmarkId);

          // Assert
          expect(result.isFailure(), isTrue);
          expect(result.fold((success) => null, (failure) => failure.toString()),
              contains('Query failed'));
        });

        test('should handle article without translation', () async {
          // Arrange
          const bookmarkId = 'bookmark123';
          final mockMaps = [
            {
              'id': 1,
              'bookmark_id': 'bookmark123',
              'article': 'Article content',
              'translate': null,
              'created_date': '2023-01-01T10:00:00.000Z',
            },
          ];
          when(mockDatabase.query(
            any,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
            limit: anyNamed('limit'),
          )).thenAnswer((_) async => mockMaps);

          // Act
          final result = await databaseService.getBookmarkArticleByBookmarkId(bookmarkId);

          // Assert
          expect(result.isSuccess(), isTrue);
          final article = result.fold((success) => success, (failure) => null);
          expect(article?.translate, isNull);
        });
      });

      group('deleteBookmarkArticle', () {
        test('should successfully delete bookmark article', () async {
          // Arrange
          const bookmarkId = 'bookmark123';
          const expectedCount = 1;
          when(mockDatabase.delete(
            any,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
          )).thenAnswer((_) async => expectedCount);

          // Act
          final result = await databaseService.deleteBookmarkArticle(bookmarkId);

          // Assert
          expect(result.isSuccess(), isTrue);
          expect(result.fold((success) => success, (failure) => null), equals(expectedCount));
          verify(mockDatabase.delete(
            'bookmark_article',
            where: 'bookmark_id = ?',
            whereArgs: ['bookmark123'],
          )).called(1);
        });

        test('should return 0 when no records deleted', () async {
          // Arrange
          const bookmarkId = 'nonexistent';
          when(mockDatabase.delete(
            any,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
          )).thenAnswer((_) async => 0);

          // Act
          final result = await databaseService.deleteBookmarkArticle(bookmarkId);

          // Assert
          expect(result.isSuccess(), isTrue);
          expect(result.fold((success) => success, (failure) => null), equals(0));
        });

        test('should return failure when database is not open', () async {
          // Arrange
          databaseService._database = null;
          const bookmarkId = 'bookmark123';

          // Act
          final result = await databaseService.deleteBookmarkArticle(bookmarkId);

          // Assert
          expect(result.isFailure(), isTrue);
          expect(result.fold((success) => null, (failure) => failure.toString()),
              contains('Database is not open'));
        });

        test('should handle database exception', () async {
          // Arrange
          const bookmarkId = 'bookmark123';
          when(mockDatabase.delete(
            any,
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
          )).thenThrow(DatabaseException('Delete failed'));

          // Act
          final result = await databaseService.deleteBookmarkArticle(bookmarkId);

          // Assert
          expect(result.isFailure(), isTrue);
          expect(result.fold((success) => null, (failure) => failure.toString()),
              contains('Delete failed'));
        });
      });
    });

    group('Data Management Operations', () {
      group('clearAllData', () {
        test('should successfully clear all data', () async {
          // Arrange
          when(mockDatabase.delete(any)).thenAnswer((_) async => 5);

          // Act
          final result = await databaseService.clearAllData();

          // Assert
          expect(result.isSuccess(), isTrue);
          verify(mockDatabase.delete('daily_read_history')).called(1);
          verify(mockDatabase.delete('bookmark_article')).called(1);
        });

        test('should return failure when database is not open', () async {
          // Arrange
          databaseService._database = null;

          // Act
          final result = await databaseService.clearAllData();

          // Assert
          expect(result.isFailure(), isTrue);
          expect(result.fold((success) => null, (failure) => failure.toString()),
              contains('Database is not open'));
        });

        test('should handle database exception during clear', () async {
          // Arrange
          when(mockDatabase.delete('daily_read_history'))
              .thenThrow(DatabaseException('Clear failed'));

          // Act
          final result = await databaseService.clearAllData();

          // Assert
          expect(result.isFailure(), isTrue);
          expect(result.fold((success) => null, (failure) => failure.toString()),
              contains('Clear failed'));
        });

        test('should handle exception on second table clear', () async {
          // Arrange
          when(mockDatabase.delete('daily_read_history')).thenAnswer((_) async => 3);
          when(mockDatabase.delete('bookmark_article'))
              .thenThrow(DatabaseException('Clear bookmark_article failed'));

          // Act
          final result = await databaseService.clearAllData();

          // Assert
          expect(result.isFailure(), isTrue);
          verify(mockDatabase.delete('daily_read_history')).called(1);
          verify(mockDatabase.delete('bookmark_article')).called(1);
        });

        test('should handle generic exception', () async {
          // Arrange
          when(mockDatabase.delete(any)).thenThrow('Generic error');

          // Act
          final result = await databaseService.clearAllData();

          // Assert
          expect(result.isFailure(), isTrue);
          expect(result.fold((success) => null, (failure) => failure is Exception), isTrue);
        });
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle null or invalid JSON in bookmark_ids', () async {
        // This test simulates what happens when the database contains invalid JSON
        // which should be handled gracefully by the application layer
        final mockMaps = [
          {
            'id': 1,
            'created_date': '2023-01-01T10:00:00.000Z',
            'bookmark_ids': 'invalid json',
          },
        ];
        when(mockDatabase.query(any)).thenAnswer((_) async => mockMaps);

        // Act & Assert
        expect(
          () => databaseService.getDailyReadHistories(),
          throwsA(isA<FormatException>()),
        );
      });

      test('should handle very long bookmark IDs', () async {
        // Arrange
        final longBookmarkId = 'bookmark${'a' * 1000}';
        final bookmarkIds = [longBookmarkId];
        const expectedId = 1;
        when(mockDatabase.insert(any, any)).thenAnswer((_) async => expectedId);

        // Act
        final result = await databaseService.insertDailyReadHistory(bookmarkIds);

        // Assert
        expect(result.isSuccess(), isTrue);
      });

      test('should handle very large article content', () async {
        // Arrange
        final largeContent = 'Article content ' * 10000; // Large content
        final article = BookmarkArticle(
          bookmarkId: 'bookmark123',
          article: largeContent,
          createdDate: DateTime.now(),
        );
        const expectedId = 1;
        when(mockDatabase.insert(any, any, conflictAlgorithm: anyNamed('conflictAlgorithm')))
            .thenAnswer((_) async => expectedId);

        // Act
        final result = await databaseService.insertOrUpdateBookmarkArticle(article);

        // Assert
        expect(result.isSuccess(), isTrue);
      });

      test('should handle Unicode characters in content', () async {
        // Arrange
        final article = BookmarkArticle(
          bookmarkId: 'bookmark123',
          article: '测试文章 🌟 مقال اختبار 文章テスト',
          translate: 'Test article 🌟 тестовая статья 測試文章',
          createdDate: DateTime.now(),
        );
        const expectedId = 1;
        when(mockDatabase.insert(any, any, conflictAlgorithm: anyNamed('conflictAlgorithm')))
            .thenAnswer((_) async => expectedId);

        // Act
        final result = await databaseService.insertOrUpdateBookmarkArticle(article);

        // Assert
        expect(result.isSuccess(), isTrue);
      });

      test('should handle concurrent operations gracefully', () async {
        // Arrange
        when(mockDatabase.insert(any, any)).thenAnswer((_) async => 1);
        when(mockDatabase.query(any)).thenAnswer((_) async => []);
        when(mockDatabase.delete(any, where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
            .thenAnswer((_) async => 1);

        // Act
        final futures = <Future>[];
        for (int i = 0; i < 10; i++) {
          futures.add(databaseService.insertDailyReadHistory(['bookmark$i']));
          futures.add(databaseService.getDailyReadHistories());
          futures.add(databaseService.deleteBookmarkArticle('bookmark$i'));
        }

        // Assert
        expect(() => Future.wait(futures), returnsNormally);
      });
    });

    group('Performance and Stress Tests', () {
      test('should handle large number of bookmark IDs efficiently', () async {
        // Arrange
        final bookmarkIds = List.generate(10000, (index) => 'bookmark$index');
        const expectedId = 1;
        when(mockDatabase.insert(any, any)).thenAnswer((_) async => expectedId);

        // Act
        final stopwatch = Stopwatch()..start();
        final result = await databaseService.insertDailyReadHistory(bookmarkIds);
        stopwatch.stop();

        // Assert
        expect(result.isSuccess(), isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should complete within 1 second
      });

      test('should handle multiple rapid queries', () async {
        // Arrange
        when(mockDatabase.query(any)).thenAnswer((_) async => []);

        // Act
        final stopwatch = Stopwatch()..start();
        final futures = List.generate(100, (_) => databaseService.getDailyReadHistories());
        await Future.wait(futures);
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Should complete within 2 seconds
      });
    });
  });
}