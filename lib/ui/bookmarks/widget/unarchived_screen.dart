import 'package:flutter/material.dart';
import 'package:readeck_app/ui/bookmarks/view_models/bookmarks_viewmodel.dart';
import 'package:readeck_app/ui/bookmarks/widget/bookmark_list_screen.dart';
import 'package:readeck_app/ui/core/main_layout.dart';

class UnarchivedScreen extends StatefulWidget {
  const UnarchivedScreen({super.key, required this.viewModel});

  final UnarchivedViewmodel viewModel;

  @override
  State<UnarchivedScreen> createState() => _UnarchivedScreenState();
}

class _UnarchivedScreenState extends State<UnarchivedScreen> {
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
      title: '未读',
      showFab: true,
      scrollController: _scrollController,
      child: BookmarkListScreen(
        viewModel: widget.viewModel,
        scrollController: _scrollController,
        texts: const BookmarkListTexts(
          loadingText: '正在加载未归档书签',
          errorMessage: '未归档书签加载失败',
          emptyIcon: Icons.inbox_outlined,
          emptyTitle: '暂无未归档书签',
          emptySubtitle: '下拉刷新或去Readeck添加新的书签',
        ),
      ),
    );
  }
}
