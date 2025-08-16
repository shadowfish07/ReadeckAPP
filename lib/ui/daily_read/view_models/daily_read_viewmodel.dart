import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/daily_read_history/daily_read_history_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/bookmark_display_model/bookmark_display_model.dart';
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
    load = Command.createAsync<bool, List<BookmarkDisplayModel>>(_load,
        includeLastResultInCommandResults: true, initialValue: [])
      ..execute(false);
    openUrl = Command.createAsyncNoResult<String>(_openUrl);
    toggleBookmarkArchived = Command.createAsyncNoResult<BookmarkDisplayModel>(
        _toggleBookmarkArchived);
    toggleBookmarkMarked = Command.createAsyncNoResult<BookmarkDisplayModel>(
        _toggleBookmarkMarked);
    loadLabels = Command.createAsyncNoParam(_loadLabels, initialValue: []);

    // 注册书签数据变化监听器
    _bookmarkRepository.addListener(_onBookmarksChanged);
    // 注册标签数据变化监听器
    _labelRepository.addListener(_onLabelsChanged);
  }

  VoidCallback? _onBookmarkArchivedCallback;
  void Function(Bookmark)? _onNavigateToDetail;

  final BookmarkRepository _bookmarkRepository;
  final DailyReadHistoryRepository _dailyReadHistoryRepository;
  final BookmarkOperationUseCases _bookmarkOperationUseCases;
  final LabelRepository _labelRepository;

  late Command<bool, List<BookmarkDisplayModel>> load;
  late Command<String, void> openUrl;
  late Command<BookmarkDisplayModel, void> toggleBookmarkArchived;
  late Command<BookmarkDisplayModel, void> toggleBookmarkMarked;
  late Command<void, List<String>> loadLabels;

  final List<BookmarkDisplayModel> _todayBookmarks = [];
  bool _isNoMore = false;
  bool get isNoMore => _isNoMore;
  List<BookmarkDisplayModel> get bookmarks => _bookmarkRepository.bookmarks
      .where((x) =>
          _todayBookmarks
              .indexWhere((today) => today.bookmark.id == x.bookmark.id) !=
          -1)
      .toList();

  List<BookmarkDisplayModel> get unArchivedBookmarks =>
      bookmarks.where((element) => !element.bookmark.isArchived).toList();

  List<String> get availableLabels => _labelRepository.labelNames;

  ReadingStatsForView? getReadingStats(String bookmarkId) {
    final idx =
        bookmarks.indexWhere((element) => element.bookmark.id == bookmarkId);
    return idx == -1 ? null : bookmarks[idx].stats;
  }

  Future<void> _openUrl(String url) async {
    final result = await _bookmarkOperationUseCases.openUrl(url);
    if (result.isError()) {
      throw result.exceptionOrNull()!;
    }
  }

  Future<List<BookmarkDisplayModel>> _load(bool refresh) async {
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
            final todayBookmarkIds =
                some.value.bookmarkIds.map((item) => item).toList();
            // 今天已经访问过
            final result =
                await _bookmarkRepository.loadBookmarksByIds(todayBookmarkIds);
            if (result.isSuccess()) {
              _todayBookmarks.clear();
              _todayBookmarks.addAll(result.getOrDefault([]));
              return unArchivedBookmarks;
            }

            appLogger.e("Failed to get today bookmarks",
                error: result.exceptionOrNull()!);
            throw result.exceptionOrNull()!;
          }
        default:
      }
    }

    // 今天没有访问过 or 刷新新的一组
    final result = await _bookmarkRepository.loadRandomUnarchivedBookmarks(5);
    if (result.isSuccess()) {
      final newBookmarks = result.getOrDefault([]);
      if (newBookmarks.isEmpty) {
        _isNoMore = true;
        return unArchivedBookmarks;
      }
      _todayBookmarks.addAll(result.getOrDefault([]));
      _isNoMore = false;
      //异步存到数据库
      _saveTodayBookmarks(newBookmarks);
      return unArchivedBookmarks;
    }

    appLogger.e("Failed to get random bookmarks",
        error: result.exceptionOrNull()!);
    throw result.exceptionOrNull()!;
  }

  Future<void> _saveTodayBookmarks(
      List<BookmarkDisplayModel> bookmarksToSave) async {
    final bookmarkList = bookmarksToSave.map((e) => e.bookmark).toList();
    final id =
        await _dailyReadHistoryRepository.saveTodayBookmarks(bookmarkList);

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

  void setNavigateToDetailCallback(void Function(Bookmark) callback) {
    _onNavigateToDetail = callback;
  }

  void _navigateToDetail(Bookmark bookmark) {
    _onNavigateToDetail?.call(bookmark);
  }

  void handleBookmarkTap(BookmarkDisplayModel bookmark) {
    appLogger.i('处理书签点击: ${bookmark.bookmark.title}');

    final bookmarkModel = bookmarks.firstWhere(
      (model) => model.bookmark.id == bookmark.bookmark.id,
      orElse: () =>
          BookmarkDisplayModel(bookmark: bookmark.bookmark, stats: null),
    );

    if (bookmarkModel.stats == null) {
      appLogger.i('书签没有阅读统计数据，可能文章内容为空，使用浏览器打开: ${bookmark.bookmark.url}');
      openUrl.execute(bookmark.bookmark.url);
    } else {
      appLogger.i('书签有阅读统计数据，触发详情页导航');
      _navigateToDetail(bookmark.bookmark);
    }
  }

  Future<void> _toggleBookmarkArchived(BookmarkDisplayModel bookmark) async {
    final result = await _bookmarkRepository.toggleArchived(bookmark.bookmark);

    if (result.isError()) {
      appLogger.e("Failed to toggle bookmark archived",
          error: result.exceptionOrNull()!);
      throw result.exceptionOrNull()!;
    }

    _onBookmarkArchivedCallback?.call();
  }

  Future<void> _toggleBookmarkMarked(BookmarkDisplayModel bookmark) async {
    final result = await _bookmarkRepository.toggleMarked(bookmark.bookmark);

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
      BookmarkDisplayModel bookmark, List<String> labels) async {
    final result =
        await _bookmarkRepository.updateLabels(bookmark.bookmark, labels);

    if (result.isError()) {
      appLogger.e("Failed to update bookmark labels",
          error: result.exceptionOrNull()!);
      throw result.exceptionOrNull()!;
    }
  }

  /// 书签数据变化回调
  void _onBookmarksChanged() {
    load.execute(false);
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
