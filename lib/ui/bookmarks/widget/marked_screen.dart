import 'package:flutter/material.dart';
import 'package:readeck_app/ui/bookmarks/view_models/bookmarks_viewmodel.dart';
import 'package:readeck_app/ui/bookmarks/widget/bookmark_list_screen.dart';

class MarkedScreen extends StatelessWidget {
  const MarkedScreen({super.key, required this.viewModel});

  final MarkedViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    return BookmarkListScreen(
      viewModel: viewModel,
      texts: const BookmarkListTexts(
        loadingText: '正在加载喜爱书签',
        errorMessage: '喜爱书签加载失败',
        emptyIcon: Icons.favorite_outline,
        emptyTitle: '暂无喜爱书签',
        emptySubtitle: '标记为喜爱的书签将在这里显示',
      ),
    );
  }
}
