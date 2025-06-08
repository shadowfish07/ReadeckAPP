import 'package:logging/logging.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/utils/result.dart';
import 'package:url_launcher/url_launcher.dart';

class BookmarkOperationUseCases {
  BookmarkOperationUseCases(this._bookmarkRepository);

  final BookmarkRepository _bookmarkRepository;

  final _log = Logger("BookmarkOperationUseCases");

  Future<Result<void>> toggleBookmarkMarked(Bookmark bookmark) async {
    return _bookmarkRepository.toggleMarked(bookmark);
  }

  Future<Result<void>> toggleBookmarkArchived(Bookmark bookmark) async {
    return _bookmarkRepository.toggleArchived(bookmark);
  }

  Future<Result<void>> openUrl(String url) async {
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
        _log.info("外部应用启动失败，尝试其他模式", e);
        launched = false;
      }

      // 如果外部应用启动失败，尝试使用平台默认方式
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (e) {
          _log.info("平台默认方式启动失败", e);
          launched = false;
        }
      }

      // 如果仍然失败，尝试使用内置WebView
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
        } catch (e) {
          _log.warning("内置WebView启动失败", e);
          launched = false;
        }
      }

      if (!launched) {
        _log.warning("无法打开链接：$url");
        return Result.error(Exception("无法打开链接"));
      }

      return const Result.ok(null);
    } catch (e) {
      _log.warning("打开链接时发生错误：$url", e);
      return Result.error(Exception("打开链接时发生错误"));
    }
  }
}
