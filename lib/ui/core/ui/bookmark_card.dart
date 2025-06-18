import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';

class BookmarkCard extends StatefulWidget {
  final Bookmark bookmark;
  final Command onOpenUrl;
  final Function(Bookmark bookmark)? onToggleMark;
  final Function(Bookmark bookmark)? onToggleArchive;

  const BookmarkCard({
    super.key,
    required this.bookmark,
    required this.onOpenUrl,
    this.onToggleMark,
    this.onToggleArchive,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          final url = widget.bookmark.url;
          widget.onOpenUrl(url);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                widget.bookmark.title,
                style: Theme.of(rootContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
                      child: Text(
                        widget.bookmark.siteName!,
                        style: Theme.of(rootContext)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: Theme.of(rootContext).colorScheme.primary,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatDate(widget.bookmark.created),
                    style: Theme.of(rootContext).textTheme.bodySmall?.copyWith(
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
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: widget.bookmark.labels.take(3).map((label) {
                    return Chip(
                      label: Text(
                        label,
                        style: Theme.of(rootContext)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: Theme.of(rootContext)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      backgroundColor: Theme.of(rootContext)
                          .colorScheme
                          .surfaceContainerHighest,
                      side: BorderSide.none,
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
                    onPressed: widget.onToggleMark != null
                        ? () => widget.onToggleMark!(widget.bookmark)
                        : null,
                    icon: Icon(
                      widget.bookmark.isMarked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 20,
                      color: widget.bookmark.isMarked
                          ? Theme.of(rootContext).colorScheme.error
                          : Theme.of(rootContext).colorScheme.onSurfaceVariant,
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
                    onPressed: widget.onToggleArchive != null
                        ? () {
                            widget.onToggleArchive!(widget.bookmark);
                          }
                        : null,
                    icon: Icon(
                      widget.bookmark.isArchived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                      size: 20,
                      color: widget.bookmark.isArchived
                          ? Theme.of(rootContext).colorScheme.primary
                          : Theme.of(rootContext).colorScheme.onSurfaceVariant,
                    ),
                    tooltip: widget.bookmark.isArchived ? '取消存档' : '存档',
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
