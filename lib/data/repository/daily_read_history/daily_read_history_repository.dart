import 'package:logging/logging.dart';
import 'package:readeck_app/data/service/database_service.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/daily_read_history/daily_read_history.dart';
import 'package:readeck_app/utils/result.dart';

class DailyReadHistoryRepository {
  DailyReadHistoryRepository(this._database);

  final DatabaseService _database;

  final _log = Logger("DailyReadHistoryRepository");

  Future<Result<List<DailyReadHistory>>> getTodayDailyReadHistory() async {
    if (!_database.isOpen()) {
      await _database.open();
    }

    return _database.getDailyReadHistories(
        where: "DATE(created_date) = DATE('now', 'localtime')");
  }

  Future<Result<int>> saveTodayBookmarks(List<Bookmark> bookmarks) async {
    if (!_database.isOpen()) {
      await _database.open();
    }

    return _database.insertDailyReadHistory(
        bookmarks.map((bookmark) => bookmark.id).toList());
  }
}
