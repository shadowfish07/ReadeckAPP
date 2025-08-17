import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/ui/bookmarks/view_models/add_bookmark_viewmodel.dart';
import 'package:readeck_app/ui/core/ui/snack_bar_helper.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/label/label_repository.dart';

/// 分享内容时显示的悬浮窗组件
class ShareOverlay extends StatefulWidget {
  const ShareOverlay({
    super.key,
    required this.sharedText,
    required this.onClose,
  });

  final String sharedText;
  final VoidCallback onClose;

  @override
  State<ShareOverlay> createState() => _ShareOverlayState();
}

class _ShareOverlayState extends State<ShareOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late AddBookmarkViewModel _viewModel;

  String _extractedUrl = '';
  String _extractedTitle = '';

  @override
  void initState() {
    super.initState();

    // 初始化动画
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // 直接创建ViewModel实例，避免Provider依赖问题
    _viewModel = AddBookmarkViewModel(
      context.read<BookmarkRepository>(),
      context.read<LabelRepository>(),
    );

    // 解析分享的文本
    _parseSharedText(widget.sharedText);

    // 启动动画
    _animationController.forward();

    // 监听创建结果
    _setupBookmarkCreationListeners();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _viewModel.dispose(); // 释放ViewModel资源
    super.dispose();
  }

  void _parseSharedText(String text) {
    // 简单的URL检测和提取
    final urlRegex = RegExp(r'https?://[^\s]+');
    final match = urlRegex.firstMatch(text);

    if (match != null) {
      _extractedUrl = match.group(0)!;
      // 尝试从文本中提取标题（去除URL后的剩余文本）
      _extractedTitle = text.replaceAll(_extractedUrl, '').trim();
    } else {
      // 如果没有找到URL，将整个文本作为标题，URL留空
      _extractedTitle = text;
      _extractedUrl = '';
    }

    // 更新ViewModel
    _viewModel.updateUrl(_extractedUrl);
    _viewModel.updateTitle(_extractedTitle);
  }

  void _setupBookmarkCreationListeners() {
    // 监听创建成功
    _viewModel.createBookmark.listen((result, _) {
      if (mounted) {
        SnackBarHelper.showSuccess(context, '书签创建请求已提交，正在后台处理中');
        _closeOverlay();
      }
    });

    // 监听创建失败
    _viewModel.createBookmark.errors.where((x) => x != null).listen((error, _) {
      if (mounted && error != null) {
        SnackBarHelper.showError(
          context,
          '创建失败: ${error.error.toString()}',
          duration: const Duration(seconds: 3),
        );
      }
    });
  }

  void _closeOverlay() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  void _createBookmark() {
    if (_viewModel.canSubmit) {
      final params = CreateBookmarkParams(
        url: _viewModel.url,
        title: _viewModel.title,
        labels: _viewModel.selectedLabels,
      );
      _viewModel.createBookmark.execute(params);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Material(
            color: Colors.black54,
            child: InkWell(
              onTap: _closeOverlay,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () {}, // 阻止点击事件冒泡
                      child: _buildContent(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return ChangeNotifierProvider<AddBookmarkViewModel>.value(
      value: _viewModel,
      child: Consumer<AddBookmarkViewModel>(
        builder: (context, viewModel, child) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题栏
                Row(
                  children: [
                    Icon(
                      Icons.bookmark_add,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '创建书签',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: _closeOverlay,
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 分享内容预览
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '分享的内容:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.sharedText,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // URL字段
                if (_extractedUrl.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'URL:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _extractedUrl,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),

                // 标题字段
                if (_extractedTitle.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '标题:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _extractedTitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),

                // 已选择的标签
                if (viewModel.selectedLabels.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '标签:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: viewModel.selectedLabels.map((label) {
                          return Chip(
                            label: Text(label),
                            labelStyle: Theme.of(context).textTheme.bodySmall,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),

                // 操作按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _closeOverlay,
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ValueListenableBuilder<bool>(
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
                            onPressed:
                                viewModel.canSubmit ? _createBookmark : null,
                            icon: const Icon(Icons.bookmark_add),
                            label: const Text('创建书签'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
