import 'package:flutter/foundation.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';
import 'package:readeck_app/data/repository/label/label_repository.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';
import 'package:result_dart/result_dart.dart';

class MarkedViewmodel extends BaseBookmarksViewmodel {
  MarkedViewmodel(super._bookmarkRepository, super._bookmarkOperationUseCases,
      super._labelRepository);

  @override
  Future<ResultDart<List<Bookmark>, Exception>> Function({int limit, int page})
      get _loadBookmarks => _bookmarkRepository.loadMarkedBookmarks;

  @override
  bool Function(String) get _bookmarkIdFilter => (id) {
        final bookmark = super._bookmarkRepository.getCachedBookmark(id);
        if (bookmark == null) {
          return false;
        }
        return bookmark.isMarked;
      };
}

class ArchivedViewmodel extends BaseBookmarksViewmodel {
  ArchivedViewmodel(super._bookmarkRepository, super._bookmarkOperationUseCases,
      super._labelRepository);

  @override
  Future<ResultDart<List<Bookmark>, Exception>> Function({int limit, int page})
      get _loadBookmarks => _bookmarkRepository.loadArchivedBookmarks;

  @override
  bool Function(String) get _bookmarkIdFilter => (id) {
        final bookmark = super._bookmarkRepository.getCachedBookmark(id);
        if (bookmark == null) {
          return false;
        }
        return bookmark.isArchived;
      };
}

class UnarchivedViewmodel extends BaseBookmarksViewmodel {
  UnarchivedViewmodel(super._bookmarkRepository,
      super._bookmarkOperationUseCases, super._labelRepository);

  @override
  Future<ResultDart<List<Bookmark>, Exception>> Function({int limit, int page})
      get _loadBookmarks => _bookmarkRepository.loadUnarchivedBookmarks;

  @override
  bool Function(String) get _bookmarkIdFilter => (id) {
        final bookmark = super._bookmarkRepository.getCachedBookmark(id);
        if (bookmark == null) {
          return false;
        }
        return !bookmark.isArchived;
      };
}

abstract class BaseBookmarksViewmodel extends ChangeNotifier {
  BaseBookmarksViewmodel(this._bookmarkRepository,
      this._bookmarkOperationUseCases, this._labelRepository) {
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
    _bookmarkRepository.addListener(_onBookmarksChanged);
    // 注册标签数据变化监听器
    _labelRepository.addListener(_onLabelsChanged);
  }

  final BookmarkRepository _bookmarkRepository;
  final BookmarkOperationUseCases _bookmarkOperationUseCases;
  final LabelRepository _labelRepository;

  final Map<String, ReadingStats> _readingStats = {};
  // 移除本地 _labels 变量，改用中心化存储
  final List<String> _bookmarkIds = [];
  List<Bookmark> get _bookmarks => _bookmarkRepository
      .getCachedBookmarks(_bookmarkIds.where(_bookmarkIdFilter).toList())
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
  }

  void _resetBookmarks(List<Bookmark> bookmarks) {
    _bookmarkIds.clear();
    _bookmarkIds.addAll(bookmarks.map((e) => e.id));
  }

  List<Bookmark> get bookmarks {
    return _bookmarks;
  }

  bool get hasMoreData => _hasMoreData;
  bool get isLoadingMore => loadMore.isExecuting.value;

  List<String> get availableLabels => _labelRepository.labelNames;

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
    _resetBookmarks(bookmarks);
    _hasMoreData = bookmarks.length == limit;

    // 加载阅读统计数据
    final stats = await _bookmarkOperationUseCases
        .loadReadingStatsForBookmarks(bookmarks);
    _readingStats.addAll(stats);

    notifyListeners();
    return bookmarks;
  }

  Future<List<Bookmark>> _loadMore(int page) async {
    if (!_hasMoreData) return _bookmarkRepository.bookmarks;

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
    return _bookmarkRepository.bookmarks;
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
    final result = await _bookmarkRepository.toggleMarked(bookmark);

    if (result.isError()) {
      appLogger.e("Failed to toggle bookmark marked",
          error: result.exceptionOrNull()!);
      throw result.exceptionOrNull()!;
    }
  }

  Future<void> _toggleBookmarkArchived(Bookmark bookmark) async {
    final result = await _bookmarkRepository.toggleArchived(bookmark);

    if (result.isError()) {
      appLogger.e("Failed to toggle bookmark archived",
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
