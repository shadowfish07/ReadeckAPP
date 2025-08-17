import 'dart:math';

import 'package:readeck_app/data/repository/article/article_repository.dart';
import 'package:readeck_app/data/repository/reading_stats/reading_stats_repository.dart';
import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/bookmark_display_model/bookmark_display_model.dart';
import 'package:readeck_app/main.dart';
import 'package:result_dart/result_dart.dart';

/// 书签数据变化监听器类型定义
typedef BookmarkChangeListener = void Function();

class BookmarkRepository {
  BookmarkRepository(this._readeckApiClient, this._readingStatsRepository,
      this._articleRepository);

  final ReadeckApiClient _readeckApiClient;
  final ReadingStatsRepository _readingStatsRepository;
  final ArticleRepository _articleRepository;

  // 全局共享数据管理 - 单一数据源
  final List<BookmarkDisplayModel> _bookmarks = [];
  final List<BookmarkChangeListener> _listeners = [];

  /// 获取所有缓存的书签（只读）
  List<BookmarkDisplayModel> get bookmarks => List.unmodifiable(_bookmarks);

  /// 添加数据变化监听器
  void addListener(BookmarkChangeListener listener) {
    _listeners.add(listener);
    appLogger.d('添加书签数据变化监听器，当前监听器数量: ${_listeners.length}');
  }

  /// 移除数据变化监听器
  void removeListener(BookmarkChangeListener listener) {
    _listeners.remove(listener);
    appLogger.d('移除书签数据变化监听器，当前监听器数量: ${_listeners.length}');
  }

  /// 通知所有监听器数据已变化
  void _notifyListeners() {
    appLogger.d('通知 ${_listeners.length} 个监听器书签数据已变化');
    for (final listener in _listeners) {
      listener();
    }
  }

  /// 插入或更新单个书签到缓存
  void _insertOrUpdateBookmark(BookmarkDisplayModel bookmark,
      {bool batch = false}) {
    final index =
        _bookmarks.indexWhere((b) => b.bookmark.id == bookmark.bookmark.id);
    if (index != -1) {
      _bookmarks[index] = bookmark;
    } else {
      _bookmarks.add(bookmark);
    }
    if (!batch) {
      _notifyListeners();
    }
  }

  /// 批量插入或更新书签到缓存
  void _insertOrUpdateCachedBookmarks(List<BookmarkDisplayModel> bookmarks) {
    appLogger.i('批量更新缓存书签，数量: ${bookmarks.length}');
    for (var bookmark in bookmarks) {
      _insertOrUpdateBookmark(bookmark, batch: true);
    }
    _notifyListeners();
  }

  /// 从缓存获取单个书签
  BookmarkDisplayModel? getCachedBookmark(String id) {
    final index = _bookmarks.indexWhere((b) => b.bookmark.id == id);
    if (index != -1) {
      return _bookmarks[index];
    }
    return null;
  }

  /// 从缓存获取多个书签
  List<BookmarkDisplayModel?> getCachedBookmarks(List<String> ids) {
    appLogger.d('从缓存批量获取书签，请求数量: ${ids.length}');
    final result = ids.map((id) => getCachedBookmark(id)).toList();
    final foundCount = result.where((b) => b != null).length;
    appLogger.d('批量获取书签完成，找到: $foundCount/${ids.length}');
    return result;
  }

  /// 从缓存删除书签
  void _deleteCachedBookmark(String id) {
    final removedCount = _bookmarks.length;
    _bookmarks.removeWhere((b) => b.bookmark.id == id);
    final actualRemovedCount = removedCount - _bookmarks.length;
    appLogger.i('从缓存删除书签: $id, 删除数量: $actualRemovedCount');
    _notifyListeners();
  }

  /// 释放资源，清空所有监听器
  void dispose() {
    appLogger.i('释放 BookmarkRepository 资源，清空 ${_listeners.length} 个监听器');
    _listeners.clear();
  }

