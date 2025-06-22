import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:flutter_command/flutter_command.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/routing/routes.dart';
import 'package:readeck_app/ui/core/ui/bookmark_card.dart';
import 'package:readeck_app/ui/core/ui/error_widget.dart';
import 'package:readeck_app/ui/core/ui/loading.dart';
import 'package:readeck_app/ui/bookmarks/view_models/bookmarks_viewmodel.dart';

class UnarchivedScreen extends StatefulWidget {
  const UnarchivedScreen({super.key, required this.viewModel});

  final UnarchivedViewmodel viewModel;

  @override
  State<UnarchivedScreen> createState() => _UnarchivedScreenState();
}

class _UnarchivedScreenState extends State<UnarchivedScreen> {
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
    return Consumer<UnarchivedViewmodel>(
      builder: (context, viewmodel, child) {
        return CommandBuilder(
          command: widget.viewModel.load,
          whileExecuting: (context, lastValue, page) {
            if (lastValue == null || lastValue.isEmpty) {
              return const Loading(text: '正在加载未归档书签');
            }
            return _buildList(lastValue);
          },
          onError: (context, error, lastValue, param) => ErrorWidget(
            message: '未归档书签加载失败',
            error: error.toString(),
            onRetry: () => widget.viewModel.load.execute(1),
          ),
          onData: (context, data, param) {
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
                              Icons.inbox_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无未归档书签',
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
                              '下拉刷新或去Readeck添加新的书签',
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

  RefreshIndicator _buildList(List<Bookmark> bookmarks) {
    return RefreshIndicator(
      onRefresh: () async {
        await widget.viewModel.load.executeWithFuture(1);
      },
      child: ListView.builder(
        controller: _scrollController,
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

          return BookmarkCard(
            bookmark: bookmarks[index],
            onOpenUrl: widget.viewModel.openUrl,
            onCardTap: (bookmark) {
              context.push(
                Routes.bookmarkDetailWithId(bookmark.id),
                extra: {
                  'bookmark': bookmark,
                  'onBookmarkUpdated': () {
                    // 隐式刷新，不显示loading
                    widget.viewModel.load.execute(1);
                  },
                },
              );
            },
            onToggleMark: (bookmark) =>
                widget.viewModel.toggleBookmarkMarked(bookmark),
            onToggleArchive: (bookmark) =>
                widget.viewModel.toggleBookmarkArchived(bookmark),
          );
        },
      ),
    );
  }
}
