import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/daily_read_history/daily_read_history_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/daily_read_history/daily_read_history.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';
import 'package:readeck_app/data/repository/label/label_repository.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/utils/option_data.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';

class DailyReadViewModel extends ChangeNotifier {
  DailyReadViewModel(
    this._bookmarkRepository,
    this._dailyReadHistoryRepository,
    this._bookmarkOperationUseCases,
    this._labelRepository,
  ) {
    load = Command.createAsync<bool, List<Bookmark>>(_load, initialValue: [])
      ..execute(false);
    openUrl = Command.createAsyncNoResult<String>(_openUrl);
    toggleBookmarkArchived =
        Command.createAsyncNoResult<Bookmark>(_toggleBookmarkArchived);
    toggleBookmarkMarked =
        Command.createAsyncNoResult<Bookmark>(_toggleBookmarkMarked);
    loadLabels = Command.createAsyncNoParam(_loadLabels, initialValue: []);

    // 注册书签数据变化监听器
    _bookmarkRepository.addListener(_onBookmarksChanged);
    // 注册标签数据变化监听器
    _labelRepository.addListener(_onLabelsChanged);
  }

  VoidCallback? _onBookmarkArchivedCallback;

  final BookmarkRepository _bookmarkRepository;
  final DailyReadHistoryRepository _dailyReadHistoryRepository;
  final BookmarkOperationUseCases _bookmarkOperationUseCases;
  final LabelRepository _labelRepository;

  late Command load;
  late Command openUrl;
  late Command toggleBookmarkArchived;
  late Command toggleBookmarkMarked;
  late Command<void, List<String>> loadLabels;

  // 移除本地缓存，改为通过Repository获取
  final List<String> _bookmarkIds = [];
  List<Bookmark> get _bookmarks => _bookmarkRepository
      .getCachedBookmarks(_bookmarkIds)
      .whereType<Bookmark>()
      .toList();
  bool _isNoMore = false;
  // 移除本地 _labels 变量，改用中心化存储
  bool get isNoMore => _isNoMore;
  List<Bookmark> get bookmarks => _bookmarks;

  List<Bookmark> get unArchivedBookmarks =>
      bookmarks.where((bookmark) => !bookmark.isArchived).toList();

  List<String> get availableLabels => _labelRepository.labelNames;

  /// 获取书签的阅读统计数据
  Future<ReadingStatsForView?> getReadingStats(String bookmarkId) async {
    final bookmark = _bookmarkRepository.getCachedBookmark(bookmarkId);
    if (bookmark == null) return null;
    final result =
        await _bookmarkOperationUseCases.loadReadingStatsForBookmark(bookmark);
    return result;
  }

  Future<void> _openUrl(String url) async {
    final result = await _bookmarkOperationUseCases.openUrl(url);
    if (result.isError()) {
      throw result.exceptionOrNull()!;
    }
  }

  void _resetBookmarkIds(List<Bookmark> bookmarks) {
    _bookmarkIds.clear();
    _bookmarkIds.addAll(bookmarks.map((e) => e.id));
  }

  Future<List<Bookmark>> _load(bool refresh) async {
    if (!refresh) {
      // 尝试读取今天已刷新过的记录
      final todayBookmarksHistory =
          await _dailyReadHistoryRepository.getTodayDailyReadHistory();

      if (todayBookmarksHistory.isError()) {
        appLogger.e("Failed to get today bookmarks",
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
                await _bookmarkRepository.loadBookmarksByIds(todayBookmarks);
            if (result.isSuccess()) {
              _resetBookmarkIds(result.getOrDefault([]));

              // 预加载阅读统计数据到Repository缓存
              await _bookmarkOperationUseCases
                  .loadReadingStatsForBookmarks(_bookmarks);
              return unArchivedBookmarks;
            }

            appLogger.e("Failed to get today bookmarks",
                error: result.exceptionOrNull()!);
            throw result.exceptionOrNull()!;
          }
        default:
      }
    }

    // 今天没有访问过 or 强制刷新
    final result = await _bookmarkRepository.loadRandomUnarchivedBookmarks(5);
    if (result.isSuccess()) {
      if (result.getOrDefault([]).isEmpty) {
        _isNoMore = true;
        return unArchivedBookmarks;
      }
      final newBookmarks = result.getOrDefault([]);
      _resetBookmarkIds(newBookmarks);

      // 预加载阅读统计数据到Repository缓存
      await _bookmarkOperationUseCases
          .loadReadingStatsForBookmarks(newBookmarks);
      //异步存到数据库
      _saveTodayBookmarks();
      return unArchivedBookmarks;
    }

    appLogger.e("Failed to get random bookmarks",
        error: result.exceptionOrNull()!);
    throw result.exceptionOrNull()!;
  }

  Future<void> _saveTodayBookmarks() async {
    final id = await _dailyReadHistoryRepository.saveTodayBookmarks(bookmarks);

    if (id.isSuccess()) {
      appLogger.i("Saved today bookmarks with id: ${id.getOrNull()}");
    } else {
      appLogger.e("Failed to save today bookmarks",
          error: id.exceptionOrNull());
    }
  }

  void setOnBookmarkArchivedCallback(VoidCallback? callback) {
    _onBookmarkArchivedCallback = callback;
  }

  Future<void> _toggleBookmarkArchived(Bookmark bookmark) async {
    final result = await _bookmarkRepository.toggleArchived(bookmark);

    if (result.isError()) {
      appLogger.e("Failed to toggle bookmark archived",
          error: result.exceptionOrNull()!);
      throw result.exceptionOrNull()!;
    }

    _onBookmarkArchivedCallback?.call();
  }

  Future<void> _toggleBookmarkMarked(Bookmark bookmark) async {
    final result = await _bookmarkRepository.toggleMarked(bookmark);

    if (result.isError()) {
      appLogger.e("Failed to toggle bookmark marked",
          error: result.exceptionOrNull()!);
      throw result.exceptionOrNull()!;
    }
  }

  Future<List<String>> _loadLabels() async {
    final result = await _labelRepository.loadLabels();
    if (result.isSuccess()) {
      return _labelRepository.labelNames;
    }

    appLogger.e("Failed to load labels", error: result.exceptionOrNull()!);
    throw result.exceptionOrNull()!;
  }

  Future<void> updateBookmarkLabels(
      Bookmark bookmark, List<String> labels) async {
    final result = await _bookmarkRepository.updateLabels(bookmark, labels);

    if (result.isError()) {
      appLogger.e("Failed to update bookmark labels",
          error: result.exceptionOrNull()!);
      throw result.exceptionOrNull()!;
    }
  }

  /// 书签数据变化回调
  void _onBookmarksChanged() {
    notifyListeners();
  }

  /// 标签数据变化回调
  void _onLabelsChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    // 移除书签数据变化监听器
    _bookmarkRepository.removeListener(_onBookmarksChanged);
    // 移除标签数据变化监听器
    _labelRepository.removeListener(_onLabelsChanged);
    super.dispose();
  }
}
