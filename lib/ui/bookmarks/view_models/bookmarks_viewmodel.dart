import 'package:flutter/foundation.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:logger/logger.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/bookmark/label_info.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';
import 'package:result_dart/result_dart.dart';

class UnarchivedViewmodel extends BaseBookmarksViewmodel {
  UnarchivedViewmodel(
      super._bookmarkRepository, super._bookmarkOperationUseCases);

  @override
  Future<ResultDart<List<Bookmark>, Exception>> Function({int limit, int page})
      get _loadBookmarks => _bookmarkRepository.getUnarchivedBookmarks;
}

abstract class BaseBookmarksViewmodel extends ChangeNotifier {
  BaseBookmarksViewmodel(
      this._bookmarkRepository, this._bookmarkOperationUseCases) {
    load = Command.createAsync<int, List<Bookmark>>(_load,
        initialValue: [], includeLastResultInCommandResults: true)
      ..execute(1);
    loadMore = Command.createAsync<int, List<Bookmark>>(_loadMore,
        initialValue: [], includeLastResultInCommandResults: true);
    openUrl = Command.createAsyncNoResult(_openUrl);
    toggleBookmarkMarked =
        Command.createAsyncNoResult<Bookmark>(_toggleBookmarkMarked);
    toggleBookmarkArchived =
        Command.createAsyncNoResult<Bookmark>(_toggleBookmarkArchived);
    loadLabels = Command.createAsyncNoParam(_loadLabels, initialValue: []);
  }

  final _log = Logger();
  final BookmarkRepository _bookmarkRepository;
  final BookmarkOperationUseCases _bookmarkOperationUseCases;
  List<Bookmark> _bookmarks = [];
  final Map<String, bool> _optimisticArchived = {};
  final Map<String, bool> _optimisticMarked = {};
  final Map<String, ReadingStats> _readingStats = {};
  List<LabelInfo> _labels = [];
  int _currentPage = 1;
  bool _hasMoreData = true;
  late Command<int, List<Bookmark>> load;
  late Command<int, List<Bookmark>> loadMore;
  late Command<String, void> openUrl;
  late Command<Bookmark, void> toggleBookmarkMarked;
  late Command<Bookmark, void> toggleBookmarkArchived;
  late Command<void, List<String>> loadLabels;

  List<Bookmark> get bookmarks {
    return _bookmarks
        .map((item) => item.copyWith(
            isArchived: _optimisticArchived[item.id] ?? item.isArchived,
            isMarked: _optimisticMarked[item.id] ?? item.isMarked))
        .toList();
  }

  bool get hasMoreData => _hasMoreData;
  bool get isLoadingMore => loadMore.isExecuting.value;

  List<String> get availableLabels =>
      _labels.map((label) => label.name).toList();

  /// 获取书签的阅读统计数据
  ReadingStats? getReadingStats(String bookmarkId) {
    return _readingStats[bookmarkId];
  }

  Future<ResultDart<List<Bookmark>, Exception>> Function({int limit, int page})
      get _loadBookmarks;

  Future<List<Bookmark>> _load(int page) async {
    var limit = 5;
    _currentPage = page;
    final result = await _loadBookmarks(limit: limit, page: page);
    final bookmarks = result.getOrThrow();
    _bookmarks = bookmarks;
    _hasMoreData = bookmarks.length == limit;

    // 加载阅读统计数据
    final stats = await _bookmarkOperationUseCases
        .loadReadingStatsForBookmarks(bookmarks);
    _readingStats.addAll(stats);

    notifyListeners();
    return bookmarks;
  }

  Future<List<Bookmark>> _loadMore(int page) async {
    if (!_hasMoreData) return _bookmarks;

    var limit = 5;
    _currentPage = page;
    final result = await _loadBookmarks(limit: limit, page: page);
    final newBookmarks = result.getOrThrow();

    if (newBookmarks.isNotEmpty) {
      _bookmarks.addAll(newBookmarks);
      _hasMoreData = newBookmarks.length == limit;

      // 加载新书签的阅读统计数据
      final stats = await _bookmarkOperationUseCases
          .loadReadingStatsForBookmarks(newBookmarks);
      _readingStats.addAll(stats);
    } else {
      _hasMoreData = false;
    }

    notifyListeners();
    return _bookmarks;
  }

  void loadNextPage() {
    if (_hasMoreData && !loadMore.isExecuting.value) {
      loadMore.execute(_currentPage + 1);
    }
  }

  Future<void> _openUrl(String url) async {
    final result = await _bookmarkOperationUseCases.openUrl(url);
    if (result.isError()) {
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
      _log.e("Failed to toggle bookmark marked",
          error: result.exceptionOrNull()!);
      _optimisticMarked.remove(bookmark.id);
      notifyListeners();
      throw result.exceptionOrNull()!;
    }

    _bookmarks = bookmarks;
  }

  Future<void> _toggleBookmarkArchived(Bookmark bookmark) async {
    // 乐观更新
    _optimisticArchived[bookmark.id] = !bookmark.isArchived;
    notifyListeners();

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

  Future<List<String>> _loadLabels() async {
    final result = await _bookmarkRepository.getLabels();
    if (result.isSuccess()) {
      _labels = result.getOrDefault([]);
      notifyListeners();
      return _labels.map((e) => e.name).toList();
    }

    _log.e("Failed to load labels", error: result.exceptionOrNull()!);
    throw result.exceptionOrNull()!;
  }

  Future<void> updateBookmarkLabels(
      Bookmark bookmark, List<String> labels) async {
    final result =
        await _bookmarkOperationUseCases.updateBookmarkLabels(bookmark, labels);

    if (result.isError()) {
      _log.e("Failed to update bookmark labels",
          error: result.exceptionOrNull()!);
      throw result.exceptionOrNull()!;
    }

    // 更新本地书签数据
    final index = _bookmarks.indexWhere((b) => b.id == bookmark.id);
    if (index != -1) {
      _bookmarks[index] = _bookmarks[index].copyWith(labels: labels);
      notifyListeners();
    }
  }
}
