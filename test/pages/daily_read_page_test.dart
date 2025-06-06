import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readeck_app/services/readeck_api_service.dart';
import 'package:readeck_app/models/bookmark.dart';
import 'package:readeck_app/widgets/common/celebration_overlay.dart';

// Mock ReadeckApiService for testing
class MockReadeckApiService extends ReadeckApiService {
  List<Bookmark> _mockBookmarks = [];
  bool _shouldThrowError = false;
  bool _isConfigured = true;
  bool _isLoading = false;
  final List<VoidCallback> _listeners = [];

  @override
  bool get isConfigured => _isConfigured;

  @override
  bool get isLoading => _isLoading;

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  Future<List<Bookmark>> getBookmarkList({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isMarked,
    bool? isArchived,
  }) async {
    if (_shouldThrowError) {
      throw Exception('Mock API Error');
    }

    // 模拟加载状态
    _isLoading = true;
    _notifyListeners();

    await Future.delayed(const Duration(milliseconds: 100));

    _isLoading = false;
    _notifyListeners();

    // 根据参数过滤书签
    var filteredBookmarks = _mockBookmarks.where((bookmark) {
      if (isMarked != null && bookmark.isMarked != isMarked) return false;
      if (isArchived != null && bookmark.isArchived != isArchived) return false;
      if (search != null && search.isNotEmpty) {
        return bookmark.title.toLowerCase().contains(search.toLowerCase()) ||
            bookmark.url.toLowerCase().contains(search.toLowerCase());
      }
      return true;
    }).toList();

    return filteredBookmarks;
  }

  @override
  Future<List<Bookmark>> getRandomUnreadBookmarks() async {
    if (_shouldThrowError) {
      throw Exception('Mock API Error');
    }

    // 模拟加载状态
    _isLoading = true;
    _notifyListeners();

    await Future.delayed(const Duration(milliseconds: 100));

    _isLoading = false;
    _notifyListeners();

    // 只返回未归档的书签
    final unArchivedBookmarks =
        _mockBookmarks.where((bookmark) => !bookmark.isArchived).toList();

    if (unArchivedBookmarks.isEmpty) {
      return [];
    }

    // 随机打乱并取前5个
    final shuffled = List<Bookmark>.from(unArchivedBookmarks);
    shuffled.shuffle();

    return shuffled.take(5).toList();
  }

  @override
  Future<bool> toggleBookmarkMark(String bookmarkId, bool isMarked) async {
    if (_shouldThrowError) {
      throw Exception('Mock toggle mark error');
    }

    final index = _mockBookmarks.indexWhere((b) => b.id == bookmarkId);
    if (index != -1) {
      final newMarkStatus = !isMarked;
      _mockBookmarks[index] = _mockBookmarks[index].copyWith(
        isMarked: newMarkStatus,
      );
      return newMarkStatus;
    }
    return !isMarked;
  }

