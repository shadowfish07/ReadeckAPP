import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:readeck_app/data/repository/article/article_repository.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/daily_read_history/daily_read_history_repository.dart';
import 'package:readeck_app/data/repository/openrouter/openrouter_repository.dart';
import 'package:readeck_app/data/repository/reading_stats/reading_stats_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/data/service/database_service.dart';
import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/data/service/openrouter_api_client.dart';
import 'package:readeck_app/data/service/web_content_service.dart';
import 'package:readeck_app/data/repository/web_content/web_content_repository.dart';
import 'package:readeck_app/data/repository/ai_tag_recommendation/ai_tag_recommendation_repository.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';

import 'package:readeck_app/data/repository/label/label_repository.dart';

import '../data/service/shared_preference_service.dart';

import 'package:readeck_app/data/service/update_service.dart';
import 'package:readeck_app/data/repository/update/update_repository.dart';
import 'package:readeck_app/data/service/download_service.dart';
import 'package:readeck_app/data/service/app_installer_service.dart';
import 'package:readeck_app/domain/use_cases/app_update_use_case.dart';

import '../main_viewmodel.dart';
import '../ui/settings/view_models/about_viewmodel.dart';

List<SingleChildWidget> providers(String host, String token) {
  return [
    Provider(create: (context) => SharedPreferencesService()),
    Provider(create: (context) => ReadeckApiClient(host, token)),
    Provider(create: (context) => DatabaseService()),
    Provider(create: (context) => WebContentService()),
    Provider<WebContentRepository>(
        create: (context) => WebContentRepositoryImpl(context.read())),
    Provider(create: (context) {
      final prefsService = context.read<SharedPreferencesService>();
      final apiClient = context.read<ReadeckApiClient>();
      return SettingsRepository(prefsService, apiClient);
    }),
    Provider(
        create: (context) =>
            OpenRouterApiClient(context.read<SettingsRepository>())),
    Provider(create: (context) {
      final openRouterClient = context.read<OpenRouterApiClient>();
      return OpenRouterRepository(openRouterClient);
    }),
    Provider(create: (context) {
      final openRouterClient = context.read<OpenRouterApiClient>();
      final settingsRepository = context.read<SettingsRepository>();
      return AiTagRecommendationRepository(
          openRouterClient, settingsRepository);
    }),
    Provider(create: (context) => UpdateService()),
    Provider(create: (context) => UpdateRepository(context.read())),
    Provider(create: (context) => DownloadService()),
    Provider(create: (context) => AppInstallerService()),
    Provider(
        create: (context) => AppUpdateUseCase(
              downloadService: context.read(),
              installerService: context.read(),
            )),
    ChangeNotifierProvider(
      create: (context) => MainAppViewModel(
        context.read<SettingsRepository>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => AboutViewModel(
        context.read<UpdateRepository>(),
        context.read<AppUpdateUseCase>(),
      ),
    ),
    Provider(
        create: (context) => ArticleRepository(
            context.read(), context.read(), context.read(), context.read())),
    Provider(create: (context) => ReadingStatsRepository(context.read())),
    Provider(
        create: (context) =>
            BookmarkRepository(context.read(), context.read(), context.read())),
    Provider(create: (context) => DailyReadHistoryRepository(context.read())),
    Provider(create: (context) => LabelRepository(context.read())),
    Provider(
        create: (context) =>
            BookmarkOperationUseCases(context.read(), context.read())),
  ];
}
