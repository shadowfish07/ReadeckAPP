import 'package:flutter/foundation.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:logger/logger.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';

class UnarchivedViewmodel extends ChangeNotifier {
  UnarchivedViewmodel(
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
  }

  final _log = Logger();
  final BookmarkRepository _bookmarkRepository;
  final BookmarkOperationUseCases _bookmarkOperationUseCases;
  List<Bookmark> _bookmarks = [];
  final Map<String, bool> _optimisticArchived = {};
  final Map<String, bool> _optimisticMarked = {};
  int _currentPage = 1;
  bool _hasMoreData = true;
  late Command<int, List<Bookmark>> load;
  late Command<int, List<Bookmark>> loadMore;
  late Command<String, void> openUrl;
  late Command<Bookmark, void> toggleBookmarkMarked;
  late Command<Bookmark, void> toggleBookmarkArchived;

  List<Bookmark> get bookmarks {
    return _bookmarks
        .map((item) => item.copyWith(
            isArchived: _optimisticArchived[item.id] ?? item.isArchived,
            isMarked: _optimisticMarked[item.id] ?? item.isMarked))
        .toList();
  }

  bool get hasMoreData => _hasMoreData;
  bool get isLoadingMore => loadMore.isExecuting.value;

  Future<List<Bookmark>> _load(int page) async {
    var limit = 5;
    _currentPage = page;
    final result = await _bookmarkRepository.getUnarchivedBookmarks(
        limit: limit, page: page);
    final bookmarks = result.getOrThrow();
    _bookmarks = bookmarks;
    _hasMoreData = bookmarks.length == limit;
    notifyListeners();
    return bookmarks;
  }

  Future<List<Bookmark>> _loadMore(int page) async {
    if (!_hasMoreData) return _bookmarks;

    var limit = 5;
    _currentPage = page;
    final result = await _bookmarkRepository.getUnarchivedBookmarks(
        limit: limit, page: page);
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
}
