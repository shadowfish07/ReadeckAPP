import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/daily_read_history/daily_read_history_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/daily_read_history/daily_read_history.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';
import 'package:readeck_app/utils/command.dart';
import 'package:readeck_app/utils/result.dart';

class DailyReadViewModel extends ChangeNotifier {
  DailyReadViewModel(this._bookmarkRepository, this._dailyReadHistoryRepository,
      this._bookmarkOperationUseCases) {
    load = Command1<void, bool>(_load)..execute(false);
    openUrl = Command1<void, String>(_openUrl);
  }

  final BookmarkRepository _bookmarkRepository;
  final DailyReadHistoryRepository _dailyReadHistoryRepository;
  final BookmarkOperationUseCases _bookmarkOperationUseCases;
  final _log = Logger("DailyReadViewModel");

  late Command1<void, bool> load;
  late Command1<void, String> openUrl;

  final List<Bookmark> _bookmarks = [];
  List<Bookmark> get bookmarks => _bookmarks;
  List<Bookmark> get unArchivedBookmarks =>
      _bookmarks.where((bookmark) => !bookmark.isArchived).toList();

  Future<Result<void>> _openUrl(String url) async {
    return _bookmarkOperationUseCases.openUrl(url);
  }

  Future<Result<void>> _load(bool refresh) async {
    if (!refresh) {
      final todayBookmarks =
          await _dailyReadHistoryRepository.getTodayDailyReadHistory();

      if (todayBookmarks is Error) {
        notifyListeners();
        return todayBookmarks;
      }

      if (todayBookmarks is Ok<List<DailyReadHistory>>) {
        // 今天已经访问过
        final result = await _bookmarkRepository.getBookmarksByIds(
            todayBookmarks.value.map((item) => item.id).toList());
        if (result is Ok<List<Bookmark>>) {
          _bookmarks.clear();
          _bookmarks.addAll(result.value);
          notifyListeners();
          return const Result.ok(null);
        }

        notifyListeners();
        return result;
      }
    }

    // 今天没有访问过 or 强制刷新
    final result = await _bookmarkRepository.getRandomUnreadBookmarks(5);
    if (result is Ok<List<Bookmark>>) {
      _bookmarks.clear();
      _bookmarks.addAll(result.value);
      notifyListeners();
      //异步存到数据库
      _saveTodayBookmarks();
      return const Result.ok(null);
    }

    return result;
  }

  Future<void> _saveTodayBookmarks() async {
    final id = await _dailyReadHistoryRepository.saveTodayBookmarks(bookmarks);

    switch (id) {
      case Ok<int>():
        _log.fine("Saved today bookmarks with id: ${id.value}");
        break;
      case Error<int>():
        _log.severe("Failed to save today bookmarks", id.error);
        break;
    }
  }

  Future<Result<void>> toggleBookmarkArchived(Bookmark bookmark) async {
    return _bookmarkOperationUseCases.toggleBookmarkArchived(bookmark);
  }

  Future<Result<void>> toggleBookmarkMarked(Bookmark bookmark) async {
    return _bookmarkOperationUseCases.toggleBookmarkMarked(bookmark);
  }
}
