import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:readeck_app/routing/routes.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const MainLayout({
    super.key,
    required this.child,
    this.appBar,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ??
          (title != null || actions != null || leading != null
              ? AppBar(
                  title: title != null ? Text(title!) : null,
                  actions: actions,
                  leading: leading,
                  automaticallyImplyLeading: automaticallyImplyLeading,
                )
              : AppBar(
                  automaticallyImplyLeading: automaticallyImplyLeading,
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
      body: child, // 显示当前路由的页面
    );
  }
}
