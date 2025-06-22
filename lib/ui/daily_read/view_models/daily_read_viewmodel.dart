import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/daily_read_history/daily_read_history_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/daily_read_history/daily_read_history.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';
import 'package:readeck_app/domain/use_cases/bookmark_use_cases.dart';
import 'package:readeck_app/domain/use_cases/label_use_cases.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/utils/option_data.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';

class DailyReadViewModel extends ChangeNotifier {
  DailyReadViewModel(
    this._bookmarkRepository,
    this._dailyReadHistoryRepository,
    this._bookmarkOperationUseCases,
    this._bookmarkUseCases,
    this._labelUseCases,
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
    _bookmarkUseCases.addListener(_onBookmarksChanged);
    // 注册标签数据变化监听器
    _labelUseCases.addListener(_onLabelsChanged);
  }

  VoidCallback? _onBookmarkArchivedCallback;

  final BookmarkRepository _bookmarkRepository;
  final DailyReadHistoryRepository _dailyReadHistoryRepository;
  final BookmarkOperationUseCases _bookmarkOperationUseCases;
  final BookmarkUseCases _bookmarkUseCases;
  final LabelUseCases _labelUseCases;

  late Command load;
  late Command openUrl;
  late Command toggleBookmarkArchived;
  late Command toggleBookmarkMarked;
  late Command<void, List<String>> loadLabels;

  final Map<String, bool> _optimisticArchived = {};
  final Map<String, bool> _optimisticMarked = {};
  final Map<String, ReadingStats> _readingStats = {};
  final List<String> _bookmarkIds = [];
  List<Bookmark> get _bookmarks => _bookmarkUseCases
      .getBookmarks(_bookmarkIds)
      .whereType<Bookmark>()
      .toList();
  bool _isNoMore = false;
  // 移除本地 _labels 变量，改用中心化存储
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

  List<String> get availableLabels => _labelUseCases.labelNames;

  /// 获取书签的阅读统计数据
  ReadingStats? getReadingStats(String bookmarkId) {
    return _readingStats[bookmarkId];
  }

  Future<void> _openUrl(String url) async {
    final result = await _bookmarkOperationUseCases.openUrl(url);
    if (result.isError()) {
      throw result.exceptionOrNull()!;
    }
  }

  void _clearAndSetBookmarks(List<Bookmark> bookmarks) {
    _bookmarkIds.clear();
    _bookmarkIds.addAll(bookmarks.map((e) => e.id));
    _bookmarkUseCases.insertOrUpdateBookmarks(bookmarks);
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
                await _bookmarkRepository.getBookmarksByIds(todayBookmarks);
            if (result.isSuccess()) {
              _clearAndSetBookmarks(result.getOrDefault([]));

              // 加载阅读统计数据
              final stats = await _bookmarkOperationUseCases
                  .loadReadingStatsForBookmarks(_bookmarks);
              _readingStats.addAll(stats);
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
    final result = await _bookmarkRepository.getRandomUnarchivedBookmarks(5);
    if (result.isSuccess()) {
      if (result.getOrDefault([]).isEmpty) {
        _isNoMore = true;
        return unArchivedBookmarks;
      }
      final newBookmarks = result.getOrDefault([]);
      _clearAndSetBookmarks(newBookmarks);

      // 加载阅读统计数据
      final stats = await _bookmarkOperationUseCases
          .loadReadingStatsForBookmarks(newBookmarks);
      _readingStats.addAll(stats);
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
    // 乐观更新
    _optimisticArchived[bookmark.id] = !bookmark.isArchived;
    notifyListeners();
    _onBookmarkArchivedCallback?.call();

    final result =
        await _bookmarkOperationUseCases.toggleBookmarkArchived(bookmark);

    if (result.isError()) {
      appLogger.e("Failed to toggle bookmark archived",
          error: result.exceptionOrNull()!);
      _optimisticArchived.remove(bookmark.id);
      notifyListeners();
      throw result.exceptionOrNull()!;
    }
  }

  Future<void> _toggleBookmarkMarked(Bookmark bookmark) async {
    // 乐观更新
    _optimisticMarked[bookmark.id] = !bookmark.isMarked;
    notifyListeners();

    final result =
        await _bookmarkOperationUseCases.toggleBookmarkMarked(bookmark);

    if (result.isError()) {
      appLogger.e("Failed to toggle bookmark marked",
          error: result.exceptionOrNull()!);
      _optimisticMarked.remove(bookmark.id);
      notifyListeners();
      throw result.exceptionOrNull()!;
    }
  }

  Future<List<String>> _loadLabels() async {
    final result = await _bookmarkRepository.getLabels();
    if (result.isSuccess()) {
      _labelUseCases.insertOrUpdateLabels(result.getOrDefault([]));
      return _labelUseCases.labelNames;
    }

    appLogger.e("Failed to load labels", error: result.exceptionOrNull()!);
    throw result.exceptionOrNull()!;
  }

  Future<void> updateBookmarkLabels(
      Bookmark bookmark, List<String> labels) async {
    final result =
        await _bookmarkOperationUseCases.updateBookmarkLabels(bookmark, labels);

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
    _bookmarkUseCases.removeListener(_onBookmarksChanged);
    // 移除标签数据变化监听器
    _labelUseCases.removeListener(_onLabelsChanged);
    super.dispose();
  }
}
