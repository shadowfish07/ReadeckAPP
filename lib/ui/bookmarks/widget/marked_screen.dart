import 'package:flutter/material.dart';
import 'package:readeck_app/ui/bookmarks/view_models/bookmarks_viewmodel.dart';
import 'package:readeck_app/ui/bookmarks/widget/bookmark_list_screen.dart';
import 'package:readeck_app/ui/core/main_layout.dart';

class MarkedScreen extends StatefulWidget {
  const MarkedScreen({super.key, required this.viewModel});

  final MarkedViewmodel viewModel;

  @override
  State<MarkedScreen> createState() => _MarkedScreenState();
}

class _MarkedScreenState extends State<MarkedScreen> {
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
      title: '标记喜爱',
      showFab: true,
      scrollController: _scrollController,
      child: BookmarkListScreen(
        viewModel: widget.viewModel,
        scrollController: _scrollController,
        texts: const BookmarkListTexts(
          loadingText: '正在加载喜爱书签',
          errorMessage: '喜爱书签加载失败',
          emptyIcon: Icons.favorite_outline,
          emptyTitle: '暂无喜爱书签',
          emptySubtitle: '标记为喜爱的书签将在这里显示',
        ),
      ),
    );
  }
}
