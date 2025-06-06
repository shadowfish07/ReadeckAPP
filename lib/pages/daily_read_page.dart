import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:confetti/confetti.dart';
import '../services/readeck_api_service.dart';
import '../services/storage_service.dart';
import '../widgets/common/celebration_overlay.dart';
import '../models/bookmark.dart';

class DailyReadPage extends StatefulWidget {
  final ReadeckApiService apiService;
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;
  final bool showAppBar;

  const DailyReadPage({
    super.key,
    required this.apiService,
    required this.onThemeChanged,
    required this.currentThemeMode,
    this.showAppBar = true,
  });

  @override
  State<DailyReadPage> createState() => _DailyReadPageState();
}

class _DailyReadPageState extends State<DailyReadPage> {
  final StorageService _storageService = StorageService.instance;
  List<Bookmark> _dailyBookmarks = [];
  bool _isLoading = false;
  String? _error;
  bool _showCelebration = false;
  bool _hasCompletedDailyReading = false; // 标记是否已完成今日阅读
  bool _noUnreadBookmarks = false; // 标记是否没有未读书签
  late ConfettiController _confettiController;
  static const String _lastRefreshDateKey = 'last_refresh_date';

  @override
  void initState() {
    super.initState();
    // 初始化礼花控制器
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    // 监听 API 服务的加载状态变化
    widget.apiService.addListener(_onApiLoadingStateChanged);
    _checkAndLoadDailyBookmarks();
  }

  @override
  void dispose() {
    // 移除监听器
    widget.apiService.removeListener(_onApiLoadingStateChanged);
    // 释放动画控制器
    _confettiController.dispose();
    super.dispose();
  }

  // API 加载状态变化回调
  void _onApiLoadingStateChanged() {
    if (mounted) {
      setState(() {
        // 触发重建以更新 AppBar 标题
      });
    }
  }

  // 检查是否需要刷新今日书签
  Future<void> _checkAndLoadDailyBookmarks() async {
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final lastRefreshDate = _storageService.getString(_lastRefreshDateKey);

    // 如果今天还没有刷新过，或者是第一次使用，则自动刷新
    if (lastRefreshDate != todayString) {
      await _loadDailyBookmarks();
      await _storageService.saveString(_lastRefreshDateKey, todayString);
    } else {
      // 今天已经刷新过，加载缓存的书签
      await _loadCachedBookmarks();
    }
  }

