import 'package:flutter/material.dart';
import 'package:readeck_app/ui/bookmarks/view_models/bookmarks_viewmodel.dart';
import 'package:readeck_app/ui/bookmarks/widget/bookmark_list_screen.dart';

class ArchivedScreen extends StatelessWidget {
  const ArchivedScreen({super.key, required this.viewModel});

  final ArchivedViewmodel viewModel;

  @override
  Widget build(BuildContext context) {
    return BookmarkListScreen(
      viewModel: viewModel,
      texts: const BookmarkListTexts(
        loadingText: '正在加载已归档书签',
        errorMessage: '已归档书签加载失败',
        emptyIcon: Icons.archive_outlined,
        emptyTitle: '暂无已归档书签',
        emptySubtitle: '归档的书签将在这里显示',
      ),
    );
  }
}
