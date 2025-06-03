import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/readeck_api_service.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final ReadeckApiService apiService;

  const HomePage({super.key, required this.apiService});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Bookmark> _dailyBookmarks = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDailyBookmarks();
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
    });

    try {
      final bookmarks = await widget.apiService.getRandomUnreadBookmarks();
      setState(() {
        _dailyBookmarks = bookmarks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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

  Future<void> _navigateToSettings() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => SettingsPage(apiService: widget.apiService),
      ),
    );

    // 如果设置页面返回true，说明配置已更新，重新加载数据
    if (result == true) {
      _loadDailyBookmarks();
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
          _dailyBookmarks[index] = Bookmark(
            id: _dailyBookmarks[index].id,
            title: _dailyBookmarks[index].title,
            url: _dailyBookmarks[index].url,
            siteName: _dailyBookmarks[index].siteName,
            description: _dailyBookmarks[index].description,
            created: _dailyBookmarks[index].created,
            isMarked: newMarkStatus,
            isArchived: _dailyBookmarks[index].isArchived,
            readProgress: _dailyBookmarks[index].readProgress,
            labels: _dailyBookmarks[index].labels,
            imageUrl: _dailyBookmarks[index].imageUrl,
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

      // 如果书签被存档，从当前列表中移除
      if (newArchiveStatus) {
        setState(() {
          _dailyBookmarks.removeWhere((bookmark) => bookmark.id == bookmarkId);
        });

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
      } else {
        // 如果取消存档，重新加载书签列表
        _loadDailyBookmarks();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日阅读'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDailyBookmarks,
            tooltip: '刷新',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: '设置',
          ),
        ],
      ),
      body: _buildBody(),
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
                onPressed: widget.apiService.isConfigured
                    ? _loadDailyBookmarks
                    : _navigateToSettings,
                child: Text(widget.apiService.isConfigured ? '重试' : '前往设置'),
              ),
            ],
          ),
        ),
      );
    }

    if (_dailyBookmarks.isEmpty) {
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

    return RefreshIndicator(
      onRefresh: _loadDailyBookmarks,
      child: ListView.builder(
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
