import 'package:readeck_app/domain/models/bookmark/bookmark.dart';

/// 表示需要导航到详情页的异常
/// 用于在 Command 中通知 UI 需要进行页面导航
class NavigationNeededException implements Exception {
  final Bookmark bookmark;

  const NavigationNeededException(this.bookmark);

  @override
  String toString() => 'Navigation needed for bookmark: ${bookmark.id}';
}
