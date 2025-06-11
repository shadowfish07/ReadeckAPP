import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'config/dependencies.dart';
import 'data/service/shared_preference_service.dart';
import 'routing/router.dart';
import 'ui/core/theme.dart';
import 'main_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.level = Level.all;

  final prefsService = SharedPreferencesService();
  final host = await prefsService.getReadeckApiHost();
  final token = await prefsService.getReadeckApiToken();

  runApp(MultiProvider(
    providers: providers(host.getOrDefault(''), token.getOrDefault('')),
    child: const MainApp(),
  ));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late GoRouter routerStore;

  @override
  void initState() {
    routerStore = router(context.read());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MainAppViewModel>(
      builder: (context, viewModel, child) {
        return MaterialApp.router(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: viewModel.themeMode,
          routerConfig: routerStore,
        );
      },
    );
  }
}
