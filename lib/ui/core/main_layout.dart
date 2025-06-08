import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
            title: const Text('首页'),
            onTap: () => context.go('/home'),
          ),
          ListTile(
            title: const Text('个人资料'),
            onTap: () => context.go('/profile'),
          ),
          ListTile(
            title: const Text('设置'),
            onTap: () => context.go('/settings'),
          ),
        ],
      ),
      body: child, // 显示当前路由的页面
    );
  }
}
