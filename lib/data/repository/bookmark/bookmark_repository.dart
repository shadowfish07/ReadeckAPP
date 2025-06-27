import 'dart:math';

import 'package:readeck_app/data/service/database_service.dart';
import 'package:readeck_app/data/service/openrouter_api_client.dart';
import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/bookmark_article/bookmark_article.dart';
import 'package:readeck_app/main.dart';
import 'package:result_dart/result_dart.dart';

/// 书签数据变化监听器类型定义
typedef BookmarkChangeListener = void Function();

class BookmarkRepository {
  BookmarkRepository(
      this._readeckApiClient, this._databaseService, this._openRouterApiClient);

  final ReadeckApiClient _readeckApiClient;
  final DatabaseService _databaseService;
  final OpenRouterApiClient _openRouterApiClient;

  // 全局共享数据管理 - 单一数据源
  final List<Bookmark> _bookmarks = [];
  final List<BookmarkChangeListener> _listeners = [];

  /// 获取所有缓存的书签（只读）
  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  /// 添加数据变化监听器
  void addListener(BookmarkChangeListener listener) {
    _listeners.add(listener);
  }

  /// 移除数据变化监听器
  void removeListener(BookmarkChangeListener listener) {
    _listeners.remove(listener);
  }

  /// 通知所有监听器数据已变化
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// 插入或更新单个书签到缓存
  void insertOrUpdateBookmark(Bookmark bookmark) {
    final index = _bookmarks.indexWhere((b) => b.id == bookmark.id);
    if (index != -1) {
      _bookmarks[index] = bookmark;
    } else {
      _bookmarks.add(bookmark);
    }
    _notifyListeners();
  }

  /// 批量插入或更新书签到缓存
  void _insertOrUpdateCachedBookmarks(List<Bookmark> bookmarks) {
    for (var bookmark in bookmarks) {
      insertOrUpdateBookmark(bookmark);
    }
  }

  /// 从缓存获取单个书签
  Bookmark? getCachedBookmark(String id) {
    return _bookmarks.where((b) => b.id == id).firstOrNull;
  }

  /// 从缓存获取多个书签
  List<Bookmark?> getCachedBookmarks(List<String> ids) {
    return ids.map((id) => getCachedBookmark(id)).toList();
  }

  /// 从缓存删除书签
  void _deleteCachedBookmark(String id) {
    _bookmarks.removeWhere((b) => b.id == id);
    _notifyListeners();
  }

  /// 释放资源，清空所有监听器
  void dispose() {
    _listeners.clear();
  }

  AsyncResult<List<Bookmark>> loadBookmarksByIds(List<String> ids) async {
    final result = await _readeckApiClient.getBookmarks(ids: ids);
    if (result.isSuccess()) {
      _insertOrUpdateCachedBookmarks(result.getOrThrow());
      return result;
    }

    return result;
  }

  AsyncResult<List<Bookmark>> loadUnarchivedBookmarks({
    int limit = 10,
    int page = 1,
  }) async {
    final result = await _readeckApiClient.getBookmarks(
      isArchived: false,
      limit: limit,
      offset: (page - 1) * limit,
    );
    if (result.isSuccess()) {
      _insertOrUpdateCachedBookmarks(result.getOrThrow());
      return result;
    }

    return result;
  }

  AsyncResult<List<Bookmark>> loadArchivedBookmarks({
    int limit = 10,
    int page = 1,
  }) async {
    final result = await _readeckApiClient.getBookmarks(
      isArchived: true,
      limit: limit,
      offset: (page - 1) * limit,
    );
    if (result.isSuccess()) {
      _insertOrUpdateCachedBookmarks(result.getOrThrow());
      return result;
    }

    return result;
  }

  AsyncResult<List<Bookmark>> loadMarkedBookmarks({
    int limit = 10,
    int page = 1,
  }) async {
    final result = await _readeckApiClient.getBookmarks(
      isMarked: true,
      limit: limit,
      offset: (page - 1) * limit,
    );
    if (result.isSuccess()) {
      _insertOrUpdateCachedBookmarks(result.getOrThrow());
      return result;
    }

    return result;
  }

