import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/routing/routes.dart';
import 'package:readeck_app/ui/core/ui/bookmark_card.dart';
import 'package:readeck_app/ui/core/ui/celebration_overlay.dart';
import 'package:readeck_app/ui/core/ui/error_page.dart';
import 'package:readeck_app/ui/core/ui/loading.dart';
import 'package:readeck_app/ui/daily_read/view_models/daily_read_viewmodel.dart';
import 'package:readeck_app/utils/network_error_exception.dart';
import 'package:readeck_app/ui/core/ui/snack_bar_helper.dart';

class DailyReadScreen extends StatefulWidget {
  const DailyReadScreen({super.key, required this.viewModel});

  final DailyReadViewModel viewModel;

  @override
  State<DailyReadScreen> createState() => _DailyReadScreenState();
}

class _DailyReadScreenState extends State<DailyReadScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // 初始化礼花控制器
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    // 设置书签归档回调
    widget.viewModel.setOnBookmarkArchivedCallback(_onBookmarkArchived);
  }

  @override
  void dispose() {
    // 释放动画控制器
    _confettiController.dispose();
    // 清除回调
    widget.viewModel.setOnBookmarkArchivedCallback(null);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.viewModel.load.errors.where((x) => x != null).listen((error, _) {
      appLogger.e(
        '加载书签失败',
        error: error,
      );
      SnackBarHelper.showError(
        context,
        '加载书签失败',
      );
    });
    widget.viewModel.toggleBookmarkArchived.errors
        .where((x) => x != null)
        .listen((error, _) {
      appLogger.e(
        '切换书签归档状态失败',
        error: error,
      );
      SnackBarHelper.showError(
        context,
        '切换书签归档状态失败',
      );
    });
    widget.viewModel.toggleBookmarkMarked.errors
        .where((x) => x != null)
        .listen((error, _) {
      appLogger.e(
        '切换书签标记状态失败',
        error: error,
      );
      SnackBarHelper.showError(
        context,
        '切换书签标记状态失败',
      );
    });
  }

  void _playConfetti() {
    _confettiController.play();
  }

  void _refreshNewContent() {
    _confettiController.stop();
    widget.viewModel.load.execute(true);
  }

  void _onBookmarkArchived() {
    if (widget.viewModel.unArchivedBookmarks.isEmpty) {
      _playConfetti();
    }
  }

  Widget render() {
    if (widget.viewModel.unArchivedBookmarks.isEmpty) {
      // 完成今日阅读，放烟花
      return Stack(
        children: [
          // 礼花动画 - 从左下角发射
          Align(
            alignment: Alignment.bottomLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 4, // 向右上方发射
              maxBlastForce: 40,
              minBlastForce: 5,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
                Theme.of(context).colorScheme.tertiary,
                Theme.of(context).colorScheme.error,
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.secondaryContainer,
                Theme.of(context).colorScheme.tertiaryContainer,
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          CelebrationOverlay(
            onRefreshNewContent: _refreshNewContent,
          )
        ],
      );
    }
    if (widget.viewModel.isNoMore) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.task_alt,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '已读完所有待读书签',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '太棒了！去Readeck添加更多书签继续阅读吧！',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
        final bookmarkModel = widget.viewModel.unArchivedBookmarks[index];
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
                SnackBarHelper.showError(
                  context,
                  '更新标签失败: $error',
                  duration: const Duration(seconds: 3),
                );
              }
            });
          },
          onCardTap: (bookmark) {
            context.push(
              Routes.bookmarkDetailWithId(bookmark.id),
            );
          },
          readingStats: bookmarkModel.stats,
          availableLabels: widget.viewModel.availableLabels,
          onLoadLabels: () => widget.viewModel.loadLabels.executeWithFuture(),
          onToggleArchive: (bookmark) {
            widget.viewModel.toggleBookmarkArchived(bookmark);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext rootContext) {
    return Consumer<DailyReadViewModel>(
      builder: (context, viewModel, child) {
        return CommandBuilder(
          command: viewModel.load,
          whileExecuting: (context, lastValue, param) {
            if (lastValue != null && lastValue.isEmpty) {
              return const Loading(text: '正在加载今日推荐');
            }

            return render();
          },
          onError: (context, error, lastValue, param) {
            switch (error) {
              case NetworkErrorException _:
                return ErrorPage.networkError(
                  error: error,
                  onBack: () => viewModel.load.execute(false),
                );
              default:
                return ErrorPage.unknownError(error: Exception(error));
            }
          },
          onData: (context, data, param) {
            return render();
          },
        );
      },
    );
  }
}
