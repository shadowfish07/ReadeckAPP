import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/daily_read_history/daily_read_history_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/main.dart';
import 'package:result_dart/result_dart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../utils/log_manager.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(
      this._settingsRepository, this._dailyReadHistoryRepository) {
    // 主题切换时整个页面都会重建，这里就不用监听了
    _initializeThemeMode();
    setThemeMode = Command.createAsyncNoResult<ThemeMode>(_setThemeMode);
    exportLogs = Command.createAsyncNoResult<void>(_exportLogs);
    clearOldLogs = Command.createAsyncNoResult<void>(_clearOldLogs);
    clearAllLogs = Command.createAsyncNoResult<void>(_clearAllLogs);
  }
  final SettingsRepository _settingsRepository;
  final DailyReadHistoryRepository _dailyReadHistoryRepository;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  late Command setThemeMode;
  late Command exportLogs;
  late Command clearOldLogs;
  late Command clearAllLogs;

  void _initializeThemeMode() {
    // 由于SettingsRepository已经预加载，直接同步获取主题模式
    final themeModeIndex = _settingsRepository.getThemeMode();
    _themeMode = ThemeMode.values[themeModeIndex];
    notifyListeners();
  }

  AsyncResult<void> _setThemeMode(ThemeMode themeMode) async {
    try {
      final result = await _settingsRepository.saveThemeMode(themeMode.index);
      if (result.isSuccess()) {
        _themeMode = themeMode;
        notifyListeners();
        return const Success(unit);
      } else {
        return Failure(result.exceptionOrNull()!);
      }
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
      final logDir = Directory('${directory.path}/logs');
      final exportLogFile = File(
          '${directory.path}/readeck_app_export_${DateTime.now().millisecondsSinceEpoch}.txt');

      // 创建导出日志内容
      final logContent = StringBuffer();
      logContent.writeln('ReadeckApp 日志导出（最近日志）');
      logContent.writeln('导出时间: ${DateTime.now().toIso8601String()}');
      logContent.writeln('=' * 50);
      logContent.writeln();

      // 添加应用基本信息
      logContent.writeln('应用信息:');
      logContent.writeln('- 主题模式: ${_getThemeModeText(_themeMode)}');
      logContent.writeln('- 导出时间: ${DateTime.now()}');
      logContent.writeln();

      // 读取并添加轮转日志文件内容
      logContent.writeln('应用日志:');
      logContent.writeln('-' * 50);

      if (logDir.existsSync()) {
        // 获取所有日志文件
        final logFiles = logDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.contains('readeck_app.log'))
            .toList();

        if (logFiles.isNotEmpty) {
          // 按修改时间排序，取最新的2个文件
          logFiles.sort(
              (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
          final recentFiles = logFiles.take(2).toList();

          for (final file in recentFiles) {
            logContent.writeln('\n文件: ${file.path.split('/').last}');
            logContent.writeln('修改时间: ${file.lastModifiedSync()}');
            logContent.writeln(
                '文件大小: ${(file.lengthSync() / 1024).toStringAsFixed(1)} KB');
            logContent.writeln('-' * 30);

            try {
              final content = await file.readAsString();
              if (content.isNotEmpty) {
                // 过滤敏感信息
                final filteredContent = _filterSensitiveInfo(content);
                logContent.writeln(filteredContent);
              } else {
                logContent.writeln('文件为空');
              }
            } catch (e) {
              logContent.writeln('读取文件失败: $e');
            }
          }
        } else {
          logContent.writeln('未找到日志文件');
        }
      } else {
        logContent.writeln('日志目录不存在（可能是首次运行或调试模式）');
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

  /// 清理旧日志（保留30天）
  AsyncResult<void> _clearOldLogs(void _) async {
    final result = await LogManager.clearOldLogs(daysToKeep: 30);
    if (result.isSuccess()) {
      return const Success(unit);
    } else {
      return Failure(result.exceptionOrNull()!);
    }
  }

  /// 清理所有日志（调试用）
  AsyncResult<void> _clearAllLogs(void _) async {
    final result = await LogManager.clearAllLogs();
    if (result.isSuccess()) {
      return const Success(unit);
    } else {
      return Failure(result.exceptionOrNull()!);
    }
  }

  /// 过滤敏感信息
  String _filterSensitiveInfo(String content) {
    return content
        .replaceAll(
            RegExp(r'token["\s]*[:=]["\s]*[\w\-\.]+', caseSensitive: false),
            'token: [FILTERED]')
        .replaceAll(
            RegExp(r'password["\s]*[:=]["\s]*\w+', caseSensitive: false),
            'password: [FILTERED]')
        .replaceAll(
            RegExp(r'api[_\s]*key["\s]*[:=]["\s]*[\w\-\.]+',
                caseSensitive: false),
            'api_key: [FILTERED]')
        .replaceAll(
            RegExp(r'authorization["\s]*[:=]["\s]*[\w\-\.]+',
                caseSensitive: false),
            'authorization: [FILTERED]');
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
