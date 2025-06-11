import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:logger/logger.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/daily_read_history/daily_read_history_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/daily_read_history/daily_read_history.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';
import 'package:readeck_app/utils/option_data.dart';

class DailyReadViewModel extends ChangeNotifier {
  DailyReadViewModel(this._bookmarkRepository, this._dailyReadHistoryRepository,
      this._bookmarkOperationUseCases) {
    load = Command.createAsync<bool, List<Bookmark>>(_load, initialValue: [])
      ..execute(false);
    openUrl = Command.createAsyncNoResult<String>(_openUrl);
    toggleBookmarkArchived =
        Command.createAsyncNoResult<Bookmark>(_toggleBookmarkArchived);
    toggleBookmarkMarked =
        Command.createAsyncNoResult<Bookmark>(_toggleBookmarkMarked);
  }

  VoidCallback? _onBookmarkArchivedCallback;

  final BookmarkRepository _bookmarkRepository;
  final DailyReadHistoryRepository _dailyReadHistoryRepository;
  final BookmarkOperationUseCases _bookmarkOperationUseCases;
  final _log = Logger();

  late Command load;
  late Command openUrl;
  late Command toggleBookmarkArchived;
  late Command toggleBookmarkMarked;

  List<Bookmark> _bookmarks = [];
  final Map<String, bool> _optimisticArchived = {};
  final Map<String, bool> _optimisticMarked = {};
  bool _isNoMore = false;
  bool get isNoMore => _isNoMore;
  List<Bookmark> get bookmarks {
    return _bookmarks
        .map((item) => item.copyWith(
            isArchived: _optimisticArchived[item.id] ?? item.isArchived,
            isMarked: _optimisticMarked[item.id] ?? item.isMarked))
        .toList();
  }

  List<Bookmark> get unArchivedBookmarks =>
      bookmarks.where((bookmark) => !bookmark.isArchived).toList();

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
        _log.e("Failed to get today bookmarks",
            error: todayBookmarksHistory.exceptionOrNull()!);
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

            _log.e("Failed to get today bookmarks",
                error: result.exceptionOrNull()!);
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

    _log.e("Failed to get random bookmarks", error: result.exceptionOrNull()!);
    throw result.exceptionOrNull()!;
  }

  Future<void> _saveTodayBookmarks() async {
    final id = await _dailyReadHistoryRepository.saveTodayBookmarks(bookmarks);

    if (id.isSuccess()) {
      _log.d("Saved today bookmarks with id: ${id.getOrNull()}");
    } else {
      _log.e("Failed to save today bookmarks", error: id.exceptionOrNull());
    }
  }

  void setOnBookmarkArchivedCallback(VoidCallback? callback) {
    _onBookmarkArchivedCallback = callback;
  }

  Future<void> _toggleBookmarkArchived(Bookmark bookmark) async {
    // 乐观更新
    _optimisticArchived[bookmark.id] = !bookmark.isArchived;
    notifyListeners();
    _onBookmarkArchivedCallback?.call();

    final result =
        await _bookmarkOperationUseCases.toggleBookmarkArchived(bookmark);

    if (result.isError()) {
      _log.e("Failed to toggle bookmark archived",
          error: result.exceptionOrNull()!);
      _optimisticArchived.remove(bookmark.id);
      notifyListeners();
      throw result.exceptionOrNull()!;
    }

    _bookmarks = bookmarks;
  }

  Future<void> _toggleBookmarkMarked(Bookmark bookmark) async {
    // 乐观更新
    _optimisticMarked[bookmark.id] = !bookmark.isMarked;
    notifyListeners();

    final result =
        await _bookmarkOperationUseCases.toggleBookmarkMarked(bookmark);

    if (result.isError()) {
      _log.e("Failed to toggle bookmark marked",
          error: result.exceptionOrNull()!);
      _optimisticMarked.remove(bookmark.id);
      notifyListeners();
      throw result.exceptionOrNull()!;
    }

    _bookmarks = bookmarks;
  }
}
