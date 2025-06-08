import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/ui/core/main_layout.dart';
import 'package:readeck_app/ui/daily_read/view_models/daily_read_viewmodel.dart';
import 'package:readeck_app/ui/daily_read/widgets/daily_read_screen.dart';
import 'package:readeck_app/ui/settings/view_models/about_viewmodel.dart';
import 'package:readeck_app/ui/settings/view_models/settings_viewmodel.dart';
import 'package:readeck_app/ui/settings/widgets/about_page.dart';
import 'package:readeck_app/ui/settings/widgets/settings_screen.dart';

import 'routes.dart';

// AppBar 配置映射
final Map<String, String> _routeTitleMap = {
  Routes.settings: '设置',
  Routes.about: '关于',
  Routes.apiConfigSetting: 'API 配置',
  Routes.home: '首页',
  Routes.dailyRead: '每日阅读',
  Routes.unread: '未读',
};

// 根据路由获取标题
String? _getTitleForRoute(String location) {
  return _routeTitleMap[location];
}

GoRouter router() => GoRouter(
      initialLocation: Routes.dailyRead,
      debugLogDiagnostics: true,
      routes: [
        ShellRoute(
            builder: (context, state, child) {
              // 根据当前路由确定页面标题
              final title = _getTitleForRoute(state.matchedLocation);
              return MainLayout(
                title: title,
                child: child,
              ); // 包含侧边菜单的布局
            },
            routes: [
              GoRoute(
                path: Routes.dailyRead,
                builder: (context, state) {
                  return ChangeNotifierProvider(
                    create: (context) => DailyReadViewModel(
                        context.read(), context.read(), context.read()),
                    child: Consumer<DailyReadViewModel>(
                      builder: (context, viewModel, child) {
                        return DailyReadScreen(viewModel: viewModel);
                      },
                    ),
                  );
                },
              ),
              GoRoute(
                path: Routes.settings,
                builder: (context, state) {
                  return ChangeNotifierProvider(
                    create: (context) => SettingsViewModel(context.read()),
                    child: Consumer<SettingsViewModel>(
                      builder: (context, viewModel, child) {
                        return SettingsScreen(viewModel: viewModel);
                      },
                    ),
                  );
                },
              ),
            ]),
        GoRoute(
            path: Routes.about,
            builder: (context, state) {
              final viewModel = AboutViewModel();
              return AboutPage(viewModel: viewModel);
            }),
      ],
    );

// TODO API 配置未定义就跳到定义页
// // From https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/redirection.dart
// Future<String?> _redirect(BuildContext context, GoRouterState state) async {
//   // if the user is not logged in, they need to login
//   final loggedIn = await context.read<AuthRepository>().isAuthenticated;
//   final loggingIn = state.matchedLocation == Routes.login;
//   if (!loggedIn) {
//     return Routes.login;
//   }

//   // if the user is logged in but still on the login page, send them to
//   // the home page
//   if (loggingIn) {
//     return Routes.home;
//   }

//   // no need to redirect at all
//   return null;
// }
