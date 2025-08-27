import 'package:flutter/material.dart';
import 'package:readeck_app/ui/bookmarks/view_models/bookmarks_viewmodel.dart';
import 'package:readeck_app/ui/bookmarks/widget/bookmark_list_screen.dart';
import 'package:readeck_app/ui/core/main_layout.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key, required this.viewModel});

  final ReadingViewmodel viewModel;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: '阅读中',
      showFab: true,
      scrollController: _scrollController,
      child: BookmarkListScreen(
        viewModel: widget.viewModel,
        scrollController: _scrollController,
        texts: const BookmarkListTexts(
          loadingText: '正在加载阅读中书签',
          errorMessage: '阅读中书签加载失败',
          emptyIcon: Icons.auto_stories_outlined,
          emptyTitle: '暂无阅读中书签',
          emptySubtitle: '下拉刷新或去Readeck开始阅读书签',
        ),
      ),
    );
  }
}
