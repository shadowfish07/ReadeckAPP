import 'package:readeck_app/data/repository/article/article_repository.dart';
import 'package:readeck_app/data/service/shared_preference_service.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';

import 'package:readeck_app/main.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';
import 'package:result_dart/result_dart.dart';
import 'package:url_launcher/url_launcher.dart';

class BookmarkOperationUseCases {
  BookmarkOperationUseCases(
      this._articleRepository, this._sharedPreferencesService);

  final ArticleRepository _articleRepository;
  final SharedPreferencesService _sharedPreferencesService;
  final ReadingStatsCalculator _readingStatsCalculator =
      const ReadingStatsCalculator();

  AsyncResult<void> openUrl(String url) async {
    try {
      final uri = Uri.parse(url);

      // 首先尝试使用外部应用打开
      bool launched = false;

      try {
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        // 外部应用启动失败，尝试其他模式
        appLogger.i("外部应用启动失败，尝试其他模式");
        launched = false;
      }

      // 如果外部应用启动失败，尝试使用平台默认方式
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (e) {
          appLogger.i("平台默认方式启动失败");
          launched = false;
        }
      }

      // 如果仍然失败，尝试使用内置WebView
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
        } catch (e) {
          appLogger.w("内置WebView启动失败");
          launched = false;
        }
      }

      if (!launched) {
        appLogger.w("无法打开链接：$url");
        return Failure(Exception("无法打开链接"));
      }

      return const Success(unit);
    } catch (e) {
      appLogger.w("打开链接时发生错误：$url");
      return Failure(Exception("打开链接时发生错误"));
    }
  }

  /// 为书签列表加载阅读统计数据
  Future<Map<String, ReadingStats>> loadReadingStatsForBookmarks(
      List<Bookmark> bookmarks) async {
    final Map<String, ReadingStats> readingStats = {};
    for (final bookmark in bookmarks) {
      final stats = await loadReadingStatsForBookmark(bookmark);
      if (stats != null) {
        readingStats[bookmark.id] = stats;
      }
    }
    return readingStats;
  }

  /// 为单个书签加载阅读统计数据
  Future<ReadingStats?> loadReadingStatsForBookmark(Bookmark bookmark) async {
    try {
      // 首先尝试从缓存中读取
      final cachedStatsResult =
          await _sharedPreferencesService.getReadingStats(bookmark.id);
      if (cachedStatsResult.isSuccess() &&
          cachedStatsResult.getOrNull() != null) {
        appLogger.d('从缓存加载书签 ${bookmark.id} 的阅读统计数据');
        return cachedStatsResult.getOrNull()!;
      }

      // 缓存中没有，获取文章内容并计算
      final articleResult =
          await _articleRepository.getBookmarkArticle(bookmark.id);
      if (articleResult.isSuccess()) {
        final htmlContent = articleResult.getOrNull()!;
        final statsResult =
            _readingStatsCalculator.calculateReadingStats(htmlContent);

        if (statsResult.isSuccess()) {
          final stats = statsResult.getOrNull()!;

          // 保存到缓存
          final saveResult = await _sharedPreferencesService.setReadingStats(
              bookmark.id, stats);
          if (saveResult.isSuccess()) {
            appLogger.i('成功缓存书签 ${bookmark.id} 的阅读统计数据');
          } else {
            appLogger.w(
                '缓存书签 ${bookmark.id} 的阅读统计数据失败: ${saveResult.exceptionOrNull()}');
          }

          return stats;
        } else {
          appLogger.w(
              '计算书签 ${bookmark.id} 的阅读统计数据失败: ${statsResult.exceptionOrNull()}');
        }
      } else {
        appLogger.w(
            '获取书签 ${bookmark.id} 的文章内容失败: ${articleResult.exceptionOrNull()}');
      }
    } catch (e) {
      appLogger.e('处理书签 ${bookmark.id} 的阅读统计数据时发生错误: $e');
    }
    return null;
  }
}
