import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:readeck_app/data/repository/article/article_repository.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/daily_read_history/daily_read_history_repository.dart';
import 'package:readeck_app/data/repository/openrouter/openrouter_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/data/service/database_service.dart';
import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/data/service/openrouter_api_client.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';

import 'package:readeck_app/data/repository/label/label_repository.dart';

import '../data/service/shared_preference_service.dart';

import '../main_viewmodel.dart';

List<SingleChildWidget> providers(String host, String token) {
  return [
    Provider(create: (context) => SharedPreferencesService()),
    Provider(create: (context) => ReadeckApiClient(host, token)),
    Provider(create: (context) => DatabaseService()),
    Provider(create: (context) {
      final prefsService = context.read<SharedPreferencesService>();
      return SettingsRepository(prefsService);
    }),
    Provider(
        create: (context) =>
            OpenRouterApiClient(context.read<SettingsRepository>())),
    Provider(create: (context) {
      final openRouterClient = context.read<OpenRouterApiClient>();
      return OpenRouterRepository(openRouterClient);
    }),
    ChangeNotifierProvider(
      create: (context) => MainAppViewModel(
        context.read<SettingsRepository>(),
      ),
    ),
    Provider(
        create: (context) => ArticleRepository(
            context.read(), context.read(), context.read(), context.read())),
    Provider(create: (context) => BookmarkRepository(context.read())),
    Provider(create: (context) => DailyReadHistoryRepository(context.read())),
    Provider(create: (context) => LabelRepository(context.read())),
    Provider(
        create: (context) =>
            BookmarkOperationUseCases(context.read(), context.read())),
  ];
}