  AsyncResult<List<BookmarkDisplayModel>> _wrapBookmarksWithStats(
    List<Bookmark> bookmarks,
  ) async {
    final models = await Future.wait(
      bookmarks.map((b) async {
        // 首先尝试从数据库中读取已有的阅读统计数据
        var statsRes = await _readingStatsRepository.getReadingStats(b.id);

        // 如果数据库中没有，尝试获取文章内容并计算
        if (statsRes.isError()) {
          try {
            final articleResult =
                await _articleRepository.getBookmarkArticle(b.id);
            if (articleResult.isSuccess()) {
              final htmlContent = articleResult.getOrThrow();
              final calculateResult = await _readingStatsRepository
                  .calculateAndSaveReadingStats(b.id, htmlContent);

              if (calculateResult.isSuccess()) {
                statsRes = Success(calculateResult.getOrThrow());
                appLogger.d('成功为书签 ${b.id} 计算并保存阅读统计数据');
              } else {
                appLogger.w(
                    '计算书签 ${b.id} 的阅读统计数据失败: ${calculateResult.exceptionOrNull()}');
              }
            } else {
              appLogger.w(
                  '获取书签 ${b.id} 的文章内容失败: ${articleResult.exceptionOrNull()}');
            }
          } catch (e) {
            appLogger.e('处理书签 ${b.id} 的阅读统计数据时发生错误: $e');
          }
        }

        return statsRes.isSuccess()
            ? BookmarkDisplayModel(bookmark: b, stats: statsRes.getOrThrow())
            : BookmarkDisplayModel(bookmark: b);
      }),
      eagerError: false,
    );
    return Success(models);
  }

  AsyncResult<List<BookmarkDisplayModel>> loadBookmarksByIds(
      List<String> ids) async {
    appLogger.i('开始根据ID加载书签，数量: ${ids.length}');
    final result = await _readeckApiClient.getBookmarks(ids: ids);
    return result.fold(
      (bookmarks) async {
        appLogger.i('成功加载书签 ${bookmarks.length} 个');
        final modelsResult = await _wrapBookmarksWithStats(bookmarks);
        if (modelsResult.isSuccess()) {
          _insertOrUpdateCachedBookmarks(modelsResult.getOrThrow());
        }
        return modelsResult;
      },
      (error) {
        appLogger.e('根据ID加载书签失败', error: error);
        return Failure(error);
      },
    );
  }

  AsyncResult<List<BookmarkDisplayModel>> loadUnarchivedBookmarks({
    int limit = 10,
    int page = 1,
  }) async {
    appLogger.i('开始加载未归档书签，页码: $page, 限制: $limit');
    final result = await _readeckApiClient.getBookmarks(
      isArchived: false,
      limit: limit,
      offset: (page - 1) * limit,
    );
    return result.fold(
      (bookmarks) async {
        appLogger.i('成功加载未归档书签 ${bookmarks.length} 个');
        final modelsResult = await _wrapBookmarksWithStats(bookmarks);
        if (modelsResult.isSuccess()) {
          _insertOrUpdateCachedBookmarks(modelsResult.getOrThrow());
        }
        return modelsResult;
      },
      (error) {
        appLogger.e('加载未归档书签失败', error: error);
        return Failure(error);
      },
    );
  }

  AsyncResult<List<BookmarkDisplayModel>> loadArchivedBookmarks({
    int limit = 10,
    int page = 1,
  }) async {
    appLogger.i('开始加载已归档书签，页码: $page, 限制: $limit');
    final result = await _readeckApiClient.getBookmarks(
      isArchived: true,
      limit: limit,
      offset: (page - 1) * limit,
    );
    return result.fold(
      (bookmarks) async {
        appLogger.i('成功加载已归档书签 ${bookmarks.length} 个');
        final modelsResult = await _wrapBookmarksWithStats(bookmarks);
        if (modelsResult.isSuccess()) {
          _insertOrUpdateCachedBookmarks(modelsResult.getOrThrow());
        }
        return modelsResult;
      },
      (error) {
        appLogger.e('加载已归档书签失败', error: error);
        return Failure(error);
      },
    );
  }

