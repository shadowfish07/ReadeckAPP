import 'package:flutter/material.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';

class LabelEditDialog extends StatefulWidget {
  final Bookmark bookmark;
  final List<String> availableLabels;
  final Function(Bookmark bookmark, List<String> labels) onUpdateLabels;
  final Future<List<String>> Function()? onLoadLabels;

  const LabelEditDialog({
    super.key,
    required this.bookmark,
    required this.availableLabels,
    required this.onUpdateLabels,
    this.onLoadLabels,
  });

  @override
  State<LabelEditDialog> createState() => _LabelEditDialogState();
}

class _LabelEditDialogState extends State<LabelEditDialog> {
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
