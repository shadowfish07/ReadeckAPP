import 'package:logging/logging.dart';
import 'package:readeck_app/data/service/database_service.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/daily_read_history/daily_read_history.dart';
import 'package:readeck_app/utils/option_data.dart';
import 'package:result_dart/result_dart.dart';

class DailyReadHistoryRepository {
  DailyReadHistoryRepository(this._database);

  final DatabaseService _database;

  final _log = Logger("DailyReadHistoryRepository");

  AsyncResult<OptionData<DailyReadHistory>> getTodayDailyReadHistory() async {
    if (!_database.isOpen()) {
      await _database.open();
    }

    final result = await _database.getDailyReadHistories(
        where: "DATE(created_date) = DATE('now', 'localtime')");

    if (result.isError()) {
      _log.severe("获取今日阅读历史失败: ${result.exceptionOrNull()?.toString()}");
      return Failure(Exception(result.exceptionOrNull()));
    }

    if (result.getOrDefault([]).isEmpty) {
      return const Success(None());
    }
    return Success(Some(result.getOrDefault([])[0]));
  }

  AsyncResult<int> saveTodayBookmarks(List<Bookmark> bookmarks) async {
    if (!_database.isOpen()) {
      await _database.open();
    }

    final today = await getTodayDailyReadHistory();
    if (today.isError()) {
      _log.severe("获取今日阅读历史失败: ${today.exceptionOrNull()?.toString()}");
      return Failure(Exception(today.exceptionOrNull()));
    }

    switch (today.getOrNull()!) {
      case Some some:
        return _database.updateDailyReadHistory(some.value.copyWith(
            bookmarkIds: some.value.bookmarkIds +
                bookmarks.map((bookmark) => bookmark.id).toList()));
      case None():
        return _database.insertDailyReadHistory(
            bookmarks.map((bookmark) => bookmark.id).toList());
    }
  }

  AsyncResult<void> clearAllDataForDebug() {
    return _database.clearAllData();
  }
}
