import 'package:readeck_app/domain/models/daily_read_history/daily_read_history.dart';
import 'package:readeck_app/domain/models/bookmark_article/bookmark_article.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/bookmark/label_info.dart';

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

/// 测试用的书签数据
class TestBookmarkData {
  static Bookmark createSample({
    String? id,
    String? title,
    String? url,
    String? siteName,
    String? description,
    bool? isMarked,
    bool? isArchived,
    int? readProgress,
    List<String>? labels,
    DateTime? created,
    String? imageUrl,
  }) {
    return Bookmark(
      id: id ?? 'test-bookmark-1',
      title: title ?? 'Test Bookmark Title',
      url: url ?? 'https://example.com/test',
      siteName: siteName ?? 'example.com',
      description: description ?? 'Test bookmark description',
      isMarked: isMarked ?? false,
      isArchived: isArchived ?? false,
      readProgress: readProgress ?? 0,
      labels: labels ?? ['tech', 'flutter'],
      created: created ?? DateTime.parse('2024-01-01T00:00:00Z'),
      imageUrl: imageUrl,
    );
  }

  static List<Bookmark> createMultipleSamples(int count) {
    return List.generate(
      count,
      (index) => createSample(
        id: 'test-bookmark-${index + 1}',
        title: 'Test Bookmark ${index + 1}',
        url: 'https://example.com/test-${index + 1}',
      ),
    );
  }

  static Map<String, dynamic> createSampleJson({
    String? id,
    String? title,
    String? url,
    String? siteName,
    String? description,
    bool? isMarked,
    bool? isArchived,
    int? readProgress,
    List<String>? labels,
    String? created,
    String? imageUrl,
  }) {
    return {
      'id': id ?? 'test-bookmark-1',
      'title': title ?? 'Test Bookmark Title',
      'url': url ?? 'https://example.com/test',
      'site_name': siteName ?? 'example.com',
      'description': description ?? 'Test bookmark description',
      'is_marked': isMarked ?? false,
      'is_archived': isArchived ?? false,
      'read_progress': readProgress ?? 0,
      'labels': labels ?? ['tech', 'flutter'],
      'created': created ?? '2024-01-01T00:00:00Z',
      'image_url': imageUrl,
    };
  }
}

/// 测试用的标签数据
class TestLabelData {
  static LabelInfo createSample({
    String? name,
    int? count,
    String? href,
    String? hrefBookmarks,
  }) {
    return LabelInfo(
      name: name ?? 'tech',
      count: count ?? 10,
      href: href ?? '/api/labels/tech',
      hrefBookmarks: hrefBookmarks ?? '/api/bookmarks?labels=tech',
    );
  }

  static List<LabelInfo> createMultipleSamples(int count) {
    return List.generate(
      count,
      (index) => createSample(
        name: 'label-${index + 1}',
        count: (index + 1) * 5,
      ),
    );
  }

  static Map<String, dynamic> createSampleJson({
    String? name,
    int? count,
  }) {
    return {
      'name': name ?? 'tech',
      'count': count ?? 10,
    };
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
