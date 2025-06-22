import 'package:flutter/foundation.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';
import 'package:readeck_app/domain/use_cases/bookmark_use_cases.dart';
import 'package:readeck_app/domain/use_cases/label_use_cases.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';
import 'package:result_dart/result_dart.dart';

class MarkedViewmodel extends BaseBookmarksViewmodel {
  MarkedViewmodel(super._bookmarkRepository, super._bookmarkOperationUseCases,
      super._bookmarkUseCases, super._labelUseCases);

  @override
  Future<ResultDart<List<Bookmark>, Exception>> Function({int limit, int page})
      get _loadBookmarks => _bookmarkRepository.getMarkedBookmarks;

  @override
  bool Function(String) get _bookmarkIdFilter => (id) {
        final bookmark = super._bookmarkUseCases.getBookmark(id);
        if (bookmark == null) {
          return false;
        }
        return super._optimisticMarked[bookmark.id] ?? bookmark.isMarked;
      };
}

class ArchivedViewmodel extends BaseBookmarksViewmodel {
  ArchivedViewmodel(super._bookmarkRepository, super._bookmarkOperationUseCases,
      super._bookmarkUseCases, super._labelUseCases);

  @override
  Future<ResultDart<List<Bookmark>, Exception>> Function({int limit, int page})
      get _loadBookmarks => _bookmarkRepository.getArchivedBookmarks;

  @override
  bool Function(String) get _bookmarkIdFilter => (id) {
        final bookmark = super._bookmarkUseCases.getBookmark(id);
        if (bookmark == null) {
          return false;
        }
        return super._optimisticArchived[bookmark.id] ?? bookmark.isArchived;
      };
}

class UnarchivedViewmodel extends BaseBookmarksViewmodel {
  UnarchivedViewmodel(
      super._bookmarkRepository,
      super._bookmarkOperationUseCases,
      super._bookmarkUseCases,
      super._labelUseCases);

  @override
  Future<ResultDart<List<Bookmark>, Exception>> Function({int limit, int page})
      get _loadBookmarks => _bookmarkRepository.getUnarchivedBookmarks;

  @override
  bool Function(String) get _bookmarkIdFilter => (id) {
        final bookmark = super._bookmarkUseCases.getBookmark(id);
        if (bookmark == null) {
          return false;
        }
        return !(_optimisticArchived[bookmark.id] ?? bookmark.isArchived);
      };
}

abstract class BaseBookmarksViewmodel extends ChangeNotifier {
  BaseBookmarksViewmodel(
      this._bookmarkRepository,
      this._bookmarkOperationUseCases,
      this._bookmarkUseCases,
      this._labelUseCases) {
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

    // 注册书签数据变化监听器
    _bookmarkUseCases.addListener(_onBookmarksChanged);
    // 注册标签数据变化监听器
    _labelUseCases.addListener(_onLabelsChanged);
  }

  final BookmarkRepository _bookmarkRepository;
  final BookmarkOperationUseCases _bookmarkOperationUseCases;
  final BookmarkUseCases _bookmarkUseCases;
  final LabelUseCases _labelUseCases;

  final Map<String, bool> _optimisticArchived = {};
  final Map<String, bool> _optimisticMarked = {};
  final Map<String, ReadingStats> _readingStats = {};
  // 移除本地 _labels 变量，改用中心化存储
  final List<String> _bookmarkIds = [];
  List<Bookmark> get _bookmarks => _bookmarkUseCases
      .getBookmarks(_bookmarkIds.where(_bookmarkIdFilter).toList())
      .whereType<Bookmark>()
      .toList();
  int _currentPage = 1;
  bool _hasMoreData = true;
  late Command<int, List<Bookmark>> load;
  late Command<int, List<Bookmark>> loadMore;
  late Command<String, void> openUrl;
  late Command<Bookmark, void> toggleBookmarkMarked;
  late Command<Bookmark, void> toggleBookmarkArchived;
  late Command<void, List<String>> loadLabels;

  bool Function(String) get _bookmarkIdFilter => (v) => true;

  void _addBookmarkIds(List<Bookmark> bookmarks) {
    _bookmarkIds.addAll(bookmarks.map((e) => e.id));
    _bookmarkUseCases.insertOrUpdateBookmarks(bookmarks);
  }

  void _clearAndSetBookmarks(List<Bookmark> bookmarks) {
    _bookmarkIds.clear();
    _bookmarkIds.addAll(bookmarks.map((e) => e.id));
    _bookmarkUseCases.insertOrUpdateBookmarks(bookmarks);
  }

  List<Bookmark> get bookmarks {
    return _bookmarks
        .map((item) => item.copyWith(
            isArchived: _optimisticArchived[item.id] ?? item.isArchived,
            isMarked: _optimisticMarked[item.id] ?? item.isMarked))
        .toList();
  }

  bool get hasMoreData => _hasMoreData;
  bool get isLoadingMore => loadMore.isExecuting.value;

  List<String> get availableLabels => _labelUseCases.labelNames;

  /// 获取书签的阅读统计数据
  ReadingStats? getReadingStats(String bookmarkId) {
    return _readingStats[bookmarkId];
  }

  Future<ResultDart<List<Bookmark>, Exception>> Function({int limit, int page})
      get _loadBookmarks;

  Future<List<Bookmark>> _load(int page) async {
    var limit = 10;
    _currentPage = page;
    final result = await _loadBookmarks(limit: limit, page: page);
    final bookmarks = result.getOrThrow();
    _clearAndSetBookmarks(bookmarks);
    _hasMoreData = bookmarks.length == limit;

    // 加载阅读统计数据
    final stats = await _bookmarkOperationUseCases
        .loadReadingStatsForBookmarks(bookmarks);
    _readingStats.addAll(stats);

    notifyListeners();
    return bookmarks;
  }

  Future<List<Bookmark>> _loadMore(int page) async {
    if (!_hasMoreData) return _bookmarkUseCases.bookmarks;

    var limit = 10;
    _currentPage = page;
    final result = await _loadBookmarks(limit: limit, page: page);
    final newBookmarks = result.getOrThrow();

    if (newBookmarks.isNotEmpty) {
      _addBookmarkIds(newBookmarks);
      _hasMoreData = newBookmarks.length == limit;

      // 加载新书签的阅读统计数据
      final stats = await _bookmarkOperationUseCases
          .loadReadingStatsForBookmarks(newBookmarks);
      _readingStats.addAll(stats);
    } else {
      _hasMoreData = false;
    }

    notifyListeners();
    return _bookmarkUseCases.bookmarks;
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
      appLogger.e("Failed to toggle bookmark marked",
          error: result.exceptionOrNull()!);
      _optimisticMarked.remove(bookmark.id);
      notifyListeners();
      throw result.exceptionOrNull()!;
    }
  }

  Future<void> _toggleBookmarkArchived(Bookmark bookmark) async {
    // 乐观更新
    _optimisticArchived[bookmark.id] = !bookmark.isArchived;
    notifyListeners();

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