  AsyncResult<List<Bookmark>> loadRandomUnarchivedBookmarks(
      int randomCount) async {
    final allBookmarks = await loadUnarchivedBookmarks(limit: 100);

    if (allBookmarks.isSuccess()) {
      _insertOrUpdateCachedBookmarks(allBookmarks.getOrThrow());

      // 随机打乱并取前5个
      final shuffled = List<Bookmark>.from(allBookmarks.getOrDefault([]));
      shuffled.shuffle(Random());

      return Success(shuffled.take(5).toList());
    }

    appLogger.w('获取所有未读书签失败: $allBookmarks');
    return allBookmarks;
  }

  AsyncResult<void> toggleMarked(Bookmark bookmark) async {
    final result = await _readeckApiClient.updateBookmark(
      bookmark.id,
      isMarked: !bookmark.isMarked,
    );
    if (result.isSuccess()) {
      insertOrUpdateBookmark(bookmark.copyWith(isMarked: !bookmark.isMarked));
    }
    return result;
  }

  AsyncResult<void> toggleArchived(Bookmark bookmark) async {
    final result = await _readeckApiClient.updateBookmark(
      bookmark.id,
      isArchived: !bookmark.isArchived,
    );
    if (result.isSuccess()) {
      insertOrUpdateBookmark(
          bookmark.copyWith(isArchived: !bookmark.isArchived));
    }
    return result;
  }

  AsyncResult<void> updateLabels(Bookmark bookmark, List<String> labels) async {
    final result = await _readeckApiClient.updateBookmark(
      bookmark.id,
      labels: labels,
    );

    if (result.isSuccess()) {
      insertOrUpdateBookmark(bookmark.copyWith(labels: labels));
      return const Success(unit);
    }

    return Failure(result.exceptionOrNull()!);
  }

  AsyncResult<void> updateReadProgress(
      Bookmark bookmark, int readProgress) async {
    final result = await _readeckApiClient.updateBookmark(
      bookmark.id,
      readProgress: readProgress,
    );

    if (result.isSuccess()) {
      insertOrUpdateBookmark(bookmark.copyWith(readProgress: readProgress));
      return const Success(unit);
    }

    return Failure(result.exceptionOrNull()!);
  }

  /// 获取书签的文章内容
  /// 优先从缓存获取，如果缓存没有则从API获取并写入缓存
  AsyncResult<String> getBookmarkArticle(String bookmarkId) async {
    // 首先尝试从缓存获取
    final cachedResult =
        await _databaseService.getBookmarkArticleByBookmarkId(bookmarkId);

    if (cachedResult.isSuccess()) {
      final cachedArticle = cachedResult.getOrNull()!;
      appLogger.i('从缓存获取文章内容成功: $bookmarkId');
      return Success(cachedArticle.article);
    }

    // 缓存中没有，从API获取
    appLogger.i('缓存中未找到文章，从API获取: $bookmarkId');
    final apiResult = await _readeckApiClient.getBookmarkArticle(bookmarkId);

    if (apiResult.isSuccess()) {
      final articleContent = apiResult.getOrNull()!;

      // 将获取的内容写入缓存
      final bookmarkArticle = BookmarkArticle(
        bookmarkId: bookmarkId,
        article: articleContent,
        translate: null,
        createdDate: DateTime.now(),
      );

      final cacheResult =
          await _databaseService.insertOrUpdateBookmarkArticle(bookmarkArticle);
      if (cacheResult.isSuccess()) {
        appLogger
            .i('文章内容已缓存: $bookmarkId 。大小: ${bookmarkArticle.article.length}');
      } else {
        appLogger.w('缓存文章内容失败: $bookmarkId',
            error: cacheResult.exceptionOrNull());
      }

      return Success(articleContent);
    }

    // API获取失败
    appLogger.e('从API获取文章内容失败: $bookmarkId',
        error: apiResult.exceptionOrNull());
    return apiResult;
  }

