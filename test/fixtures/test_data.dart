import 'package:readeck_app/domain/models/daily_read_history/daily_read_history.dart';
import 'package:readeck_app/domain/models/bookmark_article/bookmark_article.dart';

/// 测试用的书签文章数据
class TestBookmarkArticleData {
  static BookmarkArticle createSample({
    int? id,
    String? bookmarkId,
    String? article,
    String? translate,
    DateTime? createdDate,
  }) {
    return BookmarkArticle(
      id: id,
      bookmarkId: bookmarkId ?? 'test-bookmark-1',
      article: article ?? 'This is a test article content',
      translate: translate,
      createdDate: createdDate ?? DateTime.now(),
    );
  }

  static List<BookmarkArticle> createMultipleSamples(int count) {
    return List.generate(
        count,
        (index) => createSample(
              bookmarkId: 'test-bookmark-${index + 1}',
              article: 'Test article content ${index + 1}',
            ));
  }
}

/// 测试用的每日阅读历史数据
class TestDailyReadHistoryData {
  static DailyReadHistory createSample({
    int? id,
    DateTime? createdDate,
    List<String>? bookmarkIds,
  }) {
    return DailyReadHistory(
      id: id ?? 1,
      createdDate: createdDate ?? DateTime.now(),
      bookmarkIds: bookmarkIds ?? ['bookmark1', 'bookmark2'],
    );
  }

  static List<DailyReadHistory> createMultipleSamples(int count) {
    return List.generate(
        count,
        (index) => createSample(
              bookmarkIds: ['bookmark${index + 1}', 'bookmark${index + 2}'],
            ));
  }
}

/// 测试用的书签ID列表
class TestBookmarkIds {
  static const List<String> sample1 = ['bookmark1', 'bookmark2', 'bookmark3'];
  static const List<String> sample2 = ['bookmark4', 'bookmark5'];
  static const List<String> empty = [];
  static const List<String> single = ['bookmark1'];
  static const List<String> large = [
    'bookmark1',
    'bookmark2',
    'bookmark3',
    'bookmark4',
    'bookmark5',
    'bookmark6',
    'bookmark7',
    'bookmark8',
    'bookmark9',
    'bookmark10'
  ];
}
