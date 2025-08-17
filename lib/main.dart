import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'config/dependencies.dart';
import 'data/repository/settings/settings_repository.dart';
import 'data/service/shared_preference_service.dart';
import 'routing/router.dart';
import 'ui/core/theme.dart';
import 'ui/core/ui/error_page.dart';
import 'main_viewmodel.dart';
import 'utils/rotating_file_output.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 配置Logger
  await _configureLogger();

  final prefsService = SharedPreferencesService();
  final host = await prefsService.getReadeckApiHost();
  final token = await prefsService.getReadeckApiToken();

  runApp(MultiProvider(
    providers: providers(host.getOrDefault(''), token.getOrDefault('')),
    child: const MainApp(),
  ));
}

// 全局Logger实例
late Logger appLogger;

// 全局ScaffoldMessenger key，用于在页面导航后显示SnackBar
final GlobalKey<ScaffoldMessengerState> globalScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// 配置Logger，在正式包中将INFO级别以上的日志输出到文件
Future<void> _configureLogger() async {
  if (kDebugMode) {
    // 开发模式：输出所有日志到控制台
    Logger.level = Level.all;
    appLogger = Logger();
  } else {
    // 正式包：只输出INFO级别以上的日志，并保存到文件
    Logger.level = Level.info;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }

      appLogger = Logger(
        output: MultiOutput([
          ConsoleOutput(), // 仍然输出到控制台（在某些情况下有用）
          RotatingFileOutput(
            basePath: logDir.path,
            maxFileSize: 2 * 1024 * 1024, // 2MB per file
            maxFiles: 5, // 保留5个文件
          ),
        ]),
        filter: ProductionFilter(),
      );
    } catch (e) {
      // 如果文件输出失败，至少保证控制台输出
      Logger.level = Level.info;
      appLogger = Logger();
    }
  }
}

/// 轮转文件输出器

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late GoRouter routerStore;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    routerStore = router(context.read());
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 预加载设置配置
      final settingsRepository = context.read<SettingsRepository>();
      final result = await settingsRepository.loadSettings();

      if (result.isError()) {
        setState(() {
          _errorMessage = '配置加载失败: ${result.exceptionOrNull()}';
          _isLoading = false;
        });
        return;
      }

      appLogger.i('应用初始化完成');
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      appLogger.e('应用初始化失败', error: e);
      setState(() {
        _errorMessage = '应用初始化失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果正在加载，显示加载界面
    if (_isLoading) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在加载应用配置...'),
              ],
            ),
          ),
        ),
      );
    }

    // 如果加载失败，显示错误界面
    if (_errorMessage != null) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: Scaffold(
          body: ErrorPage.unknownError(
            message: '应用初始化失败',
            description: _errorMessage!,
            buttonText: '重试',
            onBack: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _initializeApp();
            },
            error: Exception(_errorMessage!),
          ),
        ),
      );
    }

    // 正常显示应用
    return Consumer<MainAppViewModel>(
      builder: (context, viewModel, child) {
        return MaterialApp.router(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: viewModel.themeMode,
          routerConfig: routerStore,
          scaffoldMessengerKey: globalScaffoldMessengerKey,
        );
      },
    );
  }
}
