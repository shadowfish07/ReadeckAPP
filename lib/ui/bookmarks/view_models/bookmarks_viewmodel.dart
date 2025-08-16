import 'package:flutter/foundation.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/bookmark_display_model/bookmark_display_model.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';
import 'package:readeck_app/data/repository/label/label_repository.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';
import 'package:result_dart/result_dart.dart';

class MarkedViewmodel extends BaseBookmarksViewmodel {
  MarkedViewmodel(super._bookmarkRepository, super._bookmarkOperationUseCases,
      super._labelRepository);

  @override
  Future<Result<List<BookmarkDisplayModel>>> Function({int limit, int page})
      get _loadBookmarks => _bookmarkRepository.loadMarkedBookmarks;
}

class ArchivedViewmodel extends BaseBookmarksViewmodel {
  ArchivedViewmodel(super._bookmarkRepository, super._bookmarkOperationUseCases,
      super._labelRepository);

  @override
  Future<Result<List<BookmarkDisplayModel>>> Function({int limit, int page})
      get _loadBookmarks => _bookmarkRepository.loadArchivedBookmarks;
}

class UnarchivedViewmodel extends BaseBookmarksViewmodel {
  UnarchivedViewmodel(super._bookmarkRepository,
      super._bookmarkOperationUseCases, super._labelRepository);

  @override
  Future<Result<List<BookmarkDisplayModel>>> Function({int limit, int page})
      get _loadBookmarks => _bookmarkRepository.loadUnarchivedBookmarks;
}

class ReadingViewmodel extends BaseBookmarksViewmodel {
  ReadingViewmodel(super._bookmarkRepository, super._bookmarkOperationUseCases,
      super._labelRepository);

  @override
  Future<Result<List<BookmarkDisplayModel>>> Function({int limit, int page})
      get _loadBookmarks => _bookmarkRepository.loadReadingBookmarks;
}

abstract class BaseBookmarksViewmodel extends ChangeNotifier {
  BaseBookmarksViewmodel(this._bookmarkRepository,
      this._bookmarkOperationUseCases, this._labelRepository) {
    load = Command.createAsync<int, List<BookmarkDisplayModel>>(_load,
        initialValue: [], includeLastResultInCommandResults: true)
      ..execute(1);
    loadMore = Command.createAsync<int, List<BookmarkDisplayModel>>(_loadMore,
        initialValue: [], includeLastResultInCommandResults: true);
    openUrl = Command.createAsyncNoResult(_openUrl);
    toggleBookmarkMarked = Command.createAsyncNoResult<BookmarkDisplayModel>(
        _toggleBookmarkMarked);
    toggleBookmarkArchived = Command.createAsyncNoResult<BookmarkDisplayModel>(
        _toggleBookmarkArchived);
    loadLabels = Command.createAsyncNoParam(_loadLabels, initialValue: []);

    // 注册书签数据变化监听器
    _bookmarkRepository.addListener(_onBookmarksChanged);
    // 注册标签数据变化监听器
    _labelRepository.addListener(_onLabelsChanged);
  }

  final BookmarkRepository _bookmarkRepository;
  final BookmarkOperationUseCases _bookmarkOperationUseCases;
  final LabelRepository _labelRepository;

  final List<BookmarkDisplayModel> _bookmarks = [];
  int _currentPage = 1;
  bool _hasMoreData = true;
  late Command<int, List<BookmarkDisplayModel>> load;
  late Command<int, List<BookmarkDisplayModel>> loadMore;
  late Command<String, void> openUrl;
  late Command<BookmarkDisplayModel, void> toggleBookmarkMarked;
  late Command<BookmarkDisplayModel, void> toggleBookmarkArchived;
  late Command<void, List<String>> loadLabels;

  List<BookmarkDisplayModel> get bookmarks => _bookmarks;

  bool get hasMoreData => _hasMoreData;
  bool get isLoadingMore => loadMore.isExecuting.value;

  List<String> get availableLabels => _labelRepository.labelNames;

  Future<Result<List<BookmarkDisplayModel>>> Function({int limit, int page})
      get _loadBookmarks;

  ReadingStatsForView? getReadingStats(String bookmarkId) {
    final idx =
        _bookmarks.indexWhere((element) => element.bookmark.id == bookmarkId);
    return idx == -1 ? null : _bookmarks[idx].stats;
  }

  Future<List<BookmarkDisplayModel>> _load(int page) async {
    var limit = 10;
    _currentPage = page;
    final result = await _loadBookmarks(limit: limit, page: page);
    final newBookmarks = result.getOrThrow();
    _bookmarks.clear();
    _bookmarks.addAll(newBookmarks);
    _hasMoreData = newBookmarks.length == limit;

    notifyListeners();
    return _bookmarks;
  }

  Future<List<BookmarkDisplayModel>> _loadMore(int page) async {
    if (!_hasMoreData) return _bookmarks;

    var limit = 10;
    _currentPage = page;
    final result = await _loadBookmarks(limit: limit, page: page);
    final newBookmarks = result.getOrThrow();

    if (newBookmarks.isNotEmpty) {
      _bookmarks.addAll(newBookmarks);
      _hasMoreData = newBookmarks.length == limit;
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

  /// 处理书签点击，根据文章内容状态决定打开方式
  void handleBookmarkTap(BookmarkDisplayModel bookmark) {
    _bookmarkOperationUseCases.handleBookmarkTap(
      bookmark: bookmark,
      onNavigateToDetail: _navigateToDetail,
    );
  }

  /// 触发详情页导航的回调
  void Function(Bookmark)? _onNavigateToDetail;

  /// 设置详情页导航回调
  void setNavigateToDetailCallback(void Function(Bookmark) callback) {
    _onNavigateToDetail = callback;
  }

  /// 导航到详情页
  void _navigateToDetail(Bookmark bookmark) {
    _onNavigateToDetail?.call(bookmark);
  }

  Future<void> _toggleBookmarkMarked(BookmarkDisplayModel bookmark) async {
    final result = await _bookmarkRepository.toggleMarked(bookmark.bookmark);

    if (result.isError()) {
      appLogger.e("Failed to toggle bookmark marked",
          error: result.exceptionOrNull()!);
      throw result.exceptionOrNull()!;
    }
  }

  Future<void> _toggleBookmarkArchived(BookmarkDisplayModel bookmark) async {
    final result = await _bookmarkRepository.toggleArchived(bookmark.bookmark);

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
