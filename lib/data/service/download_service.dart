import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:result_dart/result_dart.dart';
import 'package:logger/logger.dart';
import '../../main.dart';

class DownloadService {
  final Dio _dio;
  final Logger _logger;

  DownloadService({Dio? dio, Logger? logger})
      : _dio = dio ?? Dio(),
        _logger = logger ?? appLogger;

  /// 下载文件到应用程序目录
  /// [url] 下载链接
  /// [fileName] 保存的文件名
  /// [onProgress] 下载进度回调 (已下载字节数, 总字节数)
  Future<Result<String>> downloadFile(
    String url,
    String fileName, {
    Function(int received, int total)? onProgress,
  }) async {
    try {
      _logger.i('开始下载文件: $url');

      // 获取应用程序下载目录
      final directory = await getApplicationDocumentsDirectory();
      final downloadDirectory = Directory('${directory.path}/downloads');

      // 确保下载目录存在
      if (!await downloadDirectory.exists()) {
        await downloadDirectory.create(recursive: true);
      }

      final filePath = '${downloadDirectory.path}/$fileName';
      _logger.i('目标文件路径: $filePath');

      // 如果文件已存在，删除旧文件
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        _logger.i('删除已存在的文件: $filePath');
      }

      // 开始下载
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          onProgress?.call(received, total);
          if (total > 0) {
            final progress = (received / total * 100).toStringAsFixed(1);
            _logger.d('下载进度: $progress% ($received/$total 字节)');
          }
        },
      );

      // 简单验证下载的文件是否存在且不为空
      if (!await file.exists()) {
        _logger.e('下载完成但文件不存在: $filePath');
        return Failure(DownloadException('下载失败：文件未创建'));
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        _logger.e('下载的文件为空: $filePath');
        await file.delete();
        return Failure(DownloadException('下载失败：文件为空'));
      }

      _logger.i('文件下载完成: $filePath (大小: $fileSize 字节)');
      return Success(filePath);
    } catch (e, stackTrace) {
      _logger.e('文件下载失败', error: e, stackTrace: stackTrace);
      return Failure(DownloadException('下载失败: ${e.toString()}'));
    }
  }

  /// 检查文件是否存在
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      _logger.w('检查文件存在性失败: $e');
      return false;
    }
  }

  /// 获取文件大小
  Future<int> getFileSize(String url) async {
    try {
      final response = await _dio.head(url);
      final contentLength = response.headers.value('content-length');
      return contentLength != null ? int.parse(contentLength) : 0;
    } catch (e) {
      _logger.w('获取文件大小失败: $e');
      return 0;
    }
  }
}

class DownloadException implements Exception {
  final String message;

  DownloadException(this.message);

  @override
  String toString() => 'DownloadException: $message';
}
