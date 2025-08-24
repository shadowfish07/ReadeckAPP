import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/domain/models/bookmark_display_model/bookmark_display_model.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/ui/core/ui/bookmark_labels_widget.dart';
import 'package:readeck_app/ui/core/ui/label_edit_dialog.dart';
import 'package:readeck_app/ui/core/ui/snack_bar_helper.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';

class BookmarkCard extends StatefulWidget {
  final BookmarkDisplayModel bookmarkDisplayModel;
  final Command onOpenUrl;
  final Function(BookmarkDisplayModel bookmark)? onCardTap;
  final Function(BookmarkDisplayModel bookmark)? onToggleMark;
  final Function(BookmarkDisplayModel bookmark)? onToggleArchive;
  final Function(BookmarkDisplayModel bookmark, List<String> labels)?
      onUpdateLabels;
  final List<String>? availableLabels;
  final Future<List<String>> Function()? onLoadLabels;
  final Command<BookmarkDisplayModel, void>? deleteBookmark;

  const BookmarkCard({
    super.key,
    required this.bookmarkDisplayModel,
    required this.onOpenUrl,
    this.onCardTap,
    this.onToggleMark,
    this.onToggleArchive,
    this.onUpdateLabels,
    this.availableLabels,
    this.onLoadLabels,
    this.deleteBookmark,
  });

  @override
  State<BookmarkCard> createState() => _BookmarkCardState();
}

class _BookmarkCardState extends State<BookmarkCard> {
  ListenableSubscription? _openUrlErrorsSub;
  ListenableSubscription? _deleteBookmarkErrorsSub;

  @override
  void initState() {
    super.initState();
    // 订阅 URL 打开错误
    _openUrlErrorsSub =
        widget.onOpenUrl.errors.where((e) => e != null).listen((error, _) {
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        error.toString(),
        action: SnackBarAction(
          label: '复制链接',
          onPressed: () async {
            await Clipboard.setData(
                ClipboardData(text: widget.bookmarkDisplayModel.bookmark.url));
            if (mounted) {
              SnackBarHelper.showSuccess(context, '链接已复制到剪贴板');
            }
          },
        ),
      );
    });

