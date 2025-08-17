import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/data/service/update_service.dart';
import 'package:readeck_app/main_viewmodel.dart';
import 'package:readeck_app/routing/routes.dart';
import 'package:readeck_app/ui/core/ui/bookmark_list_fab.dart';

/// ScrollController提供者，用于FAB和页面之间共享滚动控制器
class ScrollControllerProvider extends ChangeNotifier {
  ScrollController? _scrollController;

  ScrollController? get scrollController => _scrollController;

  void setScrollController(ScrollController? controller) {
    if (_scrollController != controller) {
      _scrollController = controller;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _scrollController = null;
    super.dispose();
  }
}

class MainLayout extends StatefulWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Widget? floatingActionButton;
  final bool showFab;

  const MainLayout({
    super.key,
    required this.child,
    this.appBar,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.floatingActionButton,
    this.showFab = false,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  StreamSubscription<String>? _shareTextSubscription;
  StreamSubscription<UpdateInfo>? _updateSubscription;
  bool _isProcessingShare = false;
  bool _hasUpdate = false;

  @override
  void initState() {
    super.initState();
    _setupShareIntentListener();
    _setupUpdateListener();
  }

  void _setupShareIntentListener() {
    final mainViewModel = context.read<MainAppViewModel>();
    _shareTextSubscription = mainViewModel.shareTextStream.listen((sharedText) {
      if (mounted && !_isProcessingShare) {
        _navigateToAddBookmark(sharedText);
      }
    });
  }

  void _navigateToAddBookmark(String sharedText) {
    setState(() {
      _isProcessingShare = true;
    });

    // 使用 query parameter 传递分享的文本
    final uri = Uri.parse(Routes.addBookmark);
    final newUri = uri.replace(queryParameters: {
      'shared_text': sharedText,
    });

    context.push(newUri.toString()).then((_) {
      // 导航完成后重置状态
      if (mounted) {
        setState(() {
          _isProcessingShare = false;
        });
      }
    });
  }

  void _setupUpdateListener() {
    final mainViewModel = context.read<MainAppViewModel>();
    _updateSubscription = mainViewModel.onUpdateAvailable.listen((updateInfo) {
      if (mounted) {
        setState(() {
          _hasUpdate = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发现新版本: ${updateInfo.version}'),
            action: SnackBarAction(
              label: '前往更新',
              onPressed: () {
                context.go(Routes.about);
              },
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _shareTextSubscription?.cancel();
    _updateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ScrollControllerProvider(),
      child: Scaffold(
        appBar: widget.appBar ??
            (widget.title != null ||
                    widget.actions != null ||
                    widget.leading != null
                ? AppBar(
                    title: widget.title != null ? Text(widget.title!) : null,
                    actions: widget.actions,
                    leading: widget.leading,
                    automaticallyImplyLeading: widget.automaticallyImplyLeading,
                  )
                : AppBar(
                    automaticallyImplyLeading: widget.automaticallyImplyLeading,
                    leading: Builder(
                      builder: (context) {
                        return IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        );
                      },
                    ),
                  )),
        drawer: NavigationDrawer(
          children: [
            ListTile(
              title: const Text('每日阅读'),
              onTap: () {
                context.pop();
                context.go(Routes.dailyRead);
              },
            ),
            ListTile(
              title: const Text('未读'),
              onTap: () {
                context.pop();
                context.go(Routes.unarchived);
              },
            ),
            ListTile(
              title: const Text('阅读中'),
              onTap: () {
                context.pop();
                context.go(Routes.reading);
              },
            ),
            ListTile(
              title: const Text('已归档'),
              onTap: () {
                context.pop();
                context.go(Routes.archived);
              },
            ),
            ListTile(
              title: const Text('收藏'),
              onTap: () {
                context.pop();
                context.go(Routes.marked);
              },
            ),
            ListTile(
              title: const Text('设置'),
              trailing: _hasUpdate ? const Badge() : null,
              onTap: () {
                context.pop();
                context.go(Routes.settings);
              },
            ),
          ],
        ),
        body: widget.child, // 显示当前路由的页面
        floatingActionButton: widget.showFab
            ? Consumer<ScrollControllerProvider>(
                builder: (context, provider, child) {
                  return BookmarkListFab(
                    scrollController: provider.scrollController,
                  );
                },
              )
            : widget.floatingActionButton,
      ),
    );
  }
}
