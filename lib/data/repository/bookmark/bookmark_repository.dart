import 'dart:math';

import 'package:readeck_app/data/service/database_service.dart';
import 'package:readeck_app/data/service/openrouter_api_client.dart';
import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/bookmark/label_info.dart';
import 'package:readeck_app/domain/models/bookmark_article/bookmark_article.dart';
import 'package:readeck_app/main.dart';
import 'package:result_dart/result_dart.dart';

class BookmarkRepository {
  BookmarkRepository(
      this._readeckApiClient, this._databaseService, this._openRouterApiClient);

  final ReadeckApiClient _readeckApiClient;
  final DatabaseService _databaseService;
  final OpenRouterApiClient _openRouterApiClient;

  AsyncResult<List<Bookmark>> getBookmarksByIds(List<String> ids) async {
    return _readeckApiClient.getBookmarks(ids: ids);
  }

  AsyncResult<List<Bookmark>> getUnarchivedBookmarks({
    int limit = 10,
    int page = 1,
  }) async {
    return _readeckApiClient.getBookmarks(
      isArchived: false,
      limit: limit,
      offset: (page - 1) * limit,
    );
  }

  AsyncResult<List<Bookmark>> getArchivedBookmarks({
    int limit = 10,
    int page = 1,
  }) async {
    return _readeckApiClient.getBookmarks(
      isArchived: true,
      limit: limit,
      offset: (page - 1) * limit,
    );
  }

  AsyncResult<List<Bookmark>> getMarkedBookmarks({
    int limit = 10,
    int page = 1,
  }) async {
    return _readeckApiClient.getBookmarks(
      isMarked: true,
      limit: limit,
      offset: (page - 1) * limit,
    );
  }

  AsyncResult<List<Bookmark>> getRandomUnarchivedBookmarks(
      int randomCount) async {
    final allBookmarks = await getUnarchivedBookmarks(limit: 100);

    if (allBookmarks.isSuccess()) {
      // 随机打乱并取前5个
      final shuffled = List<Bookmark>.from(allBookmarks.getOrDefault([]));
      shuffled.shuffle(Random());

      return Success(shuffled.take(5).toList());
    }

    appLogger.w('获取所有未读书签失败: $allBookmarks');
    return allBookmarks;
  }

  AsyncResult<void> toggleMarked(Bookmark bookmark) async {
    return _readeckApiClient.updateBookmark(
      bookmark.id,
      isMarked: !bookmark.isMarked,
    );
  }

  AsyncResult<void> toggleArchived(Bookmark bookmark) async {
    return _readeckApiClient.updateBookmark(
      bookmark.id,
      isArchived: !bookmark.isArchived,
    );
  }

  AsyncResult<List<LabelInfo>> getLabels() async {
    return _readeckApiClient.getLabels();
  }

  AsyncResult<void> updateLabels(Bookmark bookmark, List<String> labels) async {
    final result = await _readeckApiClient.updateBookmark(
      bookmark.id,
      labels: labels,
    );

    if (result.isSuccess()) {
      return const Success(unit);
    }

    return Failure(result.exceptionOrNull()!);
  }

  AsyncResult<void> updateReadProgress(
      String bookmarkId, int readProgress) async {
    final result = await _readeckApiClient.updateBookmark(
      bookmarkId,
      readProgress: readProgress,
    );

    if (result.isSuccess()) {
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
    return _readeckApiClient.deleteBookmark(bookmarkId);
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
