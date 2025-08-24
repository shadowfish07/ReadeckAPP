import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:readeck_app/main.dart' show appLogger;

// 重新导出 appLogger，以便测试文件可以访问
export 'package:readeck_app/main.dart' show appLogger;

/// 测试专用的日志缓冲输出器
/// 只在测试失败时才将日志输出到控制台
class TestLoggerBuffer extends LogOutput {
  final List<String> _buffer = [];
  bool _testFailed = false;

  @override
  void output(OutputEvent event) {
    // 将日志缓存到内存中，使用最简单的格式
    for (var line in event.lines) {
      _buffer.add(line);
    }
  }

  /// 标记测试失败，将缓冲的日志输出到控制台
  void markTestFailed() {
    if (!_testFailed && _buffer.isNotEmpty) {
      _testFailed = true;
      // ignore: avoid_print
      print('\n--- Test Failed - Logger Output ---');
      for (var line in _buffer) {
        // ignore: avoid_print
        print(line);
      }
      // ignore: avoid_print
      print('--- End Logger Output ---\n');
    }
  }

  /// 清空缓冲区（测试成功时调用）
  void clear() {
    _buffer.clear();
    _testFailed = false;
  }

  /// 获取当前缓冲的日志数量
  int get bufferSize => _buffer.length;
}

/// 测试专用的简单日志打印器
class SimpleTestPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final level = event.level.name.toUpperCase();
    final message = event.message.toString();

    // 如果有异常，也包含在内
    if (event.error != null) {
      return ['[$level] $message: ${event.error}'];
    }

    return ['[$level] $message'];
  }
}

/// 全局的测试日志缓冲器实例
final TestLoggerBuffer _testLoggerBuffer = TestLoggerBuffer();

/// 配置测试专用的 appLogger
void setupTestLogger({Level level = Level.warning}) {
  appLogger = Logger(
    printer: SimpleTestPrinter(),
    output: _testLoggerBuffer,
    level: level,
  );
}

/// 测试成功时调用，清空日志缓冲区
void clearTestLogs() {
  _testLoggerBuffer.clear();
}

/// 测试失败时调用，输出缓冲的日志
void flushTestLogsOnFailure() {
  _testLoggerBuffer.markTestFailed();
}

/// 获取当前缓冲的日志数量（用于调试）
int getTestLogBufferSize() {
  return _testLoggerBuffer.bufferSize;
}

/// 为测试组设置日志处理
/// 在 group() 的 setUp() 中使用
void setupTestGroupLogging({Level level = Level.warning}) {
  setUp(() {
    setupTestLogger(level: level);
  });
}

/// 包装测试方法，自动处理日志输出
void testWithLogging(String description, dynamic Function() body) {
  test(description, () async {
    try {
      await body();
      // 测试成功，清空日志
      clearTestLogs();
    } catch (e) {
      // 测试失败，输出日志
      flushTestLogsOnFailure();
      rethrow;
    }
  });
}

/// 包装异步测试方法，自动处理日志输出
void testAsyncWithLogging(String description, Future<void> Function() body) {
  test(description, () async {
    try {
      await body();
      // 测试成功，清空日志
      clearTestLogs();
    } catch (e) {
      // 测试失败，输出日志
      flushTestLogsOnFailure();
      rethrow;
    }
  });
}
