import 'package:flutter/material.dart';
import 'package:readeck_app/ui/bookmarks/view_models/bookmarks_viewmodel.dart';
import 'package:readeck_app/ui/bookmarks/widget/bookmark_list_screen.dart';

class UnarchivedScreen extends StatelessWidget {
  const UnarchivedScreen({super.key, required this.viewModel});

  final UnarchivedViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    return BookmarkListScreen(
      viewModel: viewModel,
      texts: const BookmarkListTexts(
        loadingText: '正在加载未归档书签',
        errorMessage: '未归档书签加载失败',
        emptyIcon: Icons.inbox_outlined,
        emptyTitle: '暂无未归档书签',
        emptySubtitle: '下拉刷新或去Readeck添加新的书签',
      ),
    );
  }
}
