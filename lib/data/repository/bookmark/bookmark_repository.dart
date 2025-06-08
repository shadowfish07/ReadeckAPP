import 'dart:math';

import 'package:logging/logging.dart';
import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/utils/result.dart';

class BookmarkRepository {
  BookmarkRepository(this._readeckApiClient);

  final ReadeckApiClient _readeckApiClient;

  final _log = Logger("BookmarkRepository");

  Future<Result<List<Bookmark>>> getBookmarksByIds(List<String> ids) async {
    return _readeckApiClient.getBookmarks(ids: ids);
  }

  Future<Result<List<Bookmark>>> getUnreadBookmarks(int limit) async {
    return _readeckApiClient.getBookmarks(
      readStatus: 'unread',
      limit: limit,
    );
  }

  Future<Result<List<Bookmark>>> getRandomUnreadBookmarks(
      int randomCount) async {
    final allBookmarks = await getUnreadBookmarks(100);

    if (allBookmarks is Ok<List<Bookmark>>) {
      // 随机打乱并取前5个
      final shuffled = List<Bookmark>.from(allBookmarks.value);
      shuffled.shuffle(Random());

      return Result.ok(shuffled.take(5).toList());
    }

    _log.warning('获取所有未读书签失败: $allBookmarks');
    return allBookmarks;
  }

  Future<Result<void>> toggleMarked(Bookmark bookmark) async {
    return _readeckApiClient.updateBookmark(
      bookmark.id,
      isMarked: !bookmark.isMarked,
    );
  }

  Future<Result<void>> toggleArchived(Bookmark bookmark) async {
    return _readeckApiClient.updateBookmark(
      bookmark.id,
      isArchived: !bookmark.isArchived,
    );
  }
}
