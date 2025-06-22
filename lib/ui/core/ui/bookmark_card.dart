import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          widget.onCardTap?.call(widget.bookmark);
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
                  children: widget.bookmark.labels.map((label) {
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
                          width: 16,
                          height: 16,
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
                  // 标签编辑按钮
                  IconButton(
                    onPressed: widget.onUpdateLabels != null
                        ? () => _showLabelEditDialog(rootContext)
                        : null,
                    icon: Icon(
                      Icons.local_offer_outlined,
                      size: 20,
                      color: Theme.of(rootContext).colorScheme.onSurfaceVariant,
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
                                    ? '已取消存档'
                                    : '已标记存档'),
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

  void _showLabelEditDialog(BuildContext context) async {
    List<String> labels = widget.availableLabels ?? [];

    // 先展示对话框（如果有缓存数据）
    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => _LabelEditDialog(
          bookmark: widget.bookmark,
          availableLabels: labels,
          onUpdateLabels: widget.onUpdateLabels!,
          onLoadLabels: widget.onLoadLabels,
        ),
      );
    }
  }
}

class _LabelEditDialog extends StatefulWidget {
  final Bookmark bookmark;
  final List<String> availableLabels;
  final Function(Bookmark bookmark, List<String> labels) onUpdateLabels;
  final Future<List<String>> Function()? onLoadLabels;

  const _LabelEditDialog({
    required this.bookmark,
    required this.availableLabels,
    required this.onUpdateLabels,
    this.onLoadLabels,
  });

  @override
  State<_LabelEditDialog> createState() => _LabelEditDialogState();
}

class _LabelEditDialogState extends State<_LabelEditDialog> {
  late List<String> _selectedLabels;
  late List<String> _filteredLabels;
  late List<String> _allLabels; // 保存完整的标签列表用于过滤
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLabels = List.from(widget.bookmark.labels);
    _allLabels = List.from(widget.availableLabels);
    _filteredLabels = List.from(widget.availableLabels);
    _searchController.addListener(_filterLabels);

    // 每次打开对话框都重新加载标签
    if (widget.onLoadLabels != null) {
      _loadLabels();
    }
  }

  Future<void> _loadLabels() async {
    if (widget.onLoadLabels == null) return;

    // 只有第一次没数据的时候需要loading，后续都不展示loading
    final shouldShowLoading = _allLabels.isEmpty;
    if (shouldShowLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final newLabels = await widget.onLoadLabels!();
      if (mounted) {
        setState(() {
          _allLabels = List.from(newLabels);
          _filterLabels(); // 重新应用当前的搜索过滤
          if (shouldShowLoading) {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (shouldShowLoading) {
            _isLoading = false;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载标签失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLabels() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLabels = _allLabels
          .where((label) => label.toLowerCase().contains(query))
          .toList();
    });
  }

  void _toggleLabel(String label) {
    setState(() {
      if (_selectedLabels.contains(label)) {
        _selectedLabels.remove(label);
      } else {
        _selectedLabels.add(label);
      }
    });
  }

  void _addNewLabel(String label) {
    if (label.isNotEmpty && !_selectedLabels.contains(label)) {
      setState(() {
        _selectedLabels.add(label);
        _searchController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑标签'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 搜索或新增标签输入框
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索或新增标签',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 已选择的标签
            if (_selectedLabels.isNotEmpty) ...[
              Text(
                '已选择的标签',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _selectedLabels.map((label) {
                  return Chip(
                    label: Text(label),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _toggleLabel(label),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 可用标签列表
            Text(
              '可用标签',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // 显示当前输入的标签（如果不存在且不为空）
                          if (_searchController.text.trim().isNotEmpty &&
                              !_filteredLabels
                                  .contains(_searchController.text.trim()) &&
                              !_selectedLabels
                                  .contains(_searchController.text.trim()))
                            ActionChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add, size: 16),
                                  const SizedBox(width: 4),
                                  Text('新增 "${_searchController.text.trim()}"'),
                                ],
                              ),
                              onPressed: () =>
                                  _addNewLabel(_searchController.text.trim()),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              labelStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          // 显示过滤后的现有标签
                          ..._filteredLabels
                              .where(
                                  (label) => !_selectedLabels.contains(label))
                              .map((label) {
                            return FilterChip(
                              label: Text(label),
                              selected: false,
                              onSelected: (_) => _toggleLabel(label),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            );
                          }),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            widget.onUpdateLabels(widget.bookmark, _selectedLabels);
            Navigator.of(context).pop();
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
