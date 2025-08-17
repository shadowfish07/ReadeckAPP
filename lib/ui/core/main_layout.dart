import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/main_viewmodel.dart';
import 'package:readeck_app/routing/routes.dart';
import 'package:readeck_app/ui/core/ui/share_overlay.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Widget? floatingActionButton;

  const MainLayout({
    super.key,
    required this.child,
    this.appBar,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.floatingActionButton,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  StreamSubscription<String>? _shareTextSubscription;
  bool _isShowingOverlay = false;

  @override
  void initState() {
    super.initState();
    _setupShareIntentListener();
  }

  void _setupShareIntentListener() {
    final mainViewModel = context.read<MainAppViewModel>();
    _shareTextSubscription = mainViewModel.shareTextStream.listen((sharedText) {
      if (mounted && !_isShowingOverlay) {
        _showShareOverlay(sharedText);
      }
    });
  }

  void _showShareOverlay(String sharedText) {
    setState(() {
      _isShowingOverlay = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ShareOverlay(
        sharedText: sharedText,
        onClose: () {
          Navigator.of(context).pop();
          setState(() {
            _isShowingOverlay = false;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _shareTextSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            onTap: () {
              context.pop();
              context.go(Routes.settings);
            },
          ),
        ],
      ),
      body: widget.child, // 显示当前路由的页面
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
