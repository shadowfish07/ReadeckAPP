import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/daily_read_history/daily_read_history_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/ui/api_config/view_models/api_config_viewmodel.dart';
import 'package:readeck_app/ui/api_config/widgets/api_config_page.dart';
import 'package:readeck_app/ui/core/main_layout.dart';
import 'package:readeck_app/ui/core/ui/error_page.dart';
import 'package:readeck_app/ui/daily_read/view_models/daily_read_viewmodel.dart';
import 'package:readeck_app/ui/daily_read/widgets/daily_read_screen.dart';
import 'package:readeck_app/ui/settings/view_models/about_viewmodel.dart';
import 'package:readeck_app/ui/settings/view_models/ai_settings_viewmodel.dart';
import 'package:readeck_app/ui/settings/view_models/model_selection_viewmodel.dart';
import 'package:readeck_app/ui/settings/view_models/settings_viewmodel.dart';
import 'package:readeck_app/ui/settings/view_models/translation_settings_viewmodel.dart';
import 'package:readeck_app/ui/settings/view_models/ai_tag_settings_viewmodel.dart';
import 'package:readeck_app/ui/settings/widgets/about_page.dart';
import 'package:readeck_app/ui/settings/widgets/ai_settings_screen.dart';
import 'package:readeck_app/ui/settings/widgets/model_selection_screen.dart';
import 'package:readeck_app/ui/settings/widgets/settings_screen.dart';
import 'package:readeck_app/ui/settings/widgets/translation_settings_screen.dart';
import 'package:readeck_app/ui/settings/widgets/ai_tag_settings_screen.dart';
import 'package:readeck_app/ui/bookmarks/view_models/bookmarks_viewmodel.dart';
import 'package:readeck_app/ui/bookmarks/widget/unarchived_screen.dart';
import 'package:readeck_app/ui/bookmarks/widget/reading_screen.dart';
import 'package:readeck_app/ui/bookmarks/widget/archived_screen.dart';
import 'package:readeck_app/ui/bookmarks/widget/marked_screen.dart';
import 'package:readeck_app/ui/bookmarks/view_models/bookmark_detail_viewmodel.dart';
import 'package:readeck_app/ui/bookmarks/widget/bookmark_detail_screen.dart';
import 'package:readeck_app/ui/bookmarks/view_models/add_bookmark_viewmodel.dart';
import 'package:readeck_app/ui/bookmarks/widget/add_bookmark_screen.dart';

import 'routes.dart';

// AppBar 配置映射
final Map<String, String> _routeTitleMap = {
  Routes.settings: '设置',
  Routes.about: '关于',
  Routes.apiConfigSetting: 'API 配置',
  Routes.aiSetting: 'AI 设置',
  Routes.modelSelection: '选择模型',
  Routes.translationSetting: '翻译设置',
  Routes.aiTagSetting: 'AI 标签设置',
  Routes.dailyRead: '每日阅读',
  Routes.unarchived: '未读',
  Routes.reading: '阅读中',
  Routes.archived: '已归档',
  Routes.marked: '标记喜爱',
  Routes.bookmarkDetail: '书签详情',
  Routes.addBookmark: '添加书签',
};

// 根据路由获取标题
String? _getTitleForRoute(String location) {
  // 直接匹配
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
              final title =
                  _getTitleForRoute(state.fullPath ?? state.matchedLocation);

              // 检查是否为书签列表页面，需要显示FAB
              final isBookmarkListRoute = [
                Routes.dailyRead,
                Routes.unarchived,
                Routes.reading,
                Routes.archived,
                Routes.marked,
              ].contains(state.fullPath ?? state.matchedLocation);

              // 从设置页返回，跳转首页
              if ((state.fullPath ?? state.matchedLocation) ==
                  Routes.settings) {
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
                showFab: isBookmarkListRoute,
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
                  path: Routes.reading,
                  builder: (context, state) {
                    return ChangeNotifierProvider(
                      create: (context) => ReadingViewmodel(
                          context.read(), context.read(), context.read()),
                      child: Consumer<ReadingViewmodel>(
                        builder: (context, viewModel, child) {
                          return ReadingScreen(viewModel: viewModel);
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
                      create: (context) => SettingsViewModel(
                          context.read<SettingsRepository>(),
                          context.read<DailyReadHistoryRepository>()),
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
        // 设置子页面作为独立的顶级路由
        GoRoute(
          path: Routes.about,
          builder: (context, state) {
            return ChangeNotifierProvider<AboutViewModel>(
              create: (context) => AboutViewModel(
                context.read(),
                context.read(),
              ),
              child: Consumer<AboutViewModel>(
                builder: (context, viewModel, child) {
                  return AboutPage(viewModel: viewModel);
                },
              ),
            );
          },
        ),
        GoRoute(
          path: Routes.apiConfigSetting,
          builder: (context, state) {
            final viewModel = ApiConfigViewModel(context.read());
            return ApiConfigPage(viewModel: viewModel);
          },
        ),
        GoRoute(
          path: Routes.aiSetting,
          builder: (context, state) {
            final viewModel =
                AiSettingsViewModel(context.read(), context.read());
            return AiSettingsScreen(viewModel: viewModel);
          },
        ),
        GoRoute(
          path: Routes.modelSelection,
          builder: (context, state) {
            final scenario = state.uri.queryParameters['scenario'];
            final viewModel = ModelSelectionViewModel(
                context.read(), context.read(),
                scenario: scenario);
            return ModelSelectionScreen(
              viewModel: viewModel,
            );
          },
        ),
        GoRoute(
          path: Routes.translationSetting,
          builder: (context, state) {
            final viewModel = TranslationSettingsViewModel(
                context.read(), context.read(), context.read());
            return TranslationSettingsScreen(viewModel: viewModel);
          },
        ),
        GoRoute(
          path: Routes.aiTagSetting,
          builder: (context, state) {
            final viewModel = AiTagSettingsViewModel(context.read());
            return AiTagSettingsScreen(viewModel: viewModel);
          },
        ),
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
                context.read(),
                context.read(),
                bookmark.bookmark,
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
        GoRoute(
            path: Routes.addBookmark,
            builder: (context, state) {
              // 获取分享的文本参数
              final sharedText = state.uri.queryParameters['shared_text'];

              final viewModel = AddBookmarkViewModel(
                context.read(),
                context.read(),
                context.read(),
                context.read(),
                context.read(),
              );

              // 如果有分享的文本，进行预处理
              if (sharedText != null && sharedText.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  viewModel.processSharedText(sharedText);
                });
              }

              return ChangeNotifierProvider.value(
                value: viewModel,
                child: Consumer<AddBookmarkViewModel>(
                  builder: (context, viewModel, child) {
                    return AddBookmarkScreen(viewModel: viewModel);
                  },
                ),
              );
            }),
      ],
    );

Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  final isApiConfigured = context.read<SettingsRepository>().isApiConfigured();

  if (!isApiConfigured) {
    return Routes.apiConfigSetting;
  }

  // no need to redirect at all
  return null;
}
