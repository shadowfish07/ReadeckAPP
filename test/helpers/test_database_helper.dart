import 'dart:async';
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:readeck_app/data/service/database_service.dart';
import 'package:result_dart/result_dart.dart';
import 'package:readeck_app/domain/models/daily_read_history/daily_read_history.dart';
import 'package:readeck_app/domain/models/bookmark_article/bookmark_article.dart';
import 'test_logger_helper.dart';

/// 静态标志，确保只初始化一次数据库工厂
bool _isTestDatabaseInitialized = false;

/// 测试用的数据库服务，使用内存数据库
class TestDatabaseService extends DatabaseService {
  Database? _testDatabase;

  @override
  bool isOpen() {
    return _testDatabase?.isOpen ?? false;
  }

  @override
  Future<void> open() async {
    // 只初始化一次数据库工厂，避免重复警告
    if (!_isTestDatabaseInitialized) {
      // 使用 Zone 来抑制 sqflite 警告输出
      await runZoned(() async {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        _isTestDatabaseInitialized = true;
      }, zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          // 过滤掉 sqflite 警告信息
          if (!line.contains('*** sqflite warning ***') &&
              !line.contains('You are changing sqflite default factory') &&
              !line.contains('Be aware of the potential side effects')) {
            parent.print(zone, line);
          }
        },
      ));
    }

    // 使用内存数据库进行测试
    _testDatabase = await openDatabase(
      inMemoryDatabasePath,
      version: 2,
      onCreate: (db, version) async {
        // 创建每日阅读历史表
        await db.execute(
          '''CREATE TABLE daily_read_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_date TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    bookmark_ids TEXT NOT NULL
);
''',
        );

        // 创建书签文章缓存表
        await db.execute(
          '''CREATE TABLE bookmark_article (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bookmark_id TEXT NOT NULL,
    article TEXT NOT NULL,
    translate TEXT,
    created_date TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    UNIQUE(bookmark_id)
);
''',
        );
      },
    );
  }

  // 重写所有数据库操作方法以使用测试数据库
  @override
  Future<Result<int>> insertDailyReadHistory(List<String> bookmarkIds) async {
    if (_testDatabase == null) {
      return Failure(Exception("Database is not open"));
    }

    try {
      final id = await _testDatabase!.insert(
          'daily_read_history', {'bookmark_ids': jsonEncode(bookmarkIds)});
      appLogger.i(
          "Inserted daily read history with id: $id. bookmarkIds: $bookmarkIds");
      return Success(id);
    } on Exception catch (e) {
      appLogger.e(
          "Failed to insert daily read history. bookmarkIds: $bookmarkIds",
          error: e);
      return Failure(e);
    } catch (e) {
      appLogger.e(
          "Failed to insert daily read history. bookmarkIds: $bookmarkIds",
          error: e);
      return Failure(Exception(e));
    }
  }

  @override
  Future<Result<List<DailyReadHistory>>> getDailyReadHistories({
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (_testDatabase == null) {
      return Failure(Exception("Database is not open"));
    }
    try {
      final List<Map<String, dynamic>> maps = await _testDatabase!.query(
        'daily_read_history',
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
      appLogger.i("Retrieved ${maps.length} daily read histories. data: $maps");
      final List<DailyReadHistory> histories = [];
      for (final map in maps) {
        histories.add(DailyReadHistory.fromJson(map));
      }
      return Success(histories);
    } on Exception catch (e) {
      appLogger.e("Failed to get daily read histories", error: e);
      return Failure(e);
    } catch (e) {
      appLogger.e("Failed to get daily read histories", error: e);
      return Failure(Exception(e));
    }
  }

  @override
  Future<Result<int>> updateDailyReadHistory(DailyReadHistory obj) async {
    if (_testDatabase == null) {
      return Failure(Exception("Database is not open"));
    }

    try {
      final count = await _testDatabase!.update(
        'daily_read_history',
        obj.toJson(),
        where: 'id = ?',
        whereArgs: [obj.id],
      );
      appLogger.i("Updated daily read history with id: ${obj.id}. data: $obj");
      return Success(count);
    } on Exception catch (e) {
      appLogger.e("Failed to update daily read history. data: $obj", error: e);
      return Failure(e);
    } catch (e) {
      appLogger.e("Failed to update daily read history. data: $obj", error: e);
      return Failure(Exception(e));
    }
  }

  @override
  Future<Result<int>> insertOrUpdateBookmarkArticle(
      BookmarkArticle article) async {
    if (_testDatabase == null) {
      return Failure(Exception("Database is not open"));
    }

    try {
      final data = {
        'bookmark_id': article.bookmarkId,
        'article': article.article,
        'translate': article.translate,
        'created_date': article.createdDate.toIso8601String(),
      };

      final id = await _testDatabase!.insert(
        'bookmark_article',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      appLogger.i(
          "Inserted/Updated bookmark article with id: $id. bookmarkId: ${article.bookmarkId}");
      return Success(id);
    } on Exception catch (e) {
      appLogger.e(
          "Failed to insert/update bookmark article. bookmarkId: ${article.bookmarkId}",
          error: e);
      return Failure(e);
    } catch (e) {
      appLogger.e(
          "Failed to insert/update bookmark article. bookmarkId: ${article.bookmarkId}",
          error: e);
      return Failure(Exception(e));
    }
  }

  @override
  Future<Result<BookmarkArticle>> getBookmarkArticleByBookmarkId(
      String bookmarkId) async {
    if (_testDatabase == null) {
      return Failure(Exception("Database is not open"));
    }

    try {
      final List<Map<String, dynamic>> maps = await _testDatabase!.query(
        'bookmark_article',
        where: 'bookmark_id = ?',
        whereArgs: [bookmarkId],
        limit: 1,
      );

      if (maps.isEmpty) {
        appLogger.i("No cached article found for bookmarkId: $bookmarkId");
        return Failure(
            Exception("No cached article found for bookmarkId: $bookmarkId"));
      }

      final map = maps.first;
      final article = BookmarkArticle(
        id: map['id'] as int?,
        bookmarkId: map['bookmark_id'] as String,
        article: map['article'] as String,
        translate: map['translate'] as String?,
        createdDate: DateTime.parse(map['created_date'] as String),
      );

      appLogger.i("Retrieved cached article for bookmarkId: $bookmarkId");
      return Success(article);
    } on Exception catch (e) {
      appLogger.e("Failed to get bookmark article. bookmarkId: $bookmarkId",
          error: e);
      return Failure(e);
    } catch (e) {
      appLogger.e("Failed to get bookmark article. bookmarkId: $bookmarkId",
          error: e);
      return Failure(Exception(e));
    }
  }

  @override
  Future<Result<int>> deleteBookmarkArticle(String bookmarkId) async {
    if (_testDatabase == null) {
      return Failure(Exception("Database is not open"));
    }

    try {
      final count = await _testDatabase!.delete(
        'bookmark_article',
        where: 'bookmark_id = ?',
        whereArgs: [bookmarkId],
      );

      appLogger
          .i("Deleted $count bookmark article(s) for bookmarkId: $bookmarkId");
      return Success(count);
    } on Exception catch (e) {
      appLogger.e("Failed to delete bookmark article. bookmarkId: $bookmarkId",
          error: e);
      return Failure(e);
    } catch (e) {
      appLogger.e("Failed to delete bookmark article. bookmarkId: $bookmarkId",
          error: e);
      return Failure(Exception(e));
    }
  }

  @override
  Future<Result<void>> clearAllData() async {
    if (_testDatabase == null) {
      return Failure(Exception("Database is not open"));
    }

    try {
      // 清空每日阅读历史表
      await _testDatabase!.delete('daily_read_history');
      // 清空书签文章缓存表
      await _testDatabase!.delete('bookmark_article');
      appLogger.i("Cleared all data from database");
      return const Success(unit);
    } on Exception catch (e) {
      appLogger.e("Failed to clear all data from database", error: e);
      return Failure(e);
    } catch (e) {
      appLogger.e("Failed to clear all data from database", error: e);
      return Failure(Exception(e));
    }
  }
}

/// 设置测试环境
void setupTestEnvironment() {
  // 使用新的测试日志管理器
  setupTestLogger();
}
