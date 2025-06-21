import 'dart:math';

import 'package:logger/logger.dart';
import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/bookmark/label_info.dart';
import 'package:result_dart/result_dart.dart';

class BookmarkRepository {
  BookmarkRepository(this._readeckApiClient);

  final ReadeckApiClient _readeckApiClient;

  final _log = Logger();

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

  AsyncResult<List<Bookmark>> getRandomUnarchivedBookmarks(
      int randomCount) async {
    final allBookmarks = await getUnarchivedBookmarks(limit: 100);

    if (allBookmarks.isSuccess()) {
      // 随机打乱并取前5个
      final shuffled = List<Bookmark>.from(allBookmarks.getOrDefault([]));
      shuffled.shuffle(Random());

      return Success(shuffled.take(5).toList());
    }

    _log.w('获取所有未读书签失败: $allBookmarks');
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
}
