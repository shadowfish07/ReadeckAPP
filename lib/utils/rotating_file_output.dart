import 'dart:io';
import 'package:logger/logger.dart';

/// 日志轮转输出类
///
/// 实现日志文件的自动轮转功能，当日志文件大小超过限制时，
/// 会自动创建新的日志文件并保留指定数量的历史文件。
class RotatingFileOutput extends LogOutput {
  final String basePath;
  final int maxFileSize; // 字节
  final int maxFiles;

  RotatingFileOutput({
    required this.basePath,
    this.maxFileSize = 2 * 1024 * 1024, // 默认2MB
    this.maxFiles = 5, // 默认保留5个文件
  });

  @override
  void output(OutputEvent event) {
    try {
      final currentFile = File('$basePath/readeck_app.log');

      // 检查文件大小，如果超过限制则轮转
      if (currentFile.existsSync() && currentFile.lengthSync() > maxFileSize) {
        _rotateFiles();
      }

      // 写入日志
      final timestamp = DateTime.now().toIso8601String();
      final logEntry =
          event.lines.map((line) => '[$timestamp] $line').join('\n');
      currentFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
    } catch (e) {
      // 如果写入文件失败，忽略错误以避免影响应用运行
    }
  }

  void _rotateFiles() {
    try {
      // 删除最老的文件
      final oldestFile = File('$basePath/readeck_app.log.${maxFiles - 1}');
      if (oldestFile.existsSync()) {
        oldestFile.deleteSync();
      }

      // 重命名现有文件
      for (int i = maxFiles - 2; i >= 0; i--) {
        final sourceFile = i == 0
            ? File('$basePath/readeck_app.log')
            : File('$basePath/readeck_app.log.$i');

        if (sourceFile.existsSync()) {
          sourceFile.renameSync('$basePath/readeck_app.log.${i + 1}');
        }
      }
    } catch (e) {
      // 轮转失败时忽略错误，继续写入当前文件
    }
  }
}
