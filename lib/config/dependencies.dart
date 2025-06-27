import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/daily_read_history/daily_read_history_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/data/service/database_service.dart';
import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/data/service/openrouter_api_client.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';

import 'package:readeck_app/domain/use_cases/label_use_cases.dart';

import '../data/service/shared_preference_service.dart';
import '../data/repository/theme/theme_repository.dart';
import '../main_viewmodel.dart';

List<SingleChildWidget> providers(String host, String token) {
  return [
    Provider(create: (context) => SharedPreferencesService()),
    Provider(
      create: (context) => ThemeRepository(
        context.read<SharedPreferencesService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => MainAppViewModel(
        context.read<ThemeRepository>(),
      ),
    ),
    Provider(create: (context) => ReadeckApiClient(host, token)),
    Provider(
        create: (context) =>
            OpenRouterApiClient(context.read<SharedPreferencesService>())),
    Provider(create: (context) => DatabaseService()),
    Provider(
        create: (context) =>
            BookmarkRepository(context.read(), context.read(), context.read())),
    Provider(create: (context) => DailyReadHistoryRepository(context.read())),
    Provider(create: (context) => LabelUseCases()),
    Provider(
        create: (context) =>
            BookmarkOperationUseCases(context.read(), context.read())),
    Provider(
        create: (context) => SettingsRepository(context.read(), context.read()))
  ];
}
