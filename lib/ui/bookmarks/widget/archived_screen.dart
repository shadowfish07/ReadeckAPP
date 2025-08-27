import 'package:flutter/material.dart';
import 'package:readeck_app/ui/bookmarks/view_models/bookmarks_viewmodel.dart';
import 'package:readeck_app/ui/bookmarks/widget/bookmark_list_screen.dart';
import 'package:readeck_app/ui/core/main_layout.dart';

class ArchivedScreen extends StatefulWidget {
  const ArchivedScreen({super.key, required this.viewModel});

  final ArchivedViewmodel viewModel;

  @override
  State<ArchivedScreen> createState() => _ArchivedScreenState();
}

class _ArchivedScreenState extends State<ArchivedScreen> {
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
      title: '已归档',
      showFab: true,
      scrollController: _scrollController,
      child: BookmarkListScreen(
        viewModel: widget.viewModel,
        scrollController: _scrollController,
        texts: const BookmarkListTexts(
          loadingText: '正在加载已归档书签',
          errorMessage: '已归档书签加载失败',
          emptyIcon: Icons.archive_outlined,
          emptyTitle: '暂无已归档书签',
          emptySubtitle: '归档的书签将在这里显示',
        ),
      ),
    );
  }
}
