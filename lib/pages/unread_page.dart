import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/readeck_api_service.dart';
import '../models/bookmark.dart';
import 'daily_read_page.dart';

class UnreadPage extends StatefulWidget {
  final ReadeckApiService apiService;
  final bool showAppBar;

  const UnreadPage({
    super.key,
    required this.apiService,
    this.showAppBar = true,
  });

  @override
  State<UnreadPage> createState() => _UnreadPageState();
}

class _UnreadPageState extends State<UnreadPage> {
  List<Bookmark> _unreadBookmarks = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  // 分页参数
  static const int _pageSize = 20;
  int _currentOffset = 0;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUnreadBookmarks();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 监听滚动事件，实现滚动加载
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreBookmarks();
    }
  }

  // 加载未读书签
  Future<void> _loadUnreadBookmarks({bool isRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      if (isRefresh) {
        _currentOffset = 0;
        _hasMoreData = true;
      }
    });

    try {
      final bookmarks = await widget.apiService.getBookmarks(
        readStatus: 'unread',
        limit: _pageSize,
        offset: _currentOffset,
        sort: 'created_desc',
      );

      setState(() {
        if (isRefresh) {
          _unreadBookmarks = bookmarks;
        } else {
          _unreadBookmarks.addAll(bookmarks);
        }
        _currentOffset += bookmarks.length;
        _hasMoreData = bookmarks.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // 加载更多书签
  Future<void> _loadMoreBookmarks() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final bookmarks = await widget.apiService.getBookmarks(
        readStatus: 'unread',
        limit: _pageSize,
        offset: _currentOffset,
        sort: 'created_desc',
      );

      setState(() {
        _unreadBookmarks.addAll(bookmarks);
        _currentOffset += bookmarks.length;
        _hasMoreData = bookmarks.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载更多失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 下拉刷新
  Future<void> _onRefresh() async {
    await _loadUnreadBookmarks(isRefresh: true);
  }

  // 打开URL
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
          ),
        );
      }
    }
  }

  // 切换书签标记状态
  Future<void> _toggleBookmarkMark(
      String bookmarkId, bool currentMarkStatus) async {
    try {
      await widget.apiService
          .toggleBookmarkMark(bookmarkId, !currentMarkStatus);

      // 更新本地状态
      setState(() {
        final index = _unreadBookmarks.indexWhere((b) => b.id == bookmarkId);
        if (index != -1) {
          _unreadBookmarks[index] = _unreadBookmarks[index].copyWith(
            isMarked: !currentMarkStatus,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentMarkStatus ? '已添加到收藏' : '已取消收藏'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 切换书签归档状态
  Future<void> _toggleBookmarkArchive(
      String bookmarkId, bool currentArchiveStatus) async {
    try {
      await widget.apiService
          .toggleBookmarkArchive(bookmarkId, !currentArchiveStatus);

      // 如果归档了，从列表中移除
      if (!currentArchiveStatus) {
        setState(() {
          _unreadBookmarks.removeWhere((b) => b.id == bookmarkId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已归档'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // 更新本地状态
        setState(() {
          final index = _unreadBookmarks.indexWhere((b) => b.id == bookmarkId);
          if (index != -1) {
            _unreadBookmarks[index] = _unreadBookmarks[index].copyWith(
              isArchived: !currentArchiveStatus,
            );
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已取消归档'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text(
                '未读',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              centerTitle: false,
              elevation: 4,
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _unreadBookmarks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _unreadBookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadUnreadBookmarks(isRefresh: true),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_unreadBookmarks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '暂无未读书签',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '所有书签都已阅读完毕！',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _unreadBookmarks.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _unreadBookmarks.length) {
            // 加载更多指示器
            return Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: _isLoadingMore
                  ? const CircularProgressIndicator()
                  : const SizedBox.shrink(),
            );
          }

          return BookmarkCard(
            bookmark: _unreadBookmarks[index],
            onTap: () => _openUrl(_unreadBookmarks[index].url),
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
