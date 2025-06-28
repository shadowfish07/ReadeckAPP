import 'dart:math';

import 'package:readeck_app/data/repository/settings/settings_repository.dart';
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
  BookmarkRepository(this._readeckApiClient, this._databaseService,
      this._openRouterApiClient, this._settingsRepository);

  final ReadeckApiClient _readeckApiClient;
  final DatabaseService _databaseService;
  final OpenRouterApiClient _openRouterApiClient;
  final SettingsRepository _settingsRepository;

  // 全局共享数据管理 - 单一数据源
  final List<Bookmark> _bookmarks = [];
  final List<BookmarkChangeListener> _listeners = [];

  /// 获取所有缓存的书签（只读）
  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

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
  void _insertOrUpdateBookmark(Bookmark bookmark, {bool batch = false}) {
    final index = _bookmarks.indexWhere((b) => b.id == bookmark.id);
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
  void _insertOrUpdateCachedBookmarks(List<Bookmark> bookmarks) {
    appLogger.i('批量更新缓存书签，数量: ${bookmarks.length}');
    for (var bookmark in bookmarks) {
      _insertOrUpdateBookmark(bookmark, batch: true);
    }
    _notifyListeners();
  }

  /// 从缓存获取单个书签
  Bookmark? getCachedBookmark(String id) {
    final bookmark = _bookmarks.where((b) => b.id == id).firstOrNull;
    return bookmark;
  }

  /// 从缓存获取多个书签
  List<Bookmark?> getCachedBookmarks(List<String> ids) {
    appLogger.d('从缓存批量获取书签，请求数量: ${ids.length}');
    final result = ids.map((id) => getCachedBookmark(id)).toList();
    final foundCount = result.where((b) => b != null).length;
    appLogger.d('批量获取书签完成，找到: $foundCount/${ids.length}');
    return result;
  }

  /// 从缓存删除书签
  void _deleteCachedBookmark(String id) {
    final removedCount = _bookmarks.length;
    _bookmarks.removeWhere((b) => b.id == id);
    final actualRemovedCount = removedCount - _bookmarks.length;
    appLogger.i('从缓存删除书签: $id, 删除数量: $actualRemovedCount');
    _notifyListeners();
  }

  /// 释放资源，清空所有监听器
  void dispose() {
    appLogger.i('释放 BookmarkRepository 资源，清空 ${_listeners.length} 个监听器');
    _listeners.clear();
  }

  AsyncResult<List<Bookmark>> loadBookmarksByIds(List<String> ids) async {
    appLogger.i('开始根据ID加载书签，数量: ${ids.length}');
    final result = await _readeckApiClient.getBookmarks(ids: ids);
    if (result.isSuccess()) {
      final bookmarks = result.getOrThrow();
      appLogger.i('成功加载书签 ${bookmarks.length} 个');
      _insertOrUpdateCachedBookmarks(bookmarks);
      return result;
    }

    appLogger.e('根据ID加载书签失败', error: result.exceptionOrNull());
    return result;
  }

  AsyncResult<List<Bookmark>> loadUnarchivedBookmarks({
    int limit = 10,
    int page = 1,
  }) async {
    appLogger.i('开始加载未归档书签，页码: $page, 限制: $limit');
    final result = await _readeckApiClient.getBookmarks(
      isArchived: false,
      limit: limit,
      offset: (page - 1) * limit,
    );
    if (result.isSuccess()) {
      final bookmarks = result.getOrThrow();
      appLogger.i('成功加载未归档书签 ${bookmarks.length} 个');
      _insertOrUpdateCachedBookmarks(bookmarks);
      return result;
    }

    appLogger.e('加载未归档书签失败', error: result.exceptionOrNull());
    return result;
  }

  AsyncResult<List<Bookmark>> loadArchivedBookmarks({
    int limit = 10,
    int page = 1,
  }) async {
    appLogger.i('开始加载已归档书签，页码: $page, 限制: $limit');
    final result = await _readeckApiClient.getBookmarks(
      isArchived: true,
      limit: limit,
      offset: (page - 1) * limit,
    );
    if (result.isSuccess()) {
      final bookmarks = result.getOrThrow();
      appLogger.i('成功加载已归档书签 ${bookmarks.length} 个');
      _insertOrUpdateCachedBookmarks(bookmarks);
      return result;
    }

    appLogger.e('加载已归档书签失败', error: result.exceptionOrNull());
    return result;
  }

  AsyncResult<List<Bookmark>> loadMarkedBookmarks({
    int limit = 10,
    int page = 1,
  }) async {
    appLogger.i('开始加载已标记书签，页码: $page, 限制: $limit');
    final result = await _readeckApiClient.getBookmarks(
      isMarked: true,
      limit: limit,
      offset: (page - 1) * limit,
    );
    if (result.isSuccess()) {
      final bookmarks = result.getOrThrow();
      appLogger.i('成功加载已标记书签 ${bookmarks.length} 个');
      _insertOrUpdateCachedBookmarks(bookmarks);
      return result;
    }

    appLogger.e('加载已标记书签失败', error: result.exceptionOrNull());
    return result;
  }

  AsyncResult<List<Bookmark>> loadRandomUnarchivedBookmarks(
      int randomCount) async {
    appLogger.i('开始加载随机未归档书签，请求数量: $randomCount');
    final allBookmarks = await loadUnarchivedBookmarks(limit: 100);

    if (allBookmarks.isSuccess()) {
      _insertOrUpdateCachedBookmarks(allBookmarks.getOrThrow());

      // 随机打乱并取前5个
      final shuffled = List<Bookmark>.from(allBookmarks.getOrDefault([]));
      shuffled.shuffle(Random());
      final randomBookmarks = shuffled.take(5).toList();

      appLogger.i('成功获取随机未归档书签 ${randomBookmarks.length} 个');
      return Success(randomBookmarks);
    }

    appLogger.w('获取所有未读书签失败: $allBookmarks');
    return allBookmarks;
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
      _insertOrUpdateBookmark(bookmark.copyWith(isMarked: newMarkedState));
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
      _insertOrUpdateBookmark(bookmark.copyWith(isArchived: newArchivedState));
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
      _insertOrUpdateBookmark(bookmark.copyWith(labels: labels));
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
      _insertOrUpdateBookmark(bookmark.copyWith(readProgress: readProgress));
      appLogger.i('书签阅读进度更新成功: ${bookmark.id}');
      return const Success(unit);
    }

    appLogger.e('书签阅读进度更新失败: ${bookmark.id}', error: result.exceptionOrNull());
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
    appLogger.i('开始删除书签: $bookmarkId');
    final result = await _readeckApiClient.deleteBookmark(bookmarkId);
    if (result.isSuccess()) {
      _deleteCachedBookmark(bookmarkId);
      await _databaseService.deleteBookmarkArticle(bookmarkId);
      appLogger.i('书签删除成功: $bookmarkId');
    } else {
      appLogger.e('书签删除失败: $bookmarkId', error: result.exceptionOrNull());
    }
    return result;
  }

  /// 翻译书签内容（流式输出）
  /// 根据缓存配置决定是否使用缓存，如果启用缓存则优先从缓存获取翻译
  Stream<Result<String>> translateBookmarkContentStream(
      String bookmarkId, String originalContent) async* {
    try {
      appLogger.i('开始翻译书签内容: $bookmarkId');

      // 获取翻译缓存配置
      final cacheEnabledResult =
          await _settingsRepository.getTranslationCacheEnabled();
      final isCacheEnabled = cacheEnabledResult.getOrDefault(true); // 默认启用缓存

      // 获取翻译目标语言
      final targetLanguageResult =
          await _settingsRepository.getTranslationTargetLanguage();
      final targetLanguage = targetLanguageResult.getOrDefault('中文'); // 默认中文

      appLogger.d('翻译缓存配置: ${isCacheEnabled ? "启用" : "禁用"}');
      appLogger.d('翻译目标语言: $targetLanguage');

      // 如果启用缓存，首先尝试从缓存获取翻译
      if (isCacheEnabled) {
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
      } else {
        appLogger.i('翻译缓存已禁用，直接使用AI翻译: $bookmarkId');
      }

      // 缓存中没有翻译，使用AI进行翻译
      appLogger.i('缓存中未找到翻译，使用AI翻译: $bookmarkId');

      // 根据目标语言构建翻译提示
      final systemPrompt = _buildTranslationSystemPrompt(targetLanguage);
      final messages = [
        {'role': 'system', 'content': systemPrompt},
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

      // 如果启用缓存，将翻译结果保存到缓存
      if (isCacheEnabled) {
        await _saveTranslationToCache(
            bookmarkId, originalContent, translatedContent);
      } else {
        appLogger.d('翻译缓存已禁用，不保存翻译结果: $bookmarkId');
      }

      appLogger.i('AI翻译完成: $bookmarkId');
    } catch (e) {
      appLogger.e('翻译异常: $bookmarkId', error: e);
      yield Failure(Exception('翻译失败: $e'));
    }
  }

  /// 根据目标语言构建翻译系统提示
  String _buildTranslationSystemPrompt(String targetLanguage) {
    return 'You are a professional translation assistant. Please translate the provided HTML content into $targetLanguage, keeping the HTML tag structure unchanged and only translating the text content. Ensure the translation is accurate, fluent, and follows the expression habits of $targetLanguage.';
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
