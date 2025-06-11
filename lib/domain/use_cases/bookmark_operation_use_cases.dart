import 'package:logger/logger.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:result_dart/result_dart.dart';
import 'package:url_launcher/url_launcher.dart';

class BookmarkOperationUseCases {
  BookmarkOperationUseCases(this._bookmarkRepository);

  final BookmarkRepository _bookmarkRepository;

  final _log = Logger();

  AsyncResult<void> toggleBookmarkMarked(Bookmark bookmark) async {
    return _bookmarkRepository.toggleMarked(bookmark);
  }

  AsyncResult<void> toggleBookmarkArchived(Bookmark bookmark) async {
    return _bookmarkRepository.toggleArchived(bookmark);
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
}
