import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/utils/command.dart';

class BookmarkCard extends StatelessWidget {
  final Bookmark bookmark;
  final Command1<void, String> onOpenUrl;
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
  Widget build(BuildContext rootContext) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          final url = bookmark.url;
          await onOpenUrl.execute(url);
          if (onOpenUrl.error && rootContext.mounted) {
            ScaffoldMessenger.of(rootContext).showSnackBar(
              SnackBar(
                content: Text(onOpenUrl.result.toString()),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: '复制链接',
                  textColor: Colors.white,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (rootContext.mounted) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
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
          }
        },
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
                      color: Theme.of(rootContext).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        bookmark.siteName!,
                        style: TextStyle(
                          color: Theme.of(rootContext).colorScheme.primary,
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
                          Theme.of(rootContext).colorScheme.primaryContainer,
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
                        ? () => onToggleMark!(bookmark)
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
                        ? () => onToggleArchive!(bookmark)
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
