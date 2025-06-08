import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:flutter/services.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/ui/core/ui/bookmark_card.dart';
import 'package:readeck_app/ui/core/ui/error_widget.dart';
import 'package:readeck_app/ui/core/ui/loading.dart';
import 'package:readeck_app/ui/daily_read/view_models/daily_read_viewmodel.dart';
import 'package:readeck_app/utils/result.dart';

class DailyReadScreen extends StatefulWidget {
  const DailyReadScreen({super.key, required this.viewModel});

  final DailyReadViewModel viewModel;

  @override
  State<DailyReadScreen> createState() => _DailyReadScreenState();
}

class _DailyReadScreenState extends State<DailyReadScreen> {
  @override
  Widget build(BuildContext rootContext) {
    return ListenableBuilder(
        listenable: widget.viewModel.load,
        builder: (context, _) {
          if (widget.viewModel.load.running) {
            return const Loading(text: '正在加载今日推荐');
          }

          if (widget.viewModel.load.result is Error<bool>) {
            print(
              'err   ${widget.viewModel.load.result}',
            );
            return ErrorWidget(
              message: '每日推荐加载失败',
              error: widget.viewModel.load.result.error,
              onRetry: () => widget.viewModel.load.execute(false),
            );
          }

          if (widget.viewModel.bookmarks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '已读完所有待读书签',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '太棒了！去Readeck添加更多书签继续阅读吧！',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => widget.viewModel.load.execute(true),
                      icon: const Icon(Icons.refresh),
                      label: const Text('刷新'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (widget.viewModel.unArchivedBookmarks.isEmpty) {
            // 完成今日阅读，放烟花
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '已读完今日',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => widget.viewModel.load.execute(true),
                      icon: const Icon(Icons.refresh),
                      label: const Text('刷新'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.viewModel.unArchivedBookmarks.length,
            itemBuilder: (context, index) {
              return BookmarkCard(
                bookmark: widget.viewModel.unArchivedBookmarks[index],
                onOpenUrl: widget.viewModel.openUrl,
                onToggleMark: (bookmark) =>
                    widget.viewModel.toggleBookmarkMarked(bookmark),
                onToggleArchive: (bookmark) =>
                    widget.viewModel.toggleBookmarkArchived(bookmark),
              );
            },
          );
        });
  }
}