  /// 删除书签
  AsyncResult<void> deleteBookmark(String bookmarkId) async {
    final result = await _readeckApiClient.deleteBookmark(bookmarkId);
    if (result.isSuccess()) {
      _deleteCachedBookmark(bookmarkId);
      await _databaseService.deleteBookmarkArticle(bookmarkId);
    }
    return result;
  }

  /// 翻译书签内容（流式输出）
  /// 优先从缓存获取翻译，如果缓存没有则使用AI翻译并写入缓存
  Stream<Result<String>> translateBookmarkContentStream(
      String bookmarkId, String originalContent) async* {
    try {
      appLogger.i('开始翻译书签内容: $bookmarkId');

      // 首先尝试从缓存获取翻译
      final cachedResult =
          await _databaseService.getBookmarkArticleByBookmarkId(bookmarkId);

      if (cachedResult.isSuccess()) {
        final cachedArticle = cachedResult.getOrNull()!;
        if (cachedArticle.translate != null &&
            cachedArticle.translate!.isNotEmpty) {
          appLogger.i('从缓存获取翻译内容成功: $bookmarkId');
          yield Success(cachedArticle.translate!);
          return;
        }
      }

      // 缓存中没有翻译，使用AI进行翻译
      appLogger.i('缓存中未找到翻译，使用AI翻译: $bookmarkId');

      // 构建翻译提示
      final messages = [
        {
          'role': 'system',
          'content':
              '你是一个专业的翻译助手。请将用户提供的HTML内容翻译成中文，保持HTML标签结构不变，只翻译文本内容。请确保翻译准确、流畅、符合中文表达习惯。'
        },
        {'role': 'user', 'content': originalContent}
      ];

      // 使用流式API进行翻译
      final translationStream = _openRouterApiClient.streamChatCompletion(
        model: 'google/gemini-2.5-flash',
        messages: messages,
        temperature: 0.3,
      );

      String translatedContent = '';

      await for (final result in translationStream) {
        if (result.isSuccess()) {
          final chunk = result.getOrThrow();
          appLogger.d("AI翻译内容 chunk: $chunk");
          translatedContent += chunk;
          // 流式输出累积的翻译内容
          yield Success(translatedContent);
        } else {
          final error = result.exceptionOrNull();
          appLogger.e('AI翻译失败: $error');
          yield Failure(error ?? Exception('AI翻译失败'));
          return;
        }
      }

      // 将翻译结果保存到缓存
      await _saveTranslationToCache(
          bookmarkId, originalContent, translatedContent);

      appLogger.i('AI翻译完成: $bookmarkId');
    } catch (e) {
      appLogger.e('翻译异常: $bookmarkId', error: e);
      yield Failure(Exception('翻译失败: $e'));
    }
  }

  /// 将翻译结果保存到缓存
  Future<void> _saveTranslationToCache(String bookmarkId,
      String originalContent, String translatedContent) async {
    try {
      // 检查是否已有文章缓存
      final existingResult =
          await _databaseService.getBookmarkArticleByBookmarkId(bookmarkId);

      BookmarkArticle articleToSave;

      if (existingResult.isSuccess()) {
        // 更新现有缓存的翻译字段
        final existingArticle = existingResult.getOrNull()!;
        articleToSave = BookmarkArticle(
          id: existingArticle.id,
          bookmarkId: existingArticle.bookmarkId,
          article: existingArticle.article,
          translate: translatedContent,
          createdDate: existingArticle.createdDate,
        );
      } else {
        // 创建新的缓存记录
        articleToSave = BookmarkArticle(
          bookmarkId: bookmarkId,
          article: originalContent,
          translate: translatedContent,
          createdDate: DateTime.now(),
        );
      }

      final cacheResult =
          await _databaseService.insertOrUpdateBookmarkArticle(articleToSave);
      if (cacheResult.isSuccess()) {
        appLogger.i('翻译内容已缓存: $bookmarkId');
      } else {
        appLogger.w('缓存翻译内容失败: $bookmarkId',
            error: cacheResult.exceptionOrNull());
      }
    } catch (e) {
      appLogger.w('保存翻译缓存时发生异常: $bookmarkId', error: e);
    }
  }
}
