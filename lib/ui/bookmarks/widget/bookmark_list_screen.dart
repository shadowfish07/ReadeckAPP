import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/domain/models/bookmark_display_model/bookmark_display_model.dart';
import 'package:readeck_app/routing/routes.dart';
import 'package:readeck_app/ui/core/ui/bookmark_card.dart';
import 'package:readeck_app/ui/core/ui/error_page.dart';
import 'package:readeck_app/ui/core/ui/loading.dart';
import 'package:readeck_app/ui/bookmarks/view_models/bookmarks_viewmodel.dart';
import 'package:readeck_app/utils/network_error_exception.dart';

/// 书签列表页面的文案配置
class BookmarkListTexts {
  const BookmarkListTexts({
    required this.loadingText,
    required this.errorMessage,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  /// 加载中的文案
  final String loadingText;

  /// 错误信息
  final String errorMessage;

  /// 空状态图标
  final IconData emptyIcon;

  /// 空状态标题
  final String emptyTitle;

  /// 空状态副标题
  final String emptySubtitle;
}

/// 通用的书签列表页面组件
class BookmarkListScreen<T extends BaseBookmarksViewmodel>
    extends StatefulWidget {
  const BookmarkListScreen({
    super.key,
    required this.viewModel,
    required this.texts,
  });

  final T viewModel;
  final BookmarkListTexts texts;

  @override
  State<BookmarkListScreen<T>> createState() => _BookmarkListScreenState<T>();
}

class _BookmarkListScreenState<T extends BaseBookmarksViewmodel>
    extends State<BookmarkListScreen<T>> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.viewModel.loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<T>(
      builder: (context, viewmodel, child) {
        return CommandBuilder(
          command: widget.viewModel.load,
          whileExecuting: (context, lastValue, page) {
            if (lastValue == null || lastValue.isEmpty) {
              return Loading(text: widget.texts.loadingText);
            }
            return _buildList(widget.viewModel.bookmarks);
          },
          onError: (context, error, lastValue, param) {
            switch (error) {
              case NetworkErrorException _:
                return ErrorPage.networkError(
                  error: error,
                  onBack: () => widget.viewModel.load.execute(1),
                );
              default:
                return ErrorPage.unknownError(error: Exception(error));
            }
          },
          onData: (context, _, param) {
            final bookmarks = widget.viewModel.bookmarks;

            if (bookmarks.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  await widget.viewModel.load.executeWithFuture(1);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.texts.emptyIcon,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.texts.emptyTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.texts.emptySubtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return _buildList(bookmarks);
          },
        );
      },
    );
  }

  RefreshIndicator _buildList(List<BookmarkDisplayModel> bookmarks) {
    return RefreshIndicator(
      onRefresh: () async {
        await widget.viewModel.load.executeWithFuture(1);
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: bookmarks.length + (widget.viewModel.hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == bookmarks.length) {
            return ValueListenableBuilder(
                valueListenable: widget.viewModel.loadMore.isExecuting,
                builder: (context, isExecuting, _) {
                  if (isExecuting) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '正在加载更多...',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                });
          }

          final bookmarkModel = bookmarks[index];
          return BookmarkCard(
            bookmark: bookmarkModel.bookmark,
            onOpenUrl: widget.viewModel.openUrl,
            onToggleMark: (bookmark) =>
                widget.viewModel.toggleBookmarkMarked(bookmark),
            onUpdateLabels: (bookmark, labels) {
              widget.viewModel
                  .updateBookmarkLabels(bookmark, labels)
                  .catchError((error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('更新标签失败: $error'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              });
            },
            readingStats: bookmarkModel.stats,
            onCardTap: (bookmark) {
              context.push(
                Routes.bookmarkDetailWithId(bookmark.id),
                extra: {
                  'bookmark': bookmark,
                },
              );
            },
            availableLabels: widget.viewModel.availableLabels,
            onLoadLabels: () => widget.viewModel.loadLabels.executeWithFuture(),
            onToggleArchive: (bookmark) {
              widget.viewModel.toggleBookmarkArchived(bookmark);
            },
          );
        },
      ),
    );
  }
}
