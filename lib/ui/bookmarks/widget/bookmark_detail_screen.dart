import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:flutter_command/flutter_command.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_all/flutter_html_all.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/ui/bookmarks/view_models/bookmark_detail_viewmodel.dart';
import 'package:readeck_app/ui/core/ui/error_widget.dart';
import 'package:readeck_app/ui/core/ui/loading.dart';

class BookmarkDetailScreen extends StatefulWidget {
  const BookmarkDetailScreen({super.key, required this.viewModel});

  final BookmarkDetailViewModel viewModel;

  @override
  State<BookmarkDetailScreen> createState() => _BookmarkDetailScreenState();
}

class _BookmarkDetailScreenState extends State<BookmarkDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isAutoScrolling = false; // 标记是否正在自动滚动

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
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () {
              widget.viewModel.openUrl(widget.viewModel.bookmark.url);
            },
            tooltip: '在浏览器中打开',
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
              return Center(
                child: ErrorWidget(
                  message: '加载失败',
                  error: error.toString(),
                  onRetry: () => viewModel.retry(),
                ),
              );
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

    // 计算阅读进度百分比（0-100）
    int readProgress = 0;
    if (maxScrollExtent > 0) {
      readProgress =
          ((currentOffset / maxScrollExtent) * 100).round().clamp(0, 100);
    }

    // 使用Command更新阅读进度到服务器（带防抖功能）
    widget.viewModel.updateReadProgressCommand.execute(readProgress);
  }

  void _scrollToProgress() {
    if (!_scrollController.hasClients) return;

    final readProgress = widget.viewModel.bookmark.readProgress;
    if (readProgress <= 0) return;

    // 获取可滚动的最大距离
    final maxScrollExtent = _scrollController.position.maxScrollExtent;

    // 根据阅读进度计算滚动位置（0-100转换为0-maxScrollExtent）
    final targetOffset = (readProgress / 100.0) * maxScrollExtent;

    // 设置自动滚动标志
    _isAutoScrolling = true;

    // 平滑滚动到目标位置
    _scrollController
        .animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    )
        .then((_) {
      // 滚动完成后重置标志
      _isAutoScrolling = false;
    });
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