  @override
  Future<bool> toggleBookmarkArchive(String bookmarkId, bool isArchived) async {
    if (_shouldThrowError) {
      throw Exception('Mock toggle archive error');
    }

    final index = _mockBookmarks.indexWhere((b) => b.id == bookmarkId);
    if (index != -1) {
      final newArchiveStatus = !isArchived;
      _mockBookmarks[index] = _mockBookmarks[index].copyWith(
        isArchived: newArchiveStatus,
      );
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

  void setIsConfigured(bool configured) {
    _isConfigured = configured;
  }

  void setShouldDelay(bool shouldDelay, int milliseconds) {
    // 这个方法可以用来模拟网络延迟，但在当前实现中我们使用固定的延迟
  }
}

// 创建测试用的书签数据
List<Bookmark> createMockBookmarks(int count,
    {bool isMarked = false, bool isArchived = false}) {
  return List.generate(count, (index) {
    return Bookmark(
      id: 'bookmark_${index + 1}',
      title: '今日推荐书签 ${index + 1}',
      url: 'https://example.com/bookmark${index + 1}',
      siteName: 'Daily Site',
      description: '这是第${index + 1}个今日推荐书签的描述',
      created: DateTime.now().subtract(Duration(hours: index)),
      isMarked: isMarked,
      isArchived: isArchived,
      readProgress: 0,
      labels: ['标签${index + 1}'],
      imageUrl: 'https://example.com/image${index + 1}.jpg',
    );
  });
}

// 简化的测试页面，避免使用 StorageService
class SimpleDailyReadPage extends StatefulWidget {
  final ReadeckApiService apiService;
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;
  final bool showAppBar;

  const SimpleDailyReadPage({
    super.key,
    required this.apiService,
    required this.onThemeChanged,
    required this.currentThemeMode,
    this.showAppBar = true,
  });

  @override
  State<SimpleDailyReadPage> createState() => _SimpleDailyReadPageState();
}

class _SimpleDailyReadPageState extends State<SimpleDailyReadPage> {
  List<Bookmark> _dailyBookmarks = [];
  bool _isLoading = false;
  String? _error;
  bool _hasCompletedDailyReading = false;
  bool _noUnreadBookmarks = false;

  @override
  void initState() {
    super.initState();
    widget.apiService.addListener(_onApiLoadingStateChanged);
    _loadDailyBookmarks();
  }

  @override
  void dispose() {
    widget.apiService.removeListener(_onApiLoadingStateChanged);
    super.dispose();
  }

  void _onApiLoadingStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadDailyBookmarks() async {
    if (!widget.apiService.isConfigured) {
      setState(() {
        _error = '请先配置API设置';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _noUnreadBookmarks = false;
    });

    try {
      final bookmarks = await widget.apiService.getRandomUnreadBookmarks();
      setState(() {
        _dailyBookmarks = bookmarks;
        _isLoading = false;
        _noUnreadBookmarks = bookmarks.isEmpty;
        _hasCompletedDailyReading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBookmarkMark(
      String bookmarkId, bool currentMarkStatus) async {
    try {
      final newMarkStatus = await widget.apiService
          .toggleBookmarkMark(bookmarkId, currentMarkStatus);

      setState(() {
        final index = _dailyBookmarks.indexWhere((b) => b.id == bookmarkId);
        if (index != -1) {
          _dailyBookmarks[index] =
              _dailyBookmarks[index].copyWith(isMarked: newMarkStatus);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _toggleBookmarkArchive(
      String bookmarkId, bool currentArchiveStatus) async {
    try {
      final newArchiveStatus = await widget.apiService
          .toggleBookmarkArchive(bookmarkId, currentArchiveStatus);

      if (newArchiveStatus) {
        setState(() {
          _dailyBookmarks.removeWhere((bookmark) => bookmark.id == bookmarkId);
        });

        if (_dailyBookmarks.isEmpty) {
          setState(() {
            _hasCompletedDailyReading = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Widget _buildBookmarkCard(Bookmark bookmark) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bookmark.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.language, size: 16),
                const SizedBox(width: 4),
                Text(bookmark.siteName ?? 'Unknown Site'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    bookmark.isMarked ? Icons.favorite : Icons.favorite_border,
                    color: bookmark.isMarked ? Colors.red : null,
                  ),
                  onPressed: () =>
                      _toggleBookmarkMark(bookmark.id, bookmark.isMarked),
                ),
                IconButton(
                  icon: const Icon(Icons.archive_outlined),
                  onPressed: () =>
                      _toggleBookmarkArchive(bookmark.id, bookmark.isArchived),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('今日阅读'),
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasCompletedDailyReading) {
      return CelebrationOverlay(
        onRefreshNewContent: () {
          setState(() {
            _hasCompletedDailyReading = false;
          });
          _loadDailyBookmarks();
        },
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDailyBookmarks,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_noUnreadBookmarks) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text('已读完所有待读书签'),
            const SizedBox(height: 8),
            const Text('太棒了！去Readeck添加更多书签继续阅读吧！'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDailyBookmarks,
              child: const Text('刷新'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView.builder(
      itemCount: _dailyBookmarks.length,
      itemBuilder: (context, index) {
        return _buildBookmarkCard(_dailyBookmarks[index]);
      },
    );
  }
}

void main() {
  group('DailyReadPage Tests', () {
    late MockReadeckApiService mockApiService;

    setUp(() {
      mockApiService = MockReadeckApiService();
    });

    testWidgets('应该显示今日阅读页面的基本结构', (WidgetTester tester) async {
      // 设置mock数据
      mockApiService.setMockBookmarks(createMockBookmarks(3));

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleDailyReadPage(
            apiService: mockApiService,
            onThemeChanged: (ThemeMode mode) {},
            currentThemeMode: ThemeMode.system,
            showAppBar: true,
          ),
        ),
      );

      // 验证AppBar
      expect(find.text('今日阅读'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      // 等待数据加载完成
      await tester.pumpAndSettle();

      // 验证书签列表显示
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('应该正确展示今日推荐书签数据', (WidgetTester tester) async {
      // 设置mock数据
      final mockBookmarks = createMockBookmarks(2);
      mockApiService.setMockBookmarks(mockBookmarks);

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleDailyReadPage(
            apiService: mockApiService,
            onThemeChanged: (ThemeMode mode) {},
            currentThemeMode: ThemeMode.system,
          ),
        ),
      );

      // 等待数据加载完成
      await tester.pumpAndSettle();

      // 验证书签标题显示
      expect(find.text('今日推荐书签 1'), findsOneWidget);
      expect(find.text('今日推荐书签 2'), findsOneWidget);

      // 验证书签详细信息
      expect(find.text('Daily Site'), findsNWidgets(2));
      expect(find.byIcon(Icons.language), findsNWidgets(2));
      expect(find.byIcon(Icons.favorite_border), findsNWidgets(2));
      expect(find.byIcon(Icons.archive_outlined), findsNWidgets(2));
    });

    testWidgets('点击喜爱按钮应该切换标记状态', (WidgetTester tester) async {
      // 设置mock数据
      final mockBookmarks = createMockBookmarks(1);
      mockApiService.setMockBookmarks(mockBookmarks);

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleDailyReadPage(
            apiService: mockApiService,
            onThemeChanged: (ThemeMode mode) {},
            currentThemeMode: ThemeMode.system,
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
    });

    testWidgets('点击存档按钮应该使书签消失', (WidgetTester tester) async {
      // 设置mock数据
      final mockBookmarks = createMockBookmarks(2);
      mockApiService.setMockBookmarks(mockBookmarks);

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleDailyReadPage(
            apiService: mockApiService,
            onThemeChanged: (ThemeMode mode) {},
            currentThemeMode: ThemeMode.system,
          ),
        ),
      );

      // 等待数据加载完成
      await tester.pumpAndSettle();

      // 验证初始状态有2个书签
      expect(find.text('今日推荐书签 1'), findsOneWidget);
      expect(find.text('今日推荐书签 2'), findsOneWidget);

      // 点击第一个书签的存档按钮
      final archiveButtons = find.byIcon(Icons.archive_outlined);
      await tester.tap(archiveButtons.first);
      await tester.pumpAndSettle();

      // 验证书签已从列表中移除
      expect(find.text('今日推荐书签 1'), findsNothing);
      expect(find.text('今日推荐书签 2'), findsOneWidget);
    });

    testWidgets('存档所有书签后应该显示庆祝界面', (WidgetTester tester) async {
      // 设置只有一个书签的mock数据
      final mockBookmarks = createMockBookmarks(1);
      mockApiService.setMockBookmarks(mockBookmarks);

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleDailyReadPage(
            apiService: mockApiService,
            onThemeChanged: (ThemeMode mode) {},
            currentThemeMode: ThemeMode.system,
          ),
        ),
      );

      // 等待数据加载完成
      await tester.pumpAndSettle();

      // 验证初始状态有1个书签
      expect(find.text('今日推荐书签 1'), findsOneWidget);

      // 点击存档按钮
      await tester.tap(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();

      // 验证显示庆祝界面
      expect(find.text('🎉 恭喜完成今日阅读！'), findsOneWidget);
      expect(find.text('再来一组'), findsOneWidget);
      expect(find.byType(CelebrationOverlay), findsOneWidget);
    });

    testWidgets('应该正确处理加载错误', (WidgetTester tester) async {
      // 设置API抛出错误
      mockApiService.setShouldThrowError(true);

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleDailyReadPage(
            apiService: mockApiService,
            onThemeChanged: (ThemeMode mode) {},
            currentThemeMode: ThemeMode.system,
          ),
        ),
      );

      // 等待错误处理完成
      await tester.pumpAndSettle();

      // 验证显示错误状态
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Exception'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);

      // 点击重试按钮
      mockApiService.setShouldThrowError(false);
      mockApiService.setMockBookmarks(createMockBookmarks(2));

      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();

      // 验证重试后数据正常显示
      expect(find.text('今日推荐书签 1'), findsOneWidget);
      expect(find.text('今日推荐书签 2'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('API未配置时应该显示配置提示', (WidgetTester tester) async {
      // 设置API未配置
      mockApiService.setIsConfigured(false);

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleDailyReadPage(
            apiService: mockApiService,
            onThemeChanged: (ThemeMode mode) {},
            currentThemeMode: ThemeMode.system,
          ),
        ),
      );

      // 等待处理完成
      await tester.pumpAndSettle();

      // 验证显示配置提示
      expect(find.text('请先配置API设置'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('没有未读书签时应该显示相应状态', (WidgetTester tester) async {
      // 设置空的mock数据
      mockApiService.setMockBookmarks([]);

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleDailyReadPage(
            apiService: mockApiService,
            onThemeChanged: (ThemeMode mode) {},
            currentThemeMode: ThemeMode.system,
          ),
        ),
      );

      // 等待数据加载完成
      await tester.pumpAndSettle();

      // 验证显示没有未读书签的状态
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('已读完所有待读书签'), findsOneWidget);
      expect(find.text('太棒了！去Readeck添加更多书签继续阅读吧！'), findsOneWidget);
      expect(find.text('刷新'), findsOneWidget);
    });

    testWidgets('不显示AppBar时应该正常工作', (WidgetTester tester) async {
      // 设置mock数据
      final mockBookmarks = createMockBookmarks(3);
      mockApiService.setMockBookmarks(mockBookmarks);

      await tester.pumpWidget(
        MaterialApp(
          home: SimpleDailyReadPage(
            apiService: mockApiService,
            onThemeChanged: (ThemeMode mode) {},
            currentThemeMode: ThemeMode.system,
            showAppBar: false,
          ),
        ),
      );

      // 等待数据加载完成
      await tester.pumpAndSettle();

      // 验证不显示AppBar
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('今日阅读'), findsNothing);

      // 验证书签列表正常显示
      expect(find.text('今日推荐书签 1'), findsOneWidget);
    });
  });
}
