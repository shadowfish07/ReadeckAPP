import 'package:flutter/material.dart';
import 'package:readeck_app/ui/bookmarks/view_models/bookmarks_viewmodel.dart';
import 'package:readeck_app/ui/bookmarks/widget/bookmark_list_screen.dart';

class ReadingScreen extends StatelessWidget {
  const ReadingScreen({super.key, required this.viewModel});

  final ReadingViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    return BookmarkListScreen(
      viewModel: viewModel,
      texts: const BookmarkListTexts(
        loadingText: '正在加载阅读中书签',
        errorMessage: '阅读中书签加载失败',
        emptyIcon: Icons.auto_stories_outlined,
        emptyTitle: '暂无阅读中书签',
        emptySubtitle: '下拉刷新或去Readeck开始阅读书签',
      ),
    );
  }
}
