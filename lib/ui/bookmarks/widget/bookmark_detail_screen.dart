import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_all/flutter_html_all.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

import 'package:readeck_app/ui/bookmarks/view_models/bookmark_detail_viewmodel.dart';
import 'package:readeck_app/ui/core/ui/bookmark_labels_widget.dart';
import 'package:readeck_app/ui/core/ui/error_page.dart';
import 'package:readeck_app/ui/core/ui/label_edit_dialog.dart';
import 'package:readeck_app/ui/core/ui/loading.dart';
import 'package:readeck_app/utils/network_error_exception.dart';
import 'package:readeck_app/utils/resource_not_found_exception.dart';

class BookmarkDetailScreen extends StatefulWidget {
  const BookmarkDetailScreen({super.key, required this.viewModel});

  final BookmarkDetailViewModel viewModel;

  @override
  State<BookmarkDetailScreen> createState() => _BookmarkDetailScreenState();
}

class _BookmarkDetailScreenState extends State<BookmarkDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isAutoScrolling = false; // 标记是否正在自动滚动
  bool _isAutoScrolled = false;
  final GlobalKey _archiveCardKey = GlobalKey(); // 用于获取存档卡片高度

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.viewModel.bookmark.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case 'open_browser':
                  widget.viewModel.openUrl(widget.viewModel.bookmark.url);
                  break;
                case 'toggle_mark':
                  _toggleBookmarkMarked();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(widget.viewModel.bookmark.isMarked
                            ? '已取消喜爱'
                            : '已标记喜爱')),
                  );
                  break;
                case 'edit_labels':
                  _showLabelEditDialog();
                  break;
                case 'archive':
                  if (!widget.viewModel.bookmark.isArchived) {
                    _archiveBookmark();
                  }
                  break;
                case 'delete':
                  _showDeleteConfirmDialog();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'open_browser',
                child: ListTile(
                  leading: Icon(Icons.open_in_browser),
                  title: Text('在浏览器中打开'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'toggle_mark',
                child: ListTile(
                  leading: Icon(
                    widget.viewModel.bookmark.isMarked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: widget.viewModel.bookmark.isMarked
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                  title: Text(
                    widget.viewModel.bookmark.isMarked ? '取消喜爱' : '标记喜爱',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'edit_labels',
                child: ListTile(
                  leading: Icon(Icons.local_offer_outlined),
                  title: Text('编辑标签'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (!widget.viewModel.bookmark.isArchived)
                const PopupMenuItem<String>(
                  value: 'archive',
                  child: ListTile(
                    leading: Icon(Icons.archive),
                    title: Text('完成阅读'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    '删除书签',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<BookmarkDetailViewModel>(
        builder: (context, viewModel, child) {
          return CommandBuilder<void, String>(
            command: viewModel.loadArticleContent,
            whileExecuting: (context, lastValue, _) {
              if (lastValue == null || lastValue.isEmpty) {
                return const Loading(text: '正在加载内容...');
              }
              return _buildContent(context, lastValue, isLoading: true);
            },
            onData: (context, data, _) {
              // 内容加载完成后，延迟滚动到指定位置
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToProgress();
              });
              return _buildContent(context, data);
            },
            onError: (context, error, _, __) {
              switch (error) {
                case ResourceNotFoundException _:
                  return ErrorPage.bookmarkNotFound();
                case NetworkErrorException _:
                  return ErrorPage.networkError(
                    error: error,
                    onBack: () => viewModel.retry(),
                  );
                default:
                  return ErrorPage.unknownError(error: Exception(error));
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, String htmlContent,
      {bool isLoading = false}) {
    if (htmlContent.isEmpty) {
      return const Center(
        child: Text(
          '暂无内容',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HTML内容
              Html(
                data: htmlContent,
                style: {
                  "body": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(16),
                    lineHeight: const LineHeight(1.6),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  "p": Style(
                    margin: Margins.only(bottom: 16),
                  ),
                  "h1, h2, h3, h4, h5, h6": Style(
                    margin: Margins.only(top: 24, bottom: 16),
                    fontWeight: FontWeight.bold,
                  ),
                  "img": Style(
                    width: Width(
                      MediaQuery.of(context).size.width,
                      Unit.auto,
                    ),
                    margin: Margins.symmetric(vertical: 16),
                  ),
                  "blockquote": Style(
                    margin: Margins.symmetric(vertical: 16),
                    padding: HtmlPaddings.only(left: 16),
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 4,
                      ),
                    ),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  "code": Style(
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
                    fontFamily: 'monospace',
                  ),
                  "pre": Style(
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    padding: HtmlPaddings.all(16),
                    margin: Margins.symmetric(vertical: 16),
                    whiteSpace: WhiteSpace.pre,
                  ),
                },
                onLinkTap: (url, attributes, element) async {
                  widget.viewModel.openUrl(widget.viewModel.bookmark.url);
                },
                extensions: [
                  const AudioHtmlExtension(),
                  const IframeHtmlExtension(),
                  const MathHtmlExtension(),
                  const SvgHtmlExtension(),
                  const TableHtmlExtension(),
                  const VideoHtmlExtension(),
                  TagExtension(
                    tagsToExtend: {"img"},
                    builder: (extensionContext) {
                      final src = extensionContext
                          .styledElement?.element?.attributes['src'];
                      if (src != null) {
                        return Builder(
                          builder: (context) {
                            return GestureDetector(
                              onTap: () => _showImagePreview(context, src),
                              child: Image.network(
                                src,
                                width: MediaQuery.of(context).size.width,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.broken_image,
                                      size: 64);
                                },
                              ),
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),

              // 存档提示区域
              if (!widget.viewModel.bookmark.isArchived)
                Container(
                  key: _archiveCardKey,
                  margin: const EdgeInsets.only(top: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '读完了！',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '标记已读，专注下一篇精彩内容。',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      // 标签展示
                      if (widget.viewModel.bookmark.labels.isNotEmpty) ...[
                        BookmarkLabelsWidget(
                          labels: widget.viewModel.bookmark.labels,
                          isOnDarkBackground: true,
                        ),
                        const SizedBox(height: 16),
                      ],
                      // 操作按钮区域
                      Row(
                        children: [
                          // 标记喜爱按钮
                          IconButton(
                            onPressed: () => _toggleBookmarkMarked(),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(40, 40),
                              maximumSize: const Size(40, 40),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: Icon(
                              widget.viewModel.bookmark.isMarked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 20,
                              color: widget.viewModel.bookmark.isMarked
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                            tooltip: '标记喜爱',
                          ),
                          const SizedBox(width: 8),
                          // 标签编辑按钮
                          IconButton(
                            onPressed: () => _showLabelEditDialog(),
                            icon: Icon(
                              Icons.local_offer_outlined,
                              size: 20,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(40, 40),
                              maximumSize: const Size(40, 40),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            tooltip: '编辑标签',
                          ),
                          const SizedBox(width: 8),
                          // 删除按钮
                          IconButton(
                            onPressed: () => _showDeleteConfirmDialog(),
                            icon: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(40, 40),
                              maximumSize: const Size(40, 40),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            tooltip: '删除书签',
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: () => _archiveBookmark(),
                            icon: const Icon(Icons.archive, size: 18),
                            label: const Text('完成阅读'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // 底部间距
              const SizedBox(height: 32),
            ],
          ),
        ),

        // 加载指示器
        if (isLoading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  void _onScroll() {
    // 如果正在自动滚动，不触发进度更新
    if (!_isAutoScrolling) {
      _updateReadProgress();
    }
  }

  void _updateReadProgress() {
    if (!_scrollController.hasClients) return;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final currentOffset = _scrollController.offset;

    // 获取存档卡片高度（如果存在且未存档）
    double archiveCardHeight = 0;
    if (!widget.viewModel.bookmark.isArchived &&
        _archiveCardKey.currentContext != null) {
      final RenderBox? renderBox =
          _archiveCardKey.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        archiveCardHeight = renderBox.size.height;
      }
    }

    // 计算有效的可滚动高度（排除存档卡片）
    final effectiveMaxScrollExtent = maxScrollExtent - archiveCardHeight;

    // 计算阅读进度百分比（0-100）
    int readProgress = 0;
    if (effectiveMaxScrollExtent > 0) {
      readProgress = ((currentOffset / effectiveMaxScrollExtent) * 100)
          .round()
          .clamp(0, 100);
    }

    // 使用Command更新阅读进度到服务器（带防抖功能）
    widget.viewModel.updateReadProgressCommand.execute(readProgress);
  }

  void _scrollToProgress() {
    if (!_scrollController.hasClients || _isAutoScrolled) return;

    final readProgress = widget.viewModel.bookmark.readProgress;
    if (readProgress <= 0) return;

    // 获取可滚动的最大距离
    final maxScrollExtent = _scrollController.position.maxScrollExtent;

    // 获取存档卡片高度（如果存在且未存档）
    double archiveCardHeight = 0;
    if (!widget.viewModel.bookmark.isArchived &&
        _archiveCardKey.currentContext != null) {
      final RenderBox? renderBox =
          _archiveCardKey.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        archiveCardHeight = renderBox.size.height;
      }
    }

    // 计算有效的可滚动高度（排除存档卡片）
    final effectiveMaxScrollExtent = maxScrollExtent - archiveCardHeight;

    // 根据阅读进度计算滚动位置（0-100转换为0-effectiveMaxScrollExtent）
    final targetOffset = readProgress == 100.0
        ? maxScrollExtent
        : (readProgress / 100.0) * effectiveMaxScrollExtent;

    // 设置自动滚动标志
    _isAutoScrolling = true;

    // 直接跳转到目标位置
    _scrollController.jumpTo(targetOffset);

    // 立即重置标志
    _isAutoScrolling = false;
    _isAutoScrolled = true;
  }

  void _archiveBookmark() async {
    try {
      // 调用ViewModel中的存档方法
      await widget.viewModel.archiveBookmarkCommand.executeWithFuture();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('已成功归档'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('归档失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleBookmarkMarked() async {
    try {
      await widget.viewModel.toggleMarkCommand.executeWithFuture();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  void _showLabelEditDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return LabelEditDialog(
          bookmark: widget.viewModel.bookmark,
          availableLabels: widget.viewModel.availableLabels,
          onUpdateLabels: (bookmark, labels) async {
            try {
              await widget.viewModel.updateBookmarkLabels(labels);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('标签已更新')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('更新标签失败: $e')),
                );
              }
            }
          },
          onLoadLabels: () => widget.viewModel.loadLabels.executeWithFuture(),
        );
      },
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这个书签吗？此操作无法撤销。'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('删除'),
              onPressed: () async {
                Navigator.of(context).pop();
                _deleteBookmark();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteBookmark() async {
    try {
      await widget.viewModel.deleteBookmarkCommand.executeWithFuture();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('书签已删除')),
        );
        Navigator.of(context).pop(); // 删除成功后返回上一页
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoView(
            imageProvider: NetworkImage(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.0,
            initialScale: PhotoViewComputedScale.contained,
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(
                Icons.error,
                color: Colors.white,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