    // 订阅删除命令的错误
    if (widget.deleteBookmark != null) {
      _deleteBookmarkErrorsSub = widget.deleteBookmark!.errors
          .where((e) => e != null)
          .listen((error, _) {
        if (!mounted) return;
        SnackBarHelper.showError(
          context,
          '删除失败，请稍后重试',
        );
      });
    }
  }

  @override
  void dispose() {
    _openUrlErrorsSub?.cancel();
    _deleteBookmarkErrorsSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext rootContext) {
    final isArchived = widget.bookmarkDisplayModel.bookmark.isArchived;

    return GestureDetector(
      onLongPressStart: widget.deleteBookmark != null
          ? (details) => _handleLongPress(rootContext, details.globalPosition)
          : null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        color: isArchived
            ? Theme.of(rootContext).colorScheme.surfaceContainerLow
            : null,
        child: InkWell(
          onTap: _handleCardTap,
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: isArchived ? 0.7 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.bookmarkDisplayModel.bookmark.title,
                          style: Theme.of(rootContext)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: widget.bookmarkDisplayModel.bookmark
                                        .isArchived
                                    ? Theme.of(rootContext)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7)
                                    : null,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 站点名称和创建时间
                  Row(
                    children: [
                      if (widget.bookmarkDisplayModel.bookmark.siteName !=
                          null) ...[
                        Icon(
                          Icons.language,
                          size: 16,
                          color: Theme.of(rootContext).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              final url =
                                  widget.bookmarkDisplayModel.bookmark.url;
                              widget.onOpenUrl(url);
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Text(
                              widget.bookmarkDisplayModel.bookmark.siteName!,
                              style: Theme.of(rootContext)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(rootContext)
                                        .colorScheme
                                        .primary,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        _formatDate(
                            widget.bookmarkDisplayModel.bookmark.created),
                        style: Theme.of(rootContext)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(rootContext).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),

                  // 描述
                  if (widget.bookmarkDisplayModel.bookmark.description !=
                          null &&
                      widget.bookmarkDisplayModel.bookmark.description!
                          .isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.bookmarkDisplayModel.bookmark.description!,
                      style: Theme.of(rootContext)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: Theme.of(rootContext).colorScheme.outline,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // 标签
                  if (widget
                      .bookmarkDisplayModel.bookmark.labels.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    BookmarkLabelsWidget(
                      labels: widget.bookmarkDisplayModel.bookmark.labels,
                      isOnDarkBackground: false,
                    ),
                  ],

                  // 底部操作栏
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 阅读统计信息
                      _buildReadingStatsRow(
                          rootContext, widget.bookmarkDisplayModel.stats),
                      // 阅读进度指示器
                      if (widget.bookmarkDisplayModel.bookmark.readProgress >
                          0) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                value: widget.bookmarkDisplayModel.bookmark
                                        .readProgress /
                                    100.0,
                                strokeWidth: 2,
                                color:
                                    Theme.of(rootContext).colorScheme.primary,
                                backgroundColor: Theme.of(rootContext)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.bookmarkDisplayModel.bookmark.readProgress}%',
                              style: Theme.of(rootContext)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(rootContext)
                                        .colorScheme
                                        .outline,
                                  ),
                            ),
                          ],
                        ),
                      ],
                      const Spacer(),
                      // 标记喜爱按钮
                      IconButton(
                        onPressed: widget.onToggleMark != null
                            ? () => widget
                                .onToggleMark!(widget.bookmarkDisplayModel)
                            : null,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          maximumSize: const Size(32, 32),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          widget.bookmarkDisplayModel.bookmark.isMarked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 20,
                          color: widget.bookmarkDisplayModel.bookmark.isMarked
                              ? Theme.of(rootContext).colorScheme.error
                              : Theme.of(rootContext)
                                  .colorScheme
                                  .onSurfaceVariant,
                        ),
                        tooltip: '标记喜爱',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 标签编辑按钮
                      IconButton(
                        onPressed: widget.onUpdateLabels != null
                            ? () => _showLabelEditDialog(rootContext)
                            : null,
                        icon: Icon(
                          Icons.local_offer_outlined,
                          size: 20,
                          color: Theme.of(rootContext)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          maximumSize: const Size(32, 32),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        tooltip: '编辑标签',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 存档按钮
                      IconButton(
                        onPressed: widget.onToggleArchive != null
                            ? () {
                                widget.onToggleArchive!(
                                    widget.bookmarkDisplayModel);
                                SnackBarHelper.showSuccess(
                                  context,
                                  widget.bookmarkDisplayModel.bookmark
                                          .isArchived
                                      ? '已取消归档'
                                      : '已标记归档',
                                  duration: const Duration(seconds: 2),
                                );
                              }
                            : null,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          maximumSize: const Size(32, 32),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          widget.bookmarkDisplayModel.bookmark.isArchived
                              ? Icons.unarchive
                              : Icons.archive_outlined,
                          size: 20,
                          color: widget.bookmarkDisplayModel.bookmark.isArchived
                              ? Theme.of(rootContext)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.7)
                              : Theme.of(rootContext)
                                  .colorScheme
                                  .onSurfaceVariant,
                        ),
                        tooltip: widget.bookmarkDisplayModel.bookmark.isArchived
                            ? '取消归档'
                            : '归档',
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
        ),
      ),
    );
  }

  /// 处理卡片点击事件
  void _handleCardTap() {
    appLogger.i('处理书签卡片点击: ${widget.bookmarkDisplayModel.bookmark.title}');
    widget.onCardTap?.call(widget.bookmarkDisplayModel);
  }

  /// 处理卡片长按事件，显示上下文菜单
  void _handleLongPress(BuildContext context, Offset globalPosition) async {
    appLogger.i('处理书签卡片长按: ${widget.bookmarkDisplayModel.bookmark.id}');

    if (!mounted) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromLTRB(
      globalPosition.dx,
      globalPosition.dy,
      overlay.size.width - globalPosition.dx,
      overlay.size.height - globalPosition.dy,
    );

    final selectedValue = await showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                '删除书签',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );

    if (selectedValue == 'delete' && mounted && context.mounted) {
      _showDeleteConfirmationDialog(context);
    }
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个书签吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _handleDeleteConfirmed(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// 处理确认删除操作
  void _handleDeleteConfirmed(BuildContext context) {
    // 执行删除命令，成功和失败的处理都在 ViewModel 层
    widget.deleteBookmark?.execute(widget.bookmarkDisplayModel);
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

  void _showLabelEditDialog(BuildContext context) async {
    List<String> labels = widget.availableLabels ?? [];

    // 先展示对话框（如果有缓存数据）
    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => LabelEditDialog.fromBookmark(
          bookmark: widget.bookmarkDisplayModel.bookmark,
          availableLabels: labels,
          onUpdateLabels: (bookmark, labels) async {
            try {
              if (widget.onUpdateLabels != null) {
                widget.onUpdateLabels!(widget.bookmarkDisplayModel, labels);
                if (context.mounted) {
                  SnackBarHelper.showSuccess(context, '标签已更新');
                }
              }
            } catch (e) {
              if (context.mounted) {
                SnackBarHelper.showError(context, '更新标签失败: $e');
              }
            }
          },
          onLoadLabels: widget.onLoadLabels,
        ),
      );
    }
  }

  /// 构建阅读统计信息行
  Widget _buildReadingStatsRow(
      BuildContext context, ReadingStatsForView? stats) {
    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule_outlined,
          size: 14,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 2),
        Text(
          '${stats.estimatedReadingTimeMinutes.round()}分钟',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.text_fields_outlined,
          size: 14,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 2),
        Text(
          '${stats.readableCharCount}字',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
