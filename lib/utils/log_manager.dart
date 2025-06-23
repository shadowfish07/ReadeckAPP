import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:result_dart/result_dart.dart';
import '../main.dart';

/// 日志管理工具类
class LogManager {
  /// 清理超过指定天数的旧日志文件
  static Future<Result<void>> clearOldLogs({int daysToKeep = 30}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (!logDir.existsSync()) {
        return const Success(unit);
      }

      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final files = logDir.listSync().whereType<File>();
      int deletedCount = 0;

      for (final file in files) {
        if (file.lastModifiedSync().isBefore(cutoffDate)) {
          try {
            file.deleteSync();
            deletedCount++;
          } catch (e) {
            appLogger.w('删除日志文件失败: ${file.path}, 错误: $e');
          }
        }
      }

      appLogger.i('清理旧日志完成，删除了 $deletedCount 个文件');
      return const Success(unit);
    } catch (e) {
      appLogger.e('清理旧日志失败: $e');
      return Failure(Exception('清理旧日志失败: $e'));
    }
  }

  /// 获取日志目录大小（MB）
  static Future<Result<double>> getLogDirectorySize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (!logDir.existsSync()) {
        return const Success(0.0);
      }

      int totalSize = 0;
      final files = logDir.listSync().whereType<File>();

      for (final file in files) {
        totalSize += file.lengthSync();
      }

      final sizeInMB = totalSize / (1024 * 1024);
      return Success(sizeInMB);
    } catch (e) {
      appLogger.e('获取日志目录大小失败: $e');
      return Failure(Exception('获取日志目录大小失败: $e'));
    }
  }

  /// 获取日志文件列表信息
  static Future<Result<List<LogFileInfo>>> getLogFilesList() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (!logDir.existsSync()) {
        return const Success([]);
      }

      final files = logDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('readeck_app.log'))
          .toList();

      final logFiles = files.map((file) {
        return LogFileInfo(
          name: file.path.split('/').last,
          path: file.path,
          size: file.lengthSync(),
          lastModified: file.lastModifiedSync(),
        );
      }).toList();

      // 按修改时间排序，最新的在前
      logFiles.sort((a, b) => b.lastModified.compareTo(a.lastModified));

      return Success(logFiles);
    } catch (e) {
      appLogger.e('获取日志文件列表失败: $e');
      return Failure(Exception('获取日志文件列表失败: $e'));
    }
  }

  /// 清理所有日志文件（调试用）
  static Future<Result<void>> clearAllLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (!logDir.existsSync()) {
        return const Success(unit);
      }

      final files = logDir.listSync().whereType<File>();
      int deletedCount = 0;

      for (final file in files) {
        try {
          file.deleteSync();
          deletedCount++;
        } catch (e) {
          appLogger.w('删除日志文件失败: ${file.path}, 错误: $e');
        }
      }

      appLogger.i('清理所有日志完成，删除了 $deletedCount 个文件');
      return const Success(unit);
    } catch (e) {
      appLogger.e('清理所有日志失败: $e');
      return Failure(Exception('清理所有日志失败: $e'));
    }
  }
}

/// 日志文件信息
class LogFileInfo {
  final String name;
  final String path;
  final int size;
  final DateTime lastModified;

  const LogFileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.lastModified,
  });

  /// 获取文件大小（KB）
  double get sizeInKB => size / 1024;

  /// 获取文件大小（MB）
  double get sizeInMB => size / (1024 * 1024);
}
