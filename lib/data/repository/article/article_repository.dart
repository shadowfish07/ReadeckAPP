import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/data/service/database_service.dart';
import 'package:readeck_app/data/service/openrouter_api_client.dart';
import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/domain/models/bookmark_article/bookmark_article.dart';
import 'package:readeck_app/main.dart';
import 'package:result_dart/result_dart.dart';

/// 文章内容和翻译管理Repository
/// 负责文章内容的获取、缓存和翻译功能
class ArticleRepository {
  ArticleRepository(
    this._readeckApiClient,
    this._databaseService,
    this._openRouterApiClient,
    this._settingsRepository,
  );

  final ReadeckApiClient _readeckApiClient;
  final DatabaseService _databaseService;
  final OpenRouterApiClient _openRouterApiClient;
  final SettingsRepository _settingsRepository;

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

  /// 删除书签对应的文章缓存
  AsyncResult<void> deleteBookmarkArticle(String bookmarkId) async {
    appLogger.i('删除书签文章缓存: $bookmarkId');
    final result = await _databaseService.deleteBookmarkArticle(bookmarkId);
    if (result.isSuccess()) {
      appLogger.i('书签文章缓存删除成功: $bookmarkId');
    } else {
      appLogger.e('书签文章缓存删除失败: $bookmarkId', error: result.exceptionOrNull());
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
      final isCacheEnabled = _settingsRepository.getTranslationCacheEnabled();

      // 获取翻译目标语言
      final targetLanguage = _settingsRepository.getTranslationTargetLanguage();

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
      final translationPrompt =
          _buildTranslationPrompt(targetLanguage, originalContent);

      // 使用流式Completion API进行翻译
      final translationStream = _openRouterApiClient.streamCompletion(
        // TODO 使用设置里的模型
        model: 'google/gemini-2.5-flash',
        prompt: translationPrompt,
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

  /// 根据目标语言构建翻译提示
  String _buildTranslationPrompt(String targetLanguage, String content) {
    return '''You are a professional translation assistant. Please translate the following HTML content into $targetLanguage, keeping the HTML tag structure unchanged and only translating the text content. Ensure the translation is accurate, fluent, and follows the expression habits of $targetLanguage.

Content to translate:
$content

Translated content:''';
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

  /// 清空所有翻译缓存
  AsyncResult<void> clearTranslationCache() async {
    final result = await _databaseService.clearAllTranslationCache();
    if (result.isError()) {
      appLogger.e("清空翻译缓存失败", error: result.exceptionOrNull());
      return result;
    }
    return const Success(unit);
  }
}