  // 加载缓存的书签数据
  Future<void> _loadCachedBookmarks() async {
    final cachedBookmarksJson =
        _storageService.getString('cached_daily_bookmarks');

    if (cachedBookmarksJson != null) {
      try {
        final List<dynamic> bookmarksData = json.decode(cachedBookmarksJson);
        final cachedBookmarks =
            bookmarksData.map((json) => Bookmark.fromJson(json)).toList();

        // 过滤掉已归档的书签
        final unArchivedBookmarks =
            cachedBookmarks.where((bookmark) => !bookmark.isArchived).toList();

        setState(() {
          _dailyBookmarks = unArchivedBookmarks;
          _isLoading = false;
          // 如果缓存中所有书签都已归档，标记为已完成今日阅读
          _hasCompletedDailyReading =
              cachedBookmarks.isNotEmpty && unArchivedBookmarks.isEmpty;
          // 重置没有未读书签的状态
          _noUnreadBookmarks = false;
        });

        // 异步更新书签数据
        _updateBookmarksInBackground();
        return;
      } catch (e) {
        // 缓存数据解析失败，重新加载
      }
    }

    // 没有缓存或缓存无效，重新加载
    await _loadDailyBookmarks();
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
        // 如果API返回空列表，说明没有未读书签
        _noUnreadBookmarks = bookmarks.isEmpty;
        // 重置完成状态
        _hasCompletedDailyReading = false;
      });

      // 缓存今日书签数据
      await _cacheDailyBookmarks(bookmarks);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // 缓存今日书签数据
  Future<void> _cacheDailyBookmarks(List<Bookmark> bookmarks) async {
    try {
      final bookmarksJson =
          json.encode(bookmarks.map((b) => b.toJson()).toList());
      await _storageService.saveString('cached_daily_bookmarks', bookmarksJson);
    } catch (e) {
      // 缓存失败不影响主要功能
    }
  }

  // 在后台异步更新书签数据
  Future<void> _updateBookmarksInBackground() async {
    if (!widget.apiService.isConfigured) {
      return;
    }

    // 从持久化存储中读取缓存的书签数据
    final cachedBookmarksJson =
        _storageService.getString('cached_daily_bookmarks');

    if (cachedBookmarksJson == null) {
      return;
    }

    List<Bookmark> cachedBookmarks;
    try {
      final List<dynamic> bookmarksData = json.decode(cachedBookmarksJson);
      cachedBookmarks =
          bookmarksData.map((json) => Bookmark.fromJson(json)).toList();
    } catch (e) {
      debugPrint('解析缓存书签数据失败: $e');
      return;
    }

    if (cachedBookmarks.isEmpty) {
      return;
    }

    // 发请求前，先回显（过滤掉已存档的）
    setState(() {
      _dailyBookmarks =
          cachedBookmarks.where((bookmark) => !bookmark.isArchived).toList();
    });

    try {
      // 提取所有书签ID
      final bookmarkIds = cachedBookmarks.map((b) => b.id).toList();

      // 批量获取最新的书签信息
      final updatedBookmarks =
          await widget.apiService.getBatchBookmarksInfo(bookmarkIds);

      if (updatedBookmarks.isNotEmpty) {
        // 创建一个Map来快速查找更新的书签
        final updatedBookmarksMap = <String, Bookmark>{};
        for (final bookmark in updatedBookmarks) {
          updatedBookmarksMap[bookmark.id] = bookmark;
        }

        // 更新缓存的书签数据
        final mergedBookmarks = <Bookmark>[];
        for (final cachedBookmark in cachedBookmarks) {
          final updatedBookmark = updatedBookmarksMap[cachedBookmark.id];
          if (updatedBookmark != null) {
            mergedBookmarks.add(updatedBookmark);
          } else {
            // 如果没有找到更新的数据，保留缓存的数据
            mergedBookmarks.add(cachedBookmark);
          }
        }
        // 异步更新U
        // 更新UI（过滤掉已存档的）
        setState(() {
          _dailyBookmarks = mergedBookmarks
              .where((bookmark) => !bookmark.isArchived)
              .toList();
        });

        // 更新缓存
        await _cacheDailyBookmarks(mergedBookmarks);
      }
    } catch (e) {
      // 后台更新失败不影响用户体验，静默处理
      // 可以选择记录日志或显示轻微的提示
      debugPrint('后台更新书签失败: $e');
    }
  }

  Future<void> _openUrl(String url) async {
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
        launched = false;
      }

      // 如果外部应用启动失败，尝试使用平台默认方式
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (e) {
          launched = false;
        }
      }

      // 如果仍然失败，尝试使用内置WebView
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
        } catch (e) {
          launched = false;
        }
      }

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '无法打开链接: $url\n\n可能原因：\n• 设备上没有安装合适的浏览器应用\n• 链接格式不正确\n• 网络连接问题'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '复制链接',
              textColor: Colors.white,
              onPressed: () {
                // 这里可以添加复制到剪贴板的功能
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开链接时发生错误: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _toggleBookmarkMark(
      String bookmarkId, bool currentMarkStatus) async {
    try {
      final newMarkStatus = await widget.apiService
          .toggleBookmarkMark(bookmarkId, currentMarkStatus);

      // 更新本地书签列表中的标记状态
      setState(() {
        final index =
            _dailyBookmarks.indexWhere((bookmark) => bookmark.id == bookmarkId);
        if (index != -1) {
          _dailyBookmarks[index] = _dailyBookmarks[index].copyWith(
            isMarked: newMarkStatus,
          );
        }
      });

      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newMarkStatus ? '已标记为喜爱' : '已取消喜爱标记'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _toggleBookmarkArchive(
      String bookmarkId, bool currentArchiveStatus) async {
    try {
      final newArchiveStatus = await widget.apiService
          .toggleBookmarkArchive(bookmarkId, currentArchiveStatus);
      _updateBookmarksInBackground();

      // 如果书签被存档，从当前列表中移除
      if (newArchiveStatus) {
        setState(() {
          _dailyBookmarks.removeWhere((bookmark) => bookmark.id == bookmarkId);
        });

        // 检查是否所有书签都已归档（完成今日阅读）
        if (_dailyBookmarks.isEmpty) {
          setState(() {
            _hasCompletedDailyReading = true;
          });
          _showCelebrationScreen();
        } else {
          // 显示成功提示
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('已存档'),
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: '撤销',
                  onPressed: () {
                    // 撤销存档操作
                    _toggleBookmarkArchive(bookmarkId, true);
                  },
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已取消存档'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 显示庆祝界面
  void _showCelebrationScreen() {
    setState(() {
      _showCelebration = true;
    });
    _confettiController.play();
  }

  // 刷新一组新内容
  Future<void> _refreshNewContent() async {
    setState(() {
      _showCelebration = false;
      _hasCompletedDailyReading = false;
    });
    _confettiController.stop();
    await _loadDailyBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Row(
                children: [
                  const Text('今日阅读'),
                  // 只有在body内没有loading时，才在标题区显示loading
                  if (widget.apiService.isLoading && !_isLoading) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '加载中',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            )
          : null,
      body: Stack(
        children: [
          _buildBody(),
          if (_showCelebration) _buildCelebrationOverlay(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载今日推荐...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDailyBookmarks,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (_dailyBookmarks.isEmpty && !_showCelebration) {
      // 区分两种情况：完成今日阅读 vs 没有未读书签
      if (_hasCompletedDailyReading) {
        // 已完成今日阅读，显示庆祝界面
        return CelebrationOverlay(
          onRefreshNewContent: _refreshNewContent,
        );
      } else if (_noUnreadBookmarks) {
        // API返回没有未读书签
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  '已读完所有待读书签',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '太棒了！去Readeck添加更多书签继续阅读吧！',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadDailyBookmarks,
                  icon: const Icon(Icons.refresh),
                  label: const Text('刷新'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // 默认情况（初始状态或其他）
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  '暂无未读书签',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '去Readeck添加一些书签吧！',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _dailyBookmarks.length,
      itemBuilder: (context, index) {
        return BookmarkCard(
          bookmark: _dailyBookmarks[index],
          onTap: () => _openUrl(_dailyBookmarks[index].url),
          onToggleMark: (bookmarkId, currentMarkStatus) =>
              _toggleBookmarkMark(bookmarkId, currentMarkStatus),
          onToggleArchive: (bookmarkId, currentArchiveStatus) =>
              _toggleBookmarkArchive(bookmarkId, currentArchiveStatus),
        );
      },
    );
  }

  // 构建庆祝界面覆盖层
  Widget _buildCelebrationOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Stack(
        children: [
          // 礼花动画 - 从左下角发射
          Align(
            alignment: Alignment.bottomLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 4, // 向右上方发射
              maxBlastForce: 40,
              minBlastForce: 5,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.purple,
                Colors.orange,
                Colors.pink,
                Colors.cyan,
              ],
            ),
          ),
          CelebrationOverlay(
            onRefreshNewContent: _refreshNewContent,
          )
        ],
      ),
    );
  }
}

class BookmarkCard extends StatelessWidget {
  final Bookmark bookmark;
  final VoidCallback onTap;
  final Function(String bookmarkId, bool currentMarkStatus)? onToggleMark;
  final Function(String bookmarkId, bool currentArchiveStatus)? onToggleArchive;

  const BookmarkCard({
    super.key,
    required this.bookmark,
    required this.onTap,
    this.onToggleMark,
    this.onToggleArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                bookmark.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // 站点名称和创建时间
              Row(
                children: [
                  if (bookmark.siteName != null) ...[
                    Icon(
                      Icons.language,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        bookmark.siteName!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatDate(bookmark.created),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              // 描述
              if (bookmark.description != null &&
                  bookmark.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  bookmark.description!,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // 标签
              if (bookmark.labels.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: bookmark.labels.take(3).map((label) {
                    return Chip(
                      label: Text(
                        label,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],

              // 底部操作栏
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  // 标记喜爱按钮
                  IconButton(
                    onPressed: onToggleMark != null
                        ? () => onToggleMark!(bookmark.id, bookmark.isMarked)
                        : null,
                    icon: Icon(
                      bookmark.isMarked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 20,
                      color: bookmark.isMarked ? Colors.red : Colors.grey[600],
                    ),
                    tooltip: '标记喜爱',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 存档按钮
                  IconButton(
                    onPressed: onToggleArchive != null
                        ? () =>
                            onToggleArchive!(bookmark.id, bookmark.isArchived)
                        : null,
                    icon: Icon(
                      Icons.archive_outlined,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    tooltip: '存档',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}
