import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:readeck_app/domain/models/daily_read_history/daily_read_history.dart';
import 'package:result_dart/result_dart.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService() {
    open();
  }

  static const _kTableDailyReadHistory = 'daily_read_history';
  static const _kColumnId = 'id';
  static const _kColumnCreatedDate = 'created_date';
  static const _kColumnBookmarkIds = 'bookmark_ids';

  Database? _database;
  final _log = Logger("DatabaseService");

  bool isOpen() {
    return _database?.isOpen ?? false;
  }

  Future<void> open() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'app_database.db'),
      onCreate: (db, version) {
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
    );
  }

  AsyncResult<int> insertDailyReadHistory(List<String> bookmarkIds) async {
    if (_database == null) {
      return Failure(Exception("Database is not open"));
    }

    try {
      final id = await _database!.insert(_kTableDailyReadHistory,
          {_kColumnBookmarkIds: jsonEncode(bookmarkIds)});
      _log.fine(
          "Inserted daily read history with id: $id. bookmarkIds: $bookmarkIds");
      return Success(id);
    } on Exception catch (e) {
      _log.severe(
          "Failed to insert daily read history. bookmarkIds: $bookmarkIds", e);
      return Failure(e);
    } catch (e) {
      _log.severe(
          "Failed to insert daily read history. bookmarkIds: $bookmarkIds", e);
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
      _log.fine("Retrieved ${maps.length} daily read histories. data: $maps");
      final List<DailyReadHistory> histories = [];
      for (final map in maps) {
        histories.add(DailyReadHistory.fromJson(map));
      }
      return Success(histories);
    } on Exception catch (e) {
      _log.severe("Failed to get daily read histories", e);
      return Failure(e);
    } catch (e) {
      _log.severe("Failed to get daily read histories", e);
      return Failure(Exception(e));
    }
  }
}