  AsyncResult<List<BookmarkDisplayModel>> loadMarkedBookmarks({
    int limit = 10,
    int page = 1,
  }) async {
    appLogger.i('开始加载已标记书签，页码: $page, 限制: $limit');
    final result = await _readeckApiClient.getBookmarks(
      isMarked: true,
      limit: limit,
      offset: (page - 1) * limit,
    );
    return result.fold(
      (bookmarks) async {
        appLogger.i('成功加载已标记书签 ${bookmarks.length} 个');
        final modelsResult = await _wrapBookmarksWithStats(bookmarks);
        if (modelsResult.isSuccess()) {
          _insertOrUpdateCachedBookmarks(modelsResult.getOrThrow());
        }
        return modelsResult;
      },
      (error) {
        appLogger.e('加载已标记书签失败', error: error);
        return Failure(error);
      },
    );
  }

  AsyncResult<List<BookmarkDisplayModel>> loadReadingBookmarks({
    int limit = 10,
    int page = 1,
  }) async {
    appLogger.i('开始加载阅读中书签，页码: $page, 限制: $limit');
    final result = await _readeckApiClient.getBookmarks(
      readStatus: 'reading',
      isArchived: false,
      limit: limit,
      offset: (page - 1) * limit,
    );
    return result.fold(
      (bookmarks) async {
        appLogger.i('成功加载阅读中书签 ${bookmarks.length} 个');
        final modelsResult = await _wrapBookmarksWithStats(bookmarks);
        if (modelsResult.isSuccess()) {
          _insertOrUpdateCachedBookmarks(modelsResult.getOrThrow());
        }
        return modelsResult;
      },
      (error) {
        appLogger.e('加载阅读中书签失败', error: error);
        return Failure(error);
      },
    );
  }

  AsyncResult<List<BookmarkDisplayModel>> loadRandomUnarchivedBookmarks(
      int randomCount) async {
    appLogger.i('开始加载随机未归档书签，请求数量: $randomCount');
    final allBookmarksResult = await loadUnarchivedBookmarks(limit: 100);

    if (allBookmarksResult.isSuccess()) {
      final allBookmarks = allBookmarksResult.getOrThrow();
      // 随机打乱并取前5个
      final shuffled = List<BookmarkDisplayModel>.from(allBookmarks);
      shuffled.shuffle(Random());
      final randomBookmarks = shuffled.take(randomCount).toList();

      appLogger.i('成功获取随机未归档书签 ${randomBookmarks.length} 个');
      return Success(randomBookmarks);
    }

    appLogger.w('获取所有未读书签失败: $allBookmarksResult');
    return allBookmarksResult;
  }

  AsyncResult<void> toggleMarked(Bookmark bookmark) async {
    final newMarkedState = !bookmark.isMarked;
    appLogger
        .i('切换书签标记状态: ${bookmark.id}, ${bookmark.isMarked} -> $newMarkedState');
    final result = await _readeckApiClient.updateBookmark(
      bookmark.id,
      isMarked: newMarkedState,
    );
    if (result.isSuccess()) {
      final existingModel = getCachedBookmark(bookmark.id);
      final updatedBookmark = bookmark.copyWith(isMarked: newMarkedState);
      _insertOrUpdateBookmark(
        BookmarkDisplayModel(
          bookmark: updatedBookmark,
          stats: existingModel?.stats,
        ),
      );
      appLogger.i('书签标记状态切换成功: ${bookmark.id}');
    } else {
      appLogger.e('书签标记状态切换失败: ${bookmark.id}',
          error: result.exceptionOrNull());
    }
    return result;
  }

