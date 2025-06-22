import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/daily_read_history/daily_read_history_repository.dart';
import 'package:readeck_app/data/repository/theme/theme_repository.dart';
import 'package:readeck_app/main.dart';
import 'package:result_dart/result_dart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._themeRepository, this._dailyReadHistoryRepository) {
    // 主题切换时整个页面都会重建，这里就不用监听了
    _initializeThemeMode();
    setThemeMode = Command.createAsyncNoResult<ThemeMode>(_setThemeMode);
    exportLogs = Command.createAsyncNoResult<void>(_exportLogs);
  }
  final ThemeRepository _themeRepository;
  final DailyReadHistoryRepository _dailyReadHistoryRepository;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  late Command setThemeMode;
  late Command exportLogs;

  Future<void> _initializeThemeMode() async {
    final result = await _themeRepository.getThemeMode();
    if (result.isSuccess()) {
      _themeMode = result.getOrNull()!;
      notifyListeners();
    }
  }

  AsyncResult<void> _setThemeMode(ThemeMode themeMode) async {
    try {
      await _themeRepository.setThemeMode(themeMode);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  AsyncResult<void> clearAllDataForDebug() async {
    return _dailyReadHistoryRepository.clearAllDataForDebug();
  }

  AsyncResult<void> _exportLogs(void _) async {
    try {
      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final originalLogFile = File('${directory.path}/readeck_app_logs.txt');
      final exportLogFile = File(
          '${directory.path}/readeck_app_export_${DateTime.now().millisecondsSinceEpoch}.txt');

      // 创建导出日志内容
      final logContent = StringBuffer();
      logContent.writeln('ReadeckApp 日志导出');
      logContent.writeln('导出时间: ${DateTime.now().toIso8601String()}');
      logContent.writeln('=' * 50);
      logContent.writeln();

      // 添加应用基本信息
      logContent.writeln('应用信息:');
      logContent.writeln('- 主题模式: ${_getThemeModeText(_themeMode)}');
      logContent.writeln('- 导出时间: ${DateTime.now()}');
      logContent.writeln();

      // 读取并添加实际的日志文件内容
      logContent.writeln('应用日志:');
      logContent.writeln('-' * 50);

      if (await originalLogFile.exists()) {
        try {
          final logFileContent = await originalLogFile.readAsString();
          if (logFileContent.isNotEmpty) {
            logContent.writeln(logFileContent);
          } else {
            logContent.writeln('日志文件为空');
          }
        } catch (e) {
          logContent.writeln('读取日志文件失败: $e');
        }
      } else {
        logContent.writeln('日志文件不存在（可能是首次运行或调试模式）');
        logContent.writeln('注意: 在调试模式下，日志只输出到控制台，不会保存到文件');
      }

      logContent.writeln();
      logContent.writeln('-' * 50);
      logContent.writeln('导出完成');

      // 写入导出文件
      await exportLogFile.writeAsString(logContent.toString());

      // 分享文件
      await Share.shareXFiles(
        [XFile(exportLogFile.path)],
        text: 'ReadeckApp 日志文件',
        subject: 'ReadeckApp 日志导出 - ${DateTime.now().toIso8601String()}',
      );

      return const Success(unit);
    } on Exception catch (e) {
      appLogger.e('导出日志失败: $e');
      rethrow;
    }
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }
}
