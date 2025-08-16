import 'package:readeck_app/data/repository/article/article_repository.dart';
import 'package:readeck_app/data/repository/reading_stats/reading_stats_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/bookmark_display_model/bookmark_display_model.dart';

import 'package:readeck_app/main.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';
import 'package:result_dart/result_dart.dart';
import 'package:url_launcher/url_launcher.dart';

class BookmarkOperationUseCases {
  BookmarkOperationUseCases(
      this._articleRepository, this._readingStatsRepository);

  final ArticleRepository _articleRepository;
  final ReadingStatsRepository _readingStatsRepository;

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
  Future<Map<String, ReadingStatsForView>> loadReadingStatsForBookmarks(
      List<Bookmark> bookmarks) async {
    final Map<String, ReadingStatsForView> readingStats = {};
    for (final bookmark in bookmarks) {
      final stats = await loadReadingStatsForBookmark(bookmark);
      if (stats != null) {
        readingStats[bookmark.id] = stats;
      }
    }
    return readingStats;
  }

  /// 为单个书签加载阅读统计数据
  Future<ReadingStatsForView?> loadReadingStatsForBookmark(
      Bookmark bookmark) async {
    try {
      // 首先尝试从数据库中读取
      final cachedStatsResult =
          await _readingStatsRepository.getReadingStats(bookmark.id);
      if (cachedStatsResult.isSuccess() &&
          cachedStatsResult.getOrNull() != null) {
        appLogger.d('从数据库加载书签 ${bookmark.id} 的阅读统计数据');
        return cachedStatsResult.getOrNull()!;
      }

      // 数据库中没有，获取文章内容并计算
      final articleResult =
          await _articleRepository.getBookmarkArticle(bookmark.id);
      if (articleResult.isSuccess()) {
        final htmlContent = articleResult.getOrNull()!;
        final statsResult = await _readingStatsRepository
            .calculateAndSaveReadingStats(bookmark.id, htmlContent);

        if (statsResult.isSuccess()) {
          final stats = statsResult.getOrNull()!;
          appLogger.i('成功计算并保存书签 ${bookmark.id} 的阅读统计数据');
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

  void handleBookmarkTap({
    required BookmarkDisplayModel bookmark,
    required void Function(Bookmark) onNavigateToDetail,
  }) {
    appLogger.i('处理书签点击: ${bookmark.bookmark.title}');

    if (bookmark.stats == null) {
      appLogger.i('书签没有阅读统计数据，可能文章内容为空，使用浏览器打开: ${bookmark.bookmark.url}');
      openUrl(bookmark.bookmark.url);
    } else {
      appLogger.i('书签有阅读统计数据，触发详情页导航');
      onNavigateToDetail(bookmark.bookmark);
    }
  }
}
