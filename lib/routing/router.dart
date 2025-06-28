import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/ui/api_config/view_models/api_config_viewmodel.dart';
import 'package:readeck_app/ui/api_config/widgets/api_config_page.dart';
import 'package:readeck_app/ui/core/main_layout.dart';
import 'package:readeck_app/ui/core/ui/error_page.dart';
import 'package:readeck_app/ui/daily_read/view_models/daily_read_viewmodel.dart';
import 'package:readeck_app/ui/daily_read/widgets/daily_read_screen.dart';
import 'package:readeck_app/ui/settings/view_models/about_viewmodel.dart';
import 'package:readeck_app/ui/settings/view_models/ai_settings_viewmodel.dart';
import 'package:readeck_app/ui/settings/view_models/settings_viewmodel.dart';
import 'package:readeck_app/ui/settings/view_models/translation_settings_viewmodel.dart';
import 'package:readeck_app/ui/settings/widgets/about_page.dart';
import 'package:readeck_app/ui/settings/widgets/ai_settings_screen.dart';
import 'package:readeck_app/ui/settings/widgets/settings_screen.dart';
import 'package:readeck_app/ui/settings/widgets/translation_settings_screen.dart';
import 'package:readeck_app/ui/bookmarks/view_models/bookmarks_viewmodel.dart';
import 'package:readeck_app/ui/bookmarks/widget/unarchived_screen.dart';
import 'package:readeck_app/ui/bookmarks/widget/archived_screen.dart';
import 'package:readeck_app/ui/bookmarks/widget/marked_screen.dart';
import 'package:readeck_app/ui/bookmarks/view_models/bookmark_detail_viewmodel.dart';
import 'package:readeck_app/ui/bookmarks/widget/bookmark_detail_screen.dart';

import 'routes.dart';

// AppBar 配置映射
final Map<String, String> _routeTitleMap = {
  Routes.settings: '设置',
  Routes.about: '关于',
  Routes.apiConfigSetting: 'API 配置',
  Routes.aiSetting: 'AI 设置',
  Routes.translationSetting: '翻译设置',
  Routes.dailyRead: '每日阅读',
  Routes.unarchived: '未读',
  Routes.archived: '已归档',
  Routes.marked: '标记喜爱',
  Routes.bookmarkDetail: '书签详情',
};

// 根据路由获取标题
String? _getTitleForRoute(String location) {
  return _routeTitleMap[location];
}

GoRouter router(SettingsRepository settingsRepository) => GoRouter(
      initialLocation: Routes.dailyRead,
      debugLogDiagnostics: true,
      redirect: _redirect,
      routes: [
        // 缓存路由
        StatefulShellRoute.indexedStack(
            builder: (context, state, child) {
              // 根据当前路由确定页面标题
              final title = _getTitleForRoute(state.matchedLocation);

              // 从设置页返回，跳转首页
              if (state.matchedLocation == Routes.settings) {
                return MainLayout(
                  title: title,
                  child: PopScope(
                      canPop: false,
                      onPopInvokedWithResult: (didPop, result) {
                        if (!didPop) {
                          context.go(Routes.dailyRead);
                        }
                      },
                      child: child),
                );
              }

              return MainLayout(
                title: title,
                child: child,
              );
            },
            branches: [
              StatefulShellBranch(routes: [
                GoRoute(
                  path: Routes.dailyRead,
                  builder: (context, state) {
                    return ChangeNotifierProvider(
                      create: (context) {
                        return DailyReadViewModel(context.read(),
                            context.read(), context.read(), context.read());
                      },
                      child: Consumer<DailyReadViewModel>(
                        builder: (context, viewModel, child) {
                          return DailyReadScreen(viewModel: viewModel);
                        },
                      ),
                    );
                  },
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  path: Routes.unarchived,
                  builder: (context, state) {
                    return ChangeNotifierProvider(
                      create: (context) => UnarchivedViewmodel(
                          context.read(), context.read(), context.read()),
                      child: Consumer<UnarchivedViewmodel>(
                        builder: (context, viewModel, child) {
                          return UnarchivedScreen(viewModel: viewModel);
                        },
                      ),
                    );
                  },
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  path: Routes.archived,
                  builder: (context, state) {
                    return ChangeNotifierProvider(
                      create: (context) => ArchivedViewmodel(
                          context.read(), context.read(), context.read()),
                      child: Consumer<ArchivedViewmodel>(
                        builder: (context, viewModel, child) {
                          return ArchivedScreen(viewModel: viewModel);
                        },
                      ),
                    );
                  },
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  path: Routes.marked,
                  builder: (context, state) {
                    return ChangeNotifierProvider(
                      create: (context) => MarkedViewmodel(
                          context.read(), context.read(), context.read()),
                      child: Consumer<MarkedViewmodel>(
                        builder: (context, viewModel, child) {
                          return MarkedScreen(viewModel: viewModel);
                        },
                      ),
                    );
                  },
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  path: Routes.settings,
                  builder: (context, state) {
                    return ChangeNotifierProvider(
                      create: (context) =>
                          SettingsViewModel(context.read(), context.read()),
                      child: Consumer<SettingsViewModel>(
                        builder: (context, viewModel, child) {
                          return SettingsScreen(viewModel: viewModel);
                        },
                      ),
                    );
                  },
                ),
              ])
            ]),
        GoRoute(
            path: Routes.about,
            builder: (context, state) {
              final viewModel = AboutViewModel();
              return AboutPage(viewModel: viewModel);
            }),
        GoRoute(
            path: Routes.apiConfigSetting,
            builder: (context, state) {
              final viewModel = ApiConfigViewModel(context.read());
              return ApiConfigPage(viewModel: viewModel);
            }),
        GoRoute(
            path: Routes.aiSetting,
            builder: (context, state) {
              final viewModel = AiSettingsViewModel(context.read());
              return AiSettingsScreen(viewModel: viewModel);
            }),
        GoRoute(
            path: Routes.translationSetting,
            builder: (context, state) {
              final viewModel = TranslationSettingsViewModel(context.read());
              return TranslationSettingsScreen(viewModel: viewModel);
            }),
        GoRoute(
            path: '${Routes.bookmarkDetail}/:id',
            builder: (context, state) {
              final bookmarkId = state.pathParameters['id']!;
              final bookmarkRepository = context.read<BookmarkRepository>();
              final bookmark = bookmarkRepository.getCachedBookmark(bookmarkId);
              if (bookmark == null) {
                // 书签可能已被删除，显示友好的错误提示
                return ErrorPage.bookmarkNotFound();
              }
              final viewModel = BookmarkDetailViewModel(
                context.read(),
                context.read(),
                context.read(),
                bookmark,
              );
              return ChangeNotifierProvider.value(
                value: viewModel,
                child: Consumer<BookmarkDetailViewModel>(
                  builder: (context, viewModel, child) {
                    return BookmarkDetailScreen(viewModel: viewModel);
                  },
                ),
              );
            }),
      ],
    );

Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  final isApiConfigured =
      await context.read<SettingsRepository>().isApiConfigured();

  if (isApiConfigured.isError()) {
    return null;
  }

  if (!isApiConfigured.getOrDefault(false)) {
    return Routes.apiConfigSetting;
  }

  // no need to redirect at all
  return null;
}