  AsyncResult<void> toggleArchived(Bookmark bookmark) async {
    final newArchivedState = !bookmark.isArchived;
    appLogger.i(
        '切换书签归档状态: ${bookmark.id}, ${bookmark.isArchived} -> $newArchivedState');
    final result = await _readeckApiClient.updateBookmark(
      bookmark.id,
      isArchived: newArchivedState,
    );
    if (result.isSuccess()) {
      final existingModel = getCachedBookmark(bookmark.id);
      final updatedBookmark = bookmark.copyWith(isArchived: newArchivedState);
      _insertOrUpdateBookmark(
        BookmarkDisplayModel(
          bookmark: updatedBookmark,
          stats: existingModel?.stats,
        ),
      );
      appLogger.i('书签归档状态切换成功: ${bookmark.id}');
    } else {
      appLogger.e('书签归档状态切换失败: ${bookmark.id}',
          error: result.exceptionOrNull());
    }
    return result;
  }

  AsyncResult<void> updateLabels(Bookmark bookmark, List<String> labels) async {
    appLogger.i('更新书签标签: ${bookmark.id}, 标签: ${labels.join(", ")}');
    final result = await _readeckApiClient.updateBookmark(
      bookmark.id,
      labels: labels,
    );

    if (result.isSuccess()) {
      final existingModel = getCachedBookmark(bookmark.id);
      final updatedBookmark = bookmark.copyWith(labels: labels);
      _insertOrUpdateBookmark(
        BookmarkDisplayModel(
          bookmark: updatedBookmark,
          stats: existingModel?.stats,
        ),
      );
      appLogger.i('书签标签更新成功: ${bookmark.id}');
      return const Success(unit);
    }

    appLogger.e('书签标签更新失败: ${bookmark.id}', error: result.exceptionOrNull());
    return Failure(result.exceptionOrNull()!);
  }

  AsyncResult<void> updateReadProgress(
      Bookmark bookmark, int readProgress) async {
    appLogger.i(
        '更新书签阅读进度: ${bookmark.id}, 进度: ${bookmark.readProgress} -> $readProgress');
    final result = await _readeckApiClient.updateBookmark(
      bookmark.id,
      readProgress: readProgress,
    );

    if (result.isSuccess()) {
      final existingModel = getCachedBookmark(bookmark.id);
      final updatedBookmark = bookmark.copyWith(readProgress: readProgress);
      _insertOrUpdateBookmark(
        BookmarkDisplayModel(
          bookmark: updatedBookmark,
          stats: existingModel?.stats,
        ),
      );
      appLogger.i('书签阅读进度更新成功: ${bookmark.id}');
      return const Success(unit);
    }

    appLogger.e('书签阅读进度更新失败: ${bookmark.id}', error: result.exceptionOrNull());
    return Failure(result.exceptionOrNull()!);
  }

  /// 创建书签
  AsyncResult<void> createBookmark({
    required String url,
    String? title,
    List<String>? labels,
  }) async {
    appLogger.i('开始创建书签: $url');
    final result = await _readeckApiClient.createBookmark(
      url: url,
      title: title,
      labels: labels,
    );

    if (result.isSuccess()) {
      appLogger.i('书签创建请求已提交，正在异步处理: $url');
      // 不需要立即添加到缓存，因为书签还在异步处理中
      return const Success(unit);
    } else {
      appLogger.e('书签创建失败: $url', error: result.exceptionOrNull());
      return Failure(result.exceptionOrNull()!);
    }
  }

  /// 删除书签
  AsyncResult<void> deleteBookmark(String bookmarkId) async {
    appLogger.i('开始删除书签: $bookmarkId');
    final result = await _readeckApiClient.deleteBookmark(bookmarkId);
    if (result.isSuccess()) {
      _deleteCachedBookmark(bookmarkId);
      // 文章缓存由ArticleRepository独立管理
      appLogger.i('书签删除成功: $bookmarkId');
    } else {
      appLogger.e('书签删除失败: $bookmarkId', error: result.exceptionOrNull());
    }
    return result;
  }
}
