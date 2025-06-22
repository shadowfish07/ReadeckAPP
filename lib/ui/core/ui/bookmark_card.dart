import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/ui/core/ui/bookmark_labels_widget.dart';
import 'package:readeck_app/ui/core/ui/label_edit_dialog.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';

class BookmarkCard extends StatefulWidget {
  final Bookmark bookmark;
  final Command onOpenUrl;
  final Function(Bookmark bookmark)? onCardTap;
  final Function(Bookmark bookmark)? onToggleMark;
  final Function(Bookmark bookmark)? onToggleArchive;
  final Function(Bookmark bookmark, List<String> labels)? onUpdateLabels;
  final List<String>? availableLabels;
  final Future<List<String>> Function()? onLoadLabels;
  final ReadingStats? readingStats;

  const BookmarkCard({
    super.key,
    required this.bookmark,
    required this.onOpenUrl,
    this.onCardTap,
    this.onToggleMark,
    this.onToggleArchive,
    this.onUpdateLabels,
    this.availableLabels,
    this.onLoadLabels,
    this.readingStats,
  });

  @override
  State<BookmarkCard> createState() => _BookmarkCardState();
}

class _BookmarkCardState extends State<BookmarkCard> {
  @override
  didChangeDependencies() {
    widget.onOpenUrl.errors.where((x) => x != null).listen((error, _) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '复制链接',
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: widget.bookmark.url));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('链接已复制到剪贴板'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
      );
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext rootContext) {
    final isArchived = widget.bookmark.isArchived;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: isArchived
          ? Theme.of(rootContext).colorScheme.surfaceContainerLow
          : null,
      child: InkWell(
        onTap: () {
          widget.onCardTap?.call(widget.bookmark);
        },
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
                        widget.bookmark.title,
                        style: Theme.of(rootContext)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: widget.bookmark.isArchived
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
                    if (widget.bookmark.siteName != null) ...[
                      Icon(
                        Icons.language,
                        size: 16,
                        color: Theme.of(rootContext).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            final url = widget.bookmark.url;
                            widget.onOpenUrl(url);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Text(
                            widget.bookmark.siteName!,
                            style: Theme.of(rootContext)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(rootContext).colorScheme.primary,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatDate(widget.bookmark.created),
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
                if (widget.bookmark.description != null &&
                    widget.bookmark.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.bookmark.description!,
                    style: Theme.of(rootContext).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(rootContext).colorScheme.outline,
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // 标签
                if (widget.bookmark.labels.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  BookmarkLabelsWidget(
                    labels: widget.bookmark.labels,
                    isOnDarkBackground: false,
                  ),
                ],

                // 底部操作栏
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 阅读统计信息
                    if (widget.readingStats != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 14,
                            color: Theme.of(rootContext).colorScheme.outline,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${widget.readingStats!.estimatedReadingTimeMinutes.round()}分钟',
                            style: Theme.of(rootContext)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(rootContext).colorScheme.outline,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.text_fields_outlined,
                            size: 14,
                            color: Theme.of(rootContext).colorScheme.outline,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${widget.readingStats!.readableCharCount}字',
                            style: Theme.of(rootContext)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(rootContext).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                    ],
                    // 阅读进度指示器
                    if (widget.bookmark.readProgress > 0) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              value: widget.bookmark.readProgress / 100.0,
                              strokeWidth: 2,
                              color: Theme.of(rootContext).colorScheme.primary,
                              backgroundColor: Theme.of(rootContext)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.bookmark.readProgress}%',
                            style: Theme.of(rootContext)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(rootContext).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    // 标记喜爱按钮
                    IconButton(
                      onPressed: widget.onToggleMark != null
                          ? () => widget.onToggleMark!(widget.bookmark)
                          : null,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(32, 32),
                        maximumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(
                        widget.bookmark.isMarked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 20,
                        color: widget.bookmark.isMarked
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
                        color:
                            Theme.of(rootContext).colorScheme.onSurfaceVariant,
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
                              widget.onToggleArchive!(widget.bookmark);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(widget.bookmark.isArchived
                                      ? '已取消归档'
                                      : '已标记归档'),
                                  duration: const Duration(seconds: 2),
                                ),
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
                        widget.bookmark.isArchived
                            ? Icons.unarchive
                            : Icons.archive_outlined,
                        size: 20,
                        color: widget.bookmark.isArchived
                            ? Theme.of(rootContext)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.7)
                            : Theme.of(rootContext)
                                .colorScheme
                                .onSurfaceVariant,
                      ),
                      tooltip: widget.bookmark.isArchived ? '取消归档' : '归档',
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

  void _showLabelEditDialog(BuildContext context) async {
    List<String> labels = widget.availableLabels ?? [];

    // 先展示对话框（如果有缓存数据）
    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => LabelEditDialog(
          bookmark: widget.bookmark,
          availableLabels: labels,
          onUpdateLabels: widget.onUpdateLabels!,
          onLoadLabels: widget.onLoadLabels,
        ),
      );
    }
  }
}
