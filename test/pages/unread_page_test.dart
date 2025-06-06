import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readeck_app/pages/unread_page.dart';
import 'package:readeck_app/services/readeck_api_service.dart';
import 'package:readeck_app/models/bookmark.dart';

// Mock ReadeckApiService for testing
class MockReadeckApiService extends ReadeckApiService {
  List<Bookmark> _mockBookmarks = [];
  bool _shouldThrowError = false;
  bool _shouldDelay = false;
  int _delayMs = 100;
  String? _lastReadStatus;
  int? _lastLimit;
  int? _lastOffset;
  String? _lastSort;

  // 用于模拟分页
  static const int pageSize = 20;

  @override
  Future<void> initialize() async {
    // Mock initialization
  }

  @override
  Future<List<Bookmark>> getBookmarks({
    String? search,
    String? title,
    String? author,
    String? site,
    String? type,
    List<String>? labels,
    bool? isLoaded,
    bool? hasErrors,
    bool? hasLabels,
    bool? isMarked,
    bool? isArchived,
    String? rangeStart,
    String? rangeEnd,
    String? readStatus,
    String? updatedSince,
    List<String>? ids,
    String? collection,
    String? sort,
    int? limit,
    int? offset,
  }) async {
    // 记录最后一次调用的参数
    _lastReadStatus = readStatus;
    _lastLimit = limit;
    _lastOffset = offset;
    _lastSort = sort;

    if (_shouldDelay) {
      await Future.delayed(Duration(milliseconds: _delayMs));
    }

    if (_shouldThrowError) {
      throw Exception('网络错误');
    }

    // 模拟分页逻辑
    final startIndex = offset ?? 0;
    final endIndex = startIndex + (limit ?? pageSize);

    if (startIndex >= _mockBookmarks.length) {
      return [];
    }

    final result = _mockBookmarks.sublist(
      startIndex,
      endIndex > _mockBookmarks.length ? _mockBookmarks.length : endIndex,
    );

    // 只返回未读书签
    return result
        .where(
            (bookmark) => !bookmark.isArchived && bookmark.readProgress < 100)
        .toList();
  }

  @override
  Future<bool> toggleBookmarkMark(String bookmarkId, bool isMarked) async {
    if (_shouldDelay) {
      await Future.delayed(Duration(milliseconds: _delayMs));
    }

    if (_shouldThrowError) {
      throw Exception('标记操作失败');
    }

    // 更新mock数据中的标记状态
    final index = _mockBookmarks.indexWhere((b) => b.id == bookmarkId);
    if (index != -1) {
      final newMarkStatus = !isMarked;
      _mockBookmarks[index] =
          _mockBookmarks[index].copyWith(isMarked: newMarkStatus);
      return newMarkStatus;
    }
    return !isMarked;
  }

  @override
  Future<bool> toggleBookmarkArchive(String bookmarkId, bool isArchived) async {
    if (_shouldDelay) {
      await Future.delayed(Duration(milliseconds: _delayMs));
    }

    if (_shouldThrowError) {
      throw Exception('归档操作失败');
    }

    // 更新mock数据中的归档状态
    final index = _mockBookmarks.indexWhere((b) => b.id == bookmarkId);
    if (index != -1) {
      final newArchiveStatus = !isArchived;
      _mockBookmarks[index] =
          _mockBookmarks[index].copyWith(isArchived: newArchiveStatus);
      return newArchiveStatus;
    }
    return !isArchived;
  }

  // Test helper methods
  void setMockBookmarks(List<Bookmark> bookmarks) {
    _mockBookmarks = bookmarks;
  }

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  void setShouldDelay(bool shouldDelay, [int delayMs = 100]) {
    _shouldDelay = shouldDelay;
    _delayMs = delayMs;
  }

  void clearMockBookmarks() {
    _mockBookmarks.clear();
  }

  // 获取最后一次API调用的参数，用于验证
  String? get lastReadStatus => _lastReadStatus;
  int? get lastLimit => _lastLimit;
  int? get lastOffset => _lastOffset;
  String? get lastSort => _lastSort;
}

// 创建测试用的书签数据
List<Bookmark> createMockBookmarks(int count,
    {bool isMarked = false, bool isArchived = false}) {
  return List.generate(count, (index) {
    return Bookmark(
      id: 'bookmark_$index',
      title: '测试书签 ${index + 1}',
      url: 'https://example.com/article_$index',
      siteName: 'Example Site',
      description: '这是测试书签 ${index + 1} 的描述',
      created: DateTime.now().subtract(Duration(days: index)),
      isMarked: isMarked,
      isArchived: isArchived,
      readProgress: 0, // 未读状态
      labels: ['标签${index % 3 + 1}'],
      imageUrl: 'https://example.com/image_$index.jpg',
    );
  });
}

