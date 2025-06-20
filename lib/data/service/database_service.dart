import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:readeck_app/domain/models/daily_read_history/daily_read_history.dart';
import 'package:result_dart/result_dart.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqflite_logger.dart';

class DatabaseService {
  DatabaseService() {
    open();
  }

  static const _kTableDailyReadHistory = 'daily_read_history';
  static const _kColumnId = 'id';
  static const _kColumnCreatedDate = 'created_date';
  static const _kColumnBookmarkIds = 'bookmark_ids';

  Database? _database;
  final _log = Logger();

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
              _log.i('Current SQLite version: $version');
            } catch (e) {
              _log.e('Failed to get SQLite version', error: e);
            }
            return db.execute(
              '''CREATE TABLE $_kTableDailyReadHistory (
    $_kColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
    $_kColumnCreatedDate TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
    $_kColumnBookmarkIds TEXT NOT NULL CHECK (json_valid($_kColumnBookmarkIds))
);
''',
            );
          },
          version: 1,
        ));
  }

  AsyncResult<int> insertDailyReadHistory(List<String> bookmarkIds) async {
    if (_database == null) {
      return Failure(Exception("Database is not open"));
    }

    try {
      final id = await _database!.insert(_kTableDailyReadHistory,
          {_kColumnBookmarkIds: jsonEncode(bookmarkIds)});
      _log.d(
          "Inserted daily read history with id: $id. bookmarkIds: $bookmarkIds");
      return Success(id);
    } on Exception catch (e) {
      _log.e("Failed to insert daily read history. bookmarkIds: $bookmarkIds",
          error: e);
      return Failure(e);
    } catch (e) {
      _log.e("Failed to insert daily read history. bookmarkIds: $bookmarkIds",
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
      _log.d("Updated daily read history with id: ${obj.id}. data: $obj");
      return Success(count);
    } on Exception catch (e) {
      _log.e("Failed to update daily read history. data: $obj", error: e);
      return Failure(e);
    } catch (e) {
      _log.e("Failed to update daily read history. data: $obj", error: e);
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
      _log.d("Retrieved ${maps.length} daily read histories. data: $maps");
      final List<DailyReadHistory> histories = [];
      for (final map in maps) {
        histories.add(DailyReadHistory.fromJson(map));
      }
      return Success(histories);
    } on Exception catch (e) {
      _log.e("Failed to get daily read histories", error: e);
      return Failure(e);
    } catch (e) {
      _log.e("Failed to get daily read histories", error: e);
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
      _log.i("Cleared all data from database");
      return const Success(unit);
    } on Exception catch (e) {
      _log.e("Failed to clear all data from database", error: e);
      return Failure(e);
    } catch (e) {
      _log.e("Failed to clear all data from database", error: e);
      return Failure(Exception(e));
    }
  }
}
