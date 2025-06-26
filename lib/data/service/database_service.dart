import 'dart:convert';
import 'package:path/path.dart';
import 'package:readeck_app/domain/models/bookmark_article/bookmark_article.dart';
import 'package:readeck_app/domain/models/daily_read_history/daily_read_history.dart';
import 'package:readeck_app/main.dart';
import 'package:result_dart/result_dart.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqflite_logger.dart';

class DatabaseService {
  DatabaseService() {
    open();
  }

  static const _kTableDailyReadHistory = 'daily_read_history';
  static const _kTableBookmarkArticle = 'bookmark_article';
  static const _kColumnId = 'id';
  static const _kColumnCreatedDate = 'created_date';
  static const _kColumnBookmarkIds = 'bookmark_ids';
  static const _kColumnBookmarkId = 'bookmark_id';
  static const _kColumnArticle = 'article';
  static const _kColumnTranslate = 'translate';

  Database? _database;

  bool isOpen() {
    return _database?.isOpen ?? false;
  }

  Future<void> open() async {
    var factoryWithLogs = SqfliteDatabaseFactoryLogger(databaseFactory,
        options:
            SqfliteLoggerOptions(type: SqfliteDatabaseFactoryLoggerType.all));

    _database = await factoryWithLogs.openDatabase(
        join(await getDatabasesPath(), 'app_database.db'),
        options: OpenDatabaseOptions(
          onCreate: (db, version) async {
            try {
              final result = await db.rawQuery('SELECT sqlite_version()');
              final version = result.first.values.first;
              appLogger.i('Current SQLite version: $version');
            } catch (e) {
              appLogger.e('Failed to get SQLite version', error: e);
            }
            // 创建每日阅读历史表
            await db.execute(
              '''CREATE TABLE $_kTableDailyReadHistory (
    $_kColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
    $_kColumnCreatedDate TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    $_kColumnBookmarkIds TEXT NOT NULL CHECK (json_valid($_kColumnBookmarkIds))
);
''',
            );
          },
          onUpgrade: (db, oldVersion, newVersion) async {
            appLogger.i(
                'Upgrading database from version $oldVersion to $newVersion');
            switch (oldVersion) {
              case 1:
                // 版本1到版本2：添加书签文章缓存表
                await db.execute(
                  '''CREATE TABLE $_kTableBookmarkArticle (
    $_kColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
    $_kColumnBookmarkId TEXT NOT NULL,
    $_kColumnArticle TEXT NOT NULL,
    $_kColumnTranslate TEXT,
    $_kColumnCreatedDate TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    UNIQUE($_kColumnBookmarkId)
);
''',
                );
                appLogger.i('Created table $_kTableBookmarkArticle');
                appLogger.i('Upgraded from version 1 to 2');
              case 2:
                // 未来版本2到版本3的升级逻辑
                // 当前暂无需要升级的内容
                break;
              default:
                // 处理未知版本
                appLogger.w('未知的数据库版本: $oldVersion -> $newVersion');
                break;
            }
          },
          version: 2,
        ));
  }

  AsyncResult<int> insertDailyReadHistory(List<String> bookmarkIds) async {
    if (_database == null) {
      return Failure(Exception("Database is not open"));
    }

    try {
      final id = await _database!.insert(_kTableDailyReadHistory,
          {_kColumnBookmarkIds: jsonEncode(bookmarkIds)});
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

  AsyncResult<int> updateDailyReadHistory(DailyReadHistory obj) async {
    if (_database == null) {
      return Failure(Exception("Database is not open"));
    }

    try {
      final count = await _database!.update(
        _kTableDailyReadHistory,
        obj.toJson(),
        where: '$_kColumnId = ?',
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

  AsyncResult<List<DailyReadHistory>> getDailyReadHistories({
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
    if (_database == null) {
      return Failure(Exception("Database is not open"));
    }
    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _kTableDailyReadHistory,
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

  /// 插入或更新书签文章缓存
  AsyncResult<int> insertOrUpdateBookmarkArticle(
      BookmarkArticle article) async {
    if (_database == null) {
      return Failure(Exception("Database is not open"));
    }

    try {
      final data = {
        _kColumnBookmarkId: article.bookmarkId,
        _kColumnArticle: article.article,
        _kColumnTranslate: article.translate,
        _kColumnCreatedDate: article.createdDate.toIso8601String(),
      };

      final id = await _database!.insert(
        _kTableBookmarkArticle,
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

  /// 根据书签ID获取文章缓存
  AsyncResult<BookmarkArticle> getBookmarkArticleByBookmarkId(
      String bookmarkId) async {
    if (_database == null) {
      return Failure(Exception("Database is not open"));
    }

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        _kTableBookmarkArticle,
        where: '$_kColumnBookmarkId = ?',
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
        id: map[_kColumnId] as int?,
        bookmarkId: map[_kColumnBookmarkId] as String,
        article: map[_kColumnArticle] as String,
        translate: map[_kColumnTranslate] as String?,
        createdDate: DateTime.parse(map[_kColumnCreatedDate] as String),
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

  /// 删除书签文章缓存
  AsyncResult<int> deleteBookmarkArticle(String bookmarkId) async {
    if (_database == null) {
      return Failure(Exception("Database is not open"));
    }

    try {
      final count = await _database!.delete(
        _kTableBookmarkArticle,
        where: '$_kColumnBookmarkId = ?',
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

  /// 清空所有数据库表的数据
  AsyncResult<void> clearAllData() async {
    if (_database == null) {
      return Failure(Exception("Database is not open"));
    }

    try {
      // 清空每日阅读历史表
      await _database!.delete(_kTableDailyReadHistory);
      // 清空书签文章缓存表
      await _database!.delete(_kTableBookmarkArticle);
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
