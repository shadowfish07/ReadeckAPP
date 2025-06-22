import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'config/dependencies.dart';
import 'data/service/shared_preference_service.dart';
import 'routing/router.dart';
import 'ui/core/theme.dart';
import 'main_viewmodel.dart';

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
      final logFile = File('${directory.path}/readeck_app_logs.txt');

      appLogger = Logger(
        output: MultiOutput([
          ConsoleOutput(), // 仍然输出到控制台（在某些情况下有用）
          FileOutput(file: logFile), // 输出到文件
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

/// 自定义文件输出器
class FileOutput extends LogOutput {
  final File file;

  FileOutput({required this.file});

  @override
  void output(OutputEvent event) {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final logEntry =
          event.lines.map((line) => '[$timestamp] $line').join('\n');
      file.writeAsStringSync('$logEntry\n', mode: FileMode.append);
    } catch (e) {
      // 如果写入文件失败，忽略错误以避免影响应用运行
    }
  }
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