void main() {
  group('UnreadPage Tests', () {
    late MockReadeckApiService mockApiService;

    setUp(() {
      mockApiService = MockReadeckApiService();
    });

    testWidgets('应该显示未读页面的基本结构', (WidgetTester tester) async {
      // 设置mock数据
      mockApiService.setMockBookmarks(createMockBookmarks(5));

      await tester.pumpWidget(
        MaterialApp(
          home: UnreadPage(
            apiService: mockApiService,
            showAppBar: true,
          ),
        ),
      );

      // 验证AppBar
      expect(find.text('未读'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      // 等待数据加载完成
      await tester.pumpAndSettle();

      // 验证书签列表显示
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('应该正确展示后端数据', (WidgetTester tester) async {
      // 设置mock数据
      final mockBookmarks = createMockBookmarks(3);
      mockApiService.setMockBookmarks(mockBookmarks);

      await tester.pumpWidget(
        MaterialApp(
          home: UnreadPage(
            apiService: mockApiService,
          ),
        ),
      );

      // 等待数据加载完成
      await tester.pumpAndSettle();

      // 验证API调用参数
      expect(mockApiService.lastReadStatus, equals('unread'));
      expect(mockApiService.lastLimit, equals(20));
      expect(mockApiService.lastOffset, equals(0));
      expect(mockApiService.lastSort, equals('created_desc'));

      // 验证书签卡片显示
      expect(find.byType(Card), findsNWidgets(3));
      expect(find.text('测试书签 1'), findsOneWidget);
      expect(find.text('测试书签 2'), findsOneWidget);
      expect(find.text('测试书签 3'), findsOneWidget);

      // 验证书签详细信息
      expect(find.text('Example Site'), findsNWidgets(3));
      expect(find.byIcon(Icons.language), findsNWidgets(3));
      expect(find.byIcon(Icons.favorite_border), findsNWidgets(3));
      expect(find.byIcon(Icons.archive_outlined), findsNWidgets(3));
    });

    testWidgets('点击书签应该尝试打开外部应用', (WidgetTester tester) async {
      // 设置mock数据
      final mockBookmarks = createMockBookmarks(1);
      mockApiService.setMockBookmarks(mockBookmarks);

      await tester.pumpWidget(
        MaterialApp(
          home: UnreadPage(
            apiService: mockApiService,
          ),
        ),
      );

      // 等待数据加载完成
      await tester.pumpAndSettle();

      // 点击书签卡片
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      // 注意：由于url_launcher在测试环境中无法真正打开链接，
      // 这里主要验证点击事件被正确处理，实际的URL打开会显示错误提示
      // 可以通过检查是否显示了错误提示来验证点击事件被处理
    });

    testWidgets('点击喜爱按钮应该切换标记状态', (WidgetTester tester) async {
      // 设置mock数据
      final mockBookmarks = createMockBookmarks(1);
      mockApiService.setMockBookmarks(mockBookmarks);

      await tester.pumpWidget(
        MaterialApp(
          home: UnreadPage(
            apiService: mockApiService,
          ),
        ),
      );

      // 等待数据加载完成
      await tester.pumpAndSettle();

      // 验证初始状态（未标记）
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);

      // 点击喜爱按钮
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();

      // 验证状态已切换（已标记）
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);

      // 再次点击取消标记
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pumpAndSettle();

      // 验证状态已切换回未标记
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('点击存档按钮应该使书签消失并显示提示', (WidgetTester tester) async {
      // 设置mock数据
      final mockBookmarks = createMockBookmarks(2);
      mockApiService.setMockBookmarks(mockBookmarks);

      await tester.pumpWidget(
        MaterialApp(
          home: UnreadPage(
            apiService: mockApiService,
          ),
        ),
      );

      // 等待数据加载完成
      await tester.pumpAndSettle();

      // 验证初始状态有2个书签
      expect(find.byType(Card), findsNWidgets(2));
      expect(find.text('测试书签 1'), findsOneWidget);
      expect(find.text('测试书签 2'), findsOneWidget);

      // 点击第一个书签的存档按钮
      final archiveButtons = find.byIcon(Icons.archive_outlined);
      await tester.tap(archiveButtons.first);
      await tester.pumpAndSettle();

      // 验证书签已从列表中移除
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('测试书签 1'), findsNothing);
      expect(find.text('测试书签 2'), findsOneWidget);
    });

    testWidgets('应该支持下拉刷新', (WidgetTester tester) async {
      // 设置初始mock数据
      final initialBookmarks = createMockBookmarks(2);
      mockApiService.setMockBookmarks(initialBookmarks);

      await tester.pumpWidget(
        MaterialApp(
          home: UnreadPage(
            apiService: mockApiService,
          ),
        ),
      );

      // 等待初始数据加载完成
      await tester.pumpAndSettle();

      // 验证初始数据
      expect(find.byType(Card), findsNWidgets(2));

      // 验证RefreshIndicator存在
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('应该只显示未读状态的书签', (WidgetTester tester) async {
      // 创建混合状态的书签数据
      final unreadBookmarks = createMockBookmarks(3); // 未读
      final archivedBookmarks = createMockBookmarks(2, isArchived: true); // 已归档
      final readBookmarks = List.generate(
          2,
          (index) => Bookmark(
                id: 'read_bookmark_$index',
                title: '已读书签 ${index + 1}',
                url: 'https://example.com/read_$index',
                created: DateTime.now(),
                isMarked: false,
                isArchived: false,
                readProgress: 100, // 已读完
                labels: [],
              ));

      final allBookmarks = [
        ...unreadBookmarks,
        ...archivedBookmarks,
        ...readBookmarks
      ];
      mockApiService.setMockBookmarks(allBookmarks);

      await tester.pumpWidget(
        MaterialApp(
          home: UnreadPage(
            apiService: mockApiService,
          ),
        ),
      );

      // 等待数据加载完成
      await tester.pumpAndSettle();

      // 验证只显示未读书签
      expect(find.byType(Card), findsNWidgets(3));
      expect(find.text('测试书签 1'), findsOneWidget);
      expect(find.text('测试书签 2'), findsOneWidget);
      expect(find.text('测试书签 3'), findsOneWidget);

      // 验证不显示已归档或已读的书签
      expect(find.text('已读书签 1'), findsNothing);
      expect(find.text('已读书签 2'), findsNothing);
    });

    testWidgets('应该正确处理加载错误', (WidgetTester tester) async {
      // 设置API抛出错误
      mockApiService.setShouldThrowError(true);

      await tester.pumpWidget(
        MaterialApp(
          home: UnreadPage(
            apiService: mockApiService,
          ),
        ),
      );

      // 等待错误处理完成
      await tester.pumpAndSettle();

      // 验证显示错误状态
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('加载失败'), findsOneWidget);
      expect(find.textContaining('Exception'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);

      // 点击重试按钮
      mockApiService.setShouldThrowError(false);
      mockApiService.setMockBookmarks(createMockBookmarks(2));

      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();

      // 验证重试后数据正常显示
      expect(find.byType(Card), findsNWidgets(2));
      expect(find.text('加载失败'), findsNothing);
    });

    testWidgets('应该正确处理空数据状态', (WidgetTester tester) async {
      // 设置空的mock数据
      mockApiService.setMockBookmarks([]);

      await tester.pumpWidget(
        MaterialApp(
          home: UnreadPage(
            apiService: mockApiService,
          ),
        ),
      );

      // 等待数据加载完成
      await tester.pumpAndSettle();

      // 验证显示空状态
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('暂无未读书签'), findsOneWidget);
      expect(find.text('所有书签都已阅读完毕！'), findsOneWidget);

      // 验证仍然支持下拉刷新
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('标记操作失败时应该显示错误提示', (WidgetTester tester) async {
      // 设置mock数据
      final mockBookmarks = createMockBookmarks(1);
      mockApiService.setMockBookmarks(mockBookmarks);

      await tester.pumpWidget(
        MaterialApp(
          home: UnreadPage(
            apiService: mockApiService,
          ),
        ),
      );

      // 等待数据加载完成
      await tester.pumpAndSettle();

      // 设置标记操作失败
      mockApiService.setShouldThrowError(true);

      // 点击喜爱按钮
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();

      // 验证显示错误提示
      expect(find.textContaining('操作失败'), findsOneWidget);
    });

    testWidgets('归档操作失败时应该显示错误提示', (WidgetTester tester) async {
      // 设置mock数据
      final mockBookmarks = createMockBookmarks(1);
      mockApiService.setMockBookmarks(mockBookmarks);

      await tester.pumpWidget(
        MaterialApp(
          home: UnreadPage(
            apiService: mockApiService,
          ),
        ),
      );

      // 等待数据加载完成
      await tester.pumpAndSettle();

      // 设置归档操作失败
      mockApiService.setShouldThrowError(true);

      // 点击存档按钮
      await tester.tap(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();

      // 验证显示错误提示
      expect(find.textContaining('操作失败'), findsOneWidget);
    });

    testWidgets('不显示AppBar时应该正常工作', (WidgetTester tester) async {
      // 设置mock数据
      final mockBookmarks = createMockBookmarks(3);
      mockApiService.setMockBookmarks(mockBookmarks);

      await tester.pumpWidget(
        MaterialApp(
          home: UnreadPage(
            apiService: mockApiService,
            showAppBar: false,
          ),
        ),
      );

      // 等待数据加载完成
      await tester.pumpAndSettle();

      // 验证不显示AppBar
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('未读'), findsNothing);

      // 验证书签列表正常显示
      expect(find.byType(Card), findsNWidgets(3));
    });
  });
}
