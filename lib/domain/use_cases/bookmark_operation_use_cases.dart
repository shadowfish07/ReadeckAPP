import 'package:logger/logger.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/service/shared_preference_service.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/use_cases/bookmark_use_cases.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';
import 'package:result_dart/result_dart.dart';
import 'package:url_launcher/url_launcher.dart';

class BookmarkOperationUseCases {
  BookmarkOperationUseCases(this._bookmarkRepository,
      this._sharedPreferencesService, this._bookmarkUseCases);

  final BookmarkUseCases _bookmarkUseCases;
  final BookmarkRepository _bookmarkRepository;
  final SharedPreferencesService _sharedPreferencesService;
  final ReadingStatsCalculator _readingStatsCalculator =
      const ReadingStatsCalculator();

  final _log = Logger();

  AsyncResult<void> toggleBookmarkMarked(Bookmark bookmark) async {
    final result = await _bookmarkRepository.toggleMarked(bookmark);
    if (result.isSuccess()) {
      _bookmarkUseCases.insertOrUpdateBookmark(
          bookmark.copyWith(isMarked: !bookmark.isMarked));
    }
    return result;
  }

  AsyncResult<void> toggleBookmarkArchived(Bookmark bookmark) async {
    final result = await _bookmarkRepository.toggleArchived(bookmark);
    if (result.isSuccess()) {
      _bookmarkUseCases.insertOrUpdateBookmark(
          bookmark.copyWith(isArchived: !bookmark.isArchived));
    }
    return result;
  }

  AsyncResult<void> updateBookmarkLabels(
      Bookmark bookmark, List<String> labels) async {
    final result = await _bookmarkRepository.updateLabels(bookmark, labels);
    if (result.isSuccess()) {
      _bookmarkUseCases
          .insertOrUpdateBookmark(bookmark.copyWith(labels: labels));
    }
    return result;
  }

  AsyncResult<void> deleteBookmark(String bookmarkId) async {
    final result = await _bookmarkRepository.deleteBookmark(bookmarkId);
    if (result.isSuccess()) {
      _bookmarkUseCases.deleteBookmark(bookmarkId);
    }
    return result;
  }

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
        _log.i("外部应用启动失败，尝试其他模式");
        launched = false;
      }

      // 如果外部应用启动失败，尝试使用平台默认方式
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (e) {
          _log.i("平台默认方式启动失败");
          launched = false;
        }
      }

      // 如果仍然失败，尝试使用内置WebView
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
        } catch (e) {
          _log.w("内置WebView启动失败");
          launched = false;
        }
      }

      if (!launched) {
        _log.w("无法打开链接：$url");
        return Failure(Exception("无法打开链接"));
      }

      return const Success(unit);
    } catch (e) {
      _log.w("打开链接时发生错误：$url");
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
        _log.d('从缓存加载书签 ${bookmark.id} 的阅读统计数据');
        return cachedStatsResult.getOrNull()!;
      }

      // 缓存中没有，获取文章内容并计算
      final articleResult =
          await _bookmarkRepository.getBookmarkArticle(bookmark.id);
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
            _log.d('成功缓存书签 ${bookmark.id} 的阅读统计数据');
          } else {
            _log.w(
                '缓存书签 ${bookmark.id} 的阅读统计数据失败: ${saveResult.exceptionOrNull()}');
          }

          return stats;
        } else {
          _log.w(
              '计算书签 ${bookmark.id} 的阅读统计数据失败: ${statsResult.exceptionOrNull()}');
        }
      } else {
        _log.w(
            '获取书签 ${bookmark.id} 的文章内容失败: ${articleResult.exceptionOrNull()}');
      }
    } catch (e) {
      _log.e('处理书签 ${bookmark.id} 的阅读统计数据时发生错误: $e');
    }
    return null;
  }
}
