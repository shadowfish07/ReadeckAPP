import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:logging/logging.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/daily_read_history/daily_read_history_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/daily_read_history/daily_read_history.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';
import 'package:readeck_app/utils/option_data.dart';
import 'package:result_dart/result_dart.dart';

class DailyReadViewModel extends ChangeNotifier {
  DailyReadViewModel(this._bookmarkRepository, this._dailyReadHistoryRepository,
      this._bookmarkOperationUseCases) {
    load = Command.createAsync<bool, List<Bookmark>>(_load, initialValue: [])
      ..execute(false);
    openUrl = Command.createAsyncNoResult<String>(_openUrl);
  }

  final BookmarkRepository _bookmarkRepository;
  final DailyReadHistoryRepository _dailyReadHistoryRepository;
  final BookmarkOperationUseCases _bookmarkOperationUseCases;
  final _log = Logger("DailyReadViewModel");

  late Command load;
  late Command openUrl;
  final Command isApiConfigured =
      Command.createSync((value) => value, initialValue: false);

  final List<Bookmark> _bookmarks = [];
  List<Bookmark> get bookmarks => _bookmarks;
  List<Bookmark> get unArchivedBookmarks =>
      _bookmarks.where((bookmark) => !bookmark.isArchived).toList();

  Future<void> _openUrl(String url) async {
    final result = await _bookmarkOperationUseCases.openUrl(url);
    if (result.isError()) {
      throw result.exceptionOrNull()!;
    }
  }

  Future<List<Bookmark>> _load(bool refresh) async {
    if (!refresh) {
      final todayBookmarksHistory =
          await _dailyReadHistoryRepository.getTodayDailyReadHistory();

      if (todayBookmarksHistory.isError()) {
        _log.severe("Failed to get today bookmarks",
            todayBookmarksHistory.exceptionOrNull()!);
        throw todayBookmarksHistory.exceptionOrNull()!;
      }

      switch (todayBookmarksHistory.getOrNull()) {
        case Some<DailyReadHistory> some:
          {
            final todayBookmarks =
                some.value.bookmarkIds.map((item) => item).toList();
            // 今天已经访问过
            final result =
                await _bookmarkRepository.getBookmarksByIds(todayBookmarks);
            if (result.isSuccess()) {
              _bookmarks.clear();
              _bookmarks.addAll(result.getOrDefault([]));
              return unArchivedBookmarks;
            }
            break;
          }
        default:
      }
    }

    // 今天没有访问过 or 强制刷新
    final result = await _bookmarkRepository.getRandomUnreadBookmarks(5);
    if (result.isSuccess()) {
      _bookmarks.clear();
      _bookmarks.addAll(result.getOrDefault([]));
      //异步存到数据库
      _saveTodayBookmarks();
      return unArchivedBookmarks;
    }

    _log.severe("Failed to get random bookmarks", result.exceptionOrNull()!);
    throw result.exceptionOrNull()!;
  }

  Future<void> _saveTodayBookmarks() async {
    final id = await _dailyReadHistoryRepository.saveTodayBookmarks(bookmarks);

    if (id.isSuccess()) {
      _log.fine("Saved today bookmarks with id: ${id.getOrNull()}");
    } else {
      _log.severe("Failed to save today bookmarks", id.exceptionOrNull());
    }
  }

  AsyncResult<void> toggleBookmarkArchived(Bookmark bookmark) async {
    return _bookmarkOperationUseCases.toggleBookmarkArchived(bookmark);
  }

  AsyncResult<void> toggleBookmarkMarked(Bookmark bookmark) async {
    return _bookmarkOperationUseCases.toggleBookmarkMarked(bookmark);
  }
}
