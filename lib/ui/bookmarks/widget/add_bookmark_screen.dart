import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/ui/bookmarks/view_models/add_bookmark_viewmodel.dart';
import 'package:readeck_app/ui/core/ui/label_edit_dialog.dart';
import 'package:readeck_app/ui/core/ui/loading.dart';
import 'package:readeck_app/ui/core/ui/snack_bar_helper.dart';

class AddBookmarkScreen extends StatefulWidget {
  const AddBookmarkScreen({super.key, required this.viewModel});

  final AddBookmarkViewModel viewModel;

  @override
  State<AddBookmarkScreen> createState() => _AddBookmarkScreenState();
}

class _AddBookmarkScreenState extends State<AddBookmarkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  late ListenableSubscription _successSubscription;
  late ListenableSubscription _errorSubscription;
  late ListenableSubscription _contentFetchErrorSubscription;
  late ListenableSubscription _tagGenerationErrorSubscription;

  @override
  void initState() {
    super.initState();

    // 初始化控制器的值
    _urlController.text = widget.viewModel.url;
    _titleController.text = widget.viewModel.title;

    // 监听创建成功
    _successSubscription = widget.viewModel.createBookmark.listen((result, _) {
      if (mounted) {
        SnackBarHelper.showSuccess(context, '书签创建请求已提交，正在后台处理中');
        context.pop();
      }
    });

    // 监听创建失败
    _errorSubscription = widget.viewModel.createBookmark.errors
        .where((x) => x != null)
        .listen((error, _) {
      if (mounted && error != null) {
        SnackBarHelper.showError(
          context,
          '创建失败: ${error.error.toString()}',
          duration: const Duration(seconds: 3),
        );
      }
    });

    // 监听网页内容获取失败
    _contentFetchErrorSubscription = widget
        .viewModel.autoFetchContentCommand.errors
        .where((x) => x != null)
        .listen((error, _) {
      if (mounted && error != null) {
        SnackBarHelper.showError(
          context,
          '获取网页内容失败: ${error.error.toString()}',
          duration: const Duration(seconds: 3),
        );
      }
    });

    // 监听AI标签推荐失败
    _tagGenerationErrorSubscription = widget
        .viewModel.autoGenerateTagsCommand.errors
        .where((x) => x != null)
        .listen((error, _) {
      if (mounted && error != null) {
        SnackBarHelper.showError(
          context,
          'AI标签推荐失败: ${error.error.toString()}',
          duration: const Duration(seconds: 3),
        );
      }
    });

    // 监听表单字段变化
    _urlController.addListener(() {
      if (widget.viewModel.url != _urlController.text) {
        widget.viewModel.updateUrl(_urlController.text);
      }
    });
    _titleController.addListener(() {
      if (widget.viewModel.title != _titleController.text) {
        widget.viewModel.updateTitle(_titleController.text);
      }
    });

    // 监听ViewModel的变化以更新控制器
    widget.viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    // 同步ViewModel的值到控制器
    if (_urlController.text != widget.viewModel.url) {
      _urlController.text = widget.viewModel.url;
    }
    if (_titleController.text != widget.viewModel.title) {
      _titleController.text = widget.viewModel.title;
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _successSubscription.cancel();
    _errorSubscription.cancel();
    _contentFetchErrorSubscription.cancel();
    _tagGenerationErrorSubscription.cancel();
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() == true) {
      final params = CreateBookmarkParams(
        url: widget.viewModel.url,
        title: widget.viewModel.title,
        labels: widget.viewModel.selectedLabels,
      );
      widget.viewModel.createBookmark.execute(params);
    }
  }

  void _showLabelSelector() async {
    // 创建一个虚拟的 Bookmark 对象来配合 LabelEditDialog
    final dummyBookmark = Bookmark(
      id: '',
      url: '',
      title: '',
      labels: widget.viewModel.selectedLabels,
      isMarked: false,
      isArchived: false,
      readProgress: 0,
      created: DateTime.now(),
    );

    await showDialog(
      context: context,
      builder: (context) => LabelEditDialog(
        bookmark: dummyBookmark,
        availableLabels: widget.viewModel.availableLabels,
        onUpdateLabels: (bookmark, labels) {
          widget.viewModel.updateSelectedLabels(labels);
        },
        onLoadLabels: () async {
          // 触发加载标签并返回最新的标签列表
          widget.viewModel.loadLabels.execute();
          return widget.viewModel.availableLabels;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加书签'),
      ),
      body: Consumer<AddBookmarkViewModel>(
        builder: (context, viewModel, child) {
          return CommandBuilder(
            command: viewModel.loadLabels,
            whileExecuting: (context, lastValue, param) {
              if (lastValue == null || lastValue.isEmpty) {
                return const Loading(text: '正在加载标签');
              }
              return _buildForm(viewModel);
            },
            onError: (context, error, lastValue, param) {
              return _buildForm(viewModel);
            },
            onData: (context, data, param) {
              return _buildForm(viewModel);
            },
          );
        },
      ),
    );
  }

  Widget _buildForm(AddBookmarkViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // URL输入字段
            ValueListenableBuilder<bool>(
              valueListenable: viewModel.autoFetchContentCommand.isExecuting,
              builder: (context, isFetching, _) {
                return ValueListenableBuilder(
                  valueListenable: viewModel.autoFetchContentCommand.errors,
                  builder: (context, error, _) {
                    // 如果正在执行，错误状态应该被重置
                    final hasError = error != null && !isFetching;

                    return TextFormField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'URL *',
                        hintText: '请输入网页链接',
                        border: const OutlineInputBorder(),
                        prefixIcon: isFetching
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const Icon(Icons.link),
                        suffixIcon: hasError
                            ? IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: viewModel.retryContentFetch,
                                tooltip: '重新获取',
                              )
                            : null,
                        helperText: _getUrlHelperText(
                            viewModel, isFetching, hasError ? error : null),
                        helperStyle:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _getUrlHelperColor(context, viewModel,
                                      isFetching, hasError ? error : null),
                                ),
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入URL';
                        }
                        if (!viewModel.isValidUrl) {
                          return '请输入有效的URL（以http://或https://开头）';
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // 标题输入字段
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '标题',
                hintText: viewModel.isContentFetched ? '已自动获取' : '可选，留空将自动获取',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  viewModel.isContentFetched ? Icons.auto_awesome : Icons.title,
                  color: viewModel.isContentFetched
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitForm(),
            ),
            const SizedBox(height: 16),

            // 标签选择区域
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标签标题和编辑按钮
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '标签',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: _showLabelSelector,
                      icon: const Icon(Icons.edit),
                      tooltip: '编辑标签',
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // AI推荐标签区域
                if (viewModel.hasAiModelConfigured)
                  ..._buildAiRecommendationSection(viewModel),

                // 已选择的标签
                if (viewModel.selectedLabels.isEmpty)
                  Text(
                    '未选择标签',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: viewModel.selectedLabels.map((label) {
                      return Chip(
                        label: Text(label),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => viewModel.removeLabel(label),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      );
                    }).toList(),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // 提交按钮
            SizedBox(
              width: double.infinity,
              child: Consumer<AddBookmarkViewModel>(
                builder: (context, viewModel, child) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: viewModel.createBookmark.isExecuting,
                    builder: (context, isExecuting, _) {
                      if (isExecuting) {
                        return FilledButton.icon(
                          onPressed: null,
                          icon: const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          label: const Text('创建中...'),
                        );
                      }

                      return FilledButton.icon(
                        onPressed: viewModel.canSubmit ? _submitForm : null,
                        icon: const Icon(Icons.bookmark_add),
                        label: const Text('创建书签'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取URL输入框的帮助文本
  String _getUrlHelperText(
      AddBookmarkViewModel viewModel, bool isFetching, dynamic error) {
    if (isFetching) {
      return '正在获取网页内容...';
    }
    if (error != null) {
      return '获取失败，请检查网址或重试';
    }
    if (viewModel.isContentFetched) {
      return '已成功获取网页内容';
    }
    return '必填项';
  }

  /// 获取URL输入框帮助文本的颜色
  Color? _getUrlHelperColor(BuildContext context,
      AddBookmarkViewModel viewModel, bool isFetching, dynamic error) {
    if (isFetching) {
      return Theme.of(context).colorScheme.primary;
    }
    if (error != null) {
      return Theme.of(context).colorScheme.error;
    }
    if (viewModel.isContentFetched) {
      return Theme.of(context).colorScheme.primary;
    }
    return Theme.of(context).colorScheme.primary;
  }

  /// 构建AI推荐标签区域
  List<Widget> _buildAiRecommendationSection(AddBookmarkViewModel viewModel) {
    return [
      // AI推荐状态指示器
      ValueListenableBuilder<bool>(
        valueListenable: viewModel.autoGenerateTagsCommand.isExecuting,
        builder: (context, isGenerating, _) {
          if (isGenerating) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI正在分析内容并推荐标签...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),

      // AI推荐标签显示 - 使用shouldShowRecommendations来控制显示
      if (viewModel.shouldShowRecommendations) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI推荐标签',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // 只添加未选择的推荐标签
                      for (final tag in viewModel.recommendedTags) {
                        if (!viewModel.selectedLabels.contains(tag)) {
                          viewModel.addRecommendedTag(tag);
                        }
                      }
                    },
                    child: const Text('全部添加'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: viewModel.recommendedTags
                    .where((tag) => !viewModel.selectedLabels.contains(tag))
                    .map((tag) {
                  return ActionChip(
                    label: Text(tag),
                    onPressed: () => viewModel.addRecommendedTag(tag),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHigh,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 8),
    ];
  }
}
