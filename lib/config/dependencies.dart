import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:readeck_app/data/service/readeck_service.dart';

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
    Provider(create: (context) => ReadeckService(host, token))
  ];
}
