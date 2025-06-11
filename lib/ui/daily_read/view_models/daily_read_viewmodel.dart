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

  VoidCallback? _onBookmarkArchivedCallback;

  final BookmarkRepository _bookmarkRepository;
  final DailyReadHistoryRepository _dailyReadHistoryRepository;
  final BookmarkOperationUseCases _bookmarkOperationUseCases;
  final _log = Logger("DailyReadViewModel");

  late Command load;
  late Command openUrl;

  final List<Bookmark> _bookmarks = [];
  bool _isNoMore = false;
  bool get isNoMore => _isNoMore;
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
      // 尝试读取今天已刷新过的记录
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

            _log.severe(
                "Failed to get today bookmarks", result.exceptionOrNull()!);
            throw result.exceptionOrNull()!;
          }
        default:
      }
    }

    // 今天没有访问过 or 强制刷新
    final result = await _bookmarkRepository.getRandomUnarchivedBookmarks(5);
    if (result.isSuccess()) {
      if (result.getOrDefault([]).isEmpty) {
        _isNoMore = true;
        return unArchivedBookmarks;
      }
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

  void setOnBookmarkArchivedCallback(VoidCallback? callback) {
    _onBookmarkArchivedCallback = callback;
  }

  AsyncResult<void> toggleBookmarkArchived(Bookmark bookmark) async {
    final result =
        await _bookmarkOperationUseCases.toggleBookmarkArchived(bookmark);

    if (result.isError()) {
      _log.severe(
          "Failed to toggle bookmark archived", result.exceptionOrNull()!);
      return result;
    }

    // 乐观更新
    final index = _bookmarks.indexWhere((item) => item.id == bookmark.id);
    if (index != -1) {
      _bookmarks[index] = bookmark.copyWith(isArchived: !bookmark.isArchived);
    }
    notifyListeners();
    _onBookmarkArchivedCallback?.call();

    // 异步刷新
    await _load(false);
    notifyListeners();

    return result;
  }

  AsyncResult<void> toggleBookmarkMarked(Bookmark bookmark) async {
    final result =
        await _bookmarkOperationUseCases.toggleBookmarkMarked(bookmark);

    if (result.isError()) {
      _log.severe(
          "Failed to toggle bookmark marked", result.exceptionOrNull()!);
      return result;
    }

    // 乐观更新
    final index = _bookmarks.indexWhere((item) => item.id == bookmark.id);
    if (index != -1) {
      _bookmarks[index] = bookmark.copyWith(isMarked: !bookmark.isMarked);
    }
    notifyListeners();

    // 异步刷新
    await _load(false);
    notifyListeners();

    return result;
  }
}
