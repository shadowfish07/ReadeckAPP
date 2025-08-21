import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:readeck_app/data/service/download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('DownloadService', () {
    late DownloadService service;

    setUp(() {
      service = DownloadService();
    });

    group('Exception Handling', () {
      test('DownloadException should format message correctly', () {
        const message = 'Test download error';
        final exception = DownloadException(message);

        expect(exception.message, message);
        expect(exception.toString(), 'DownloadException: $message');
      });
    });

    group('File Existence Tests', () {
      test('fileExists should return true for existing file', () async {
        // 创建临时文件
        final tempFile = File('${Directory.systemTemp.path}/test_existing.txt');
        await tempFile.writeAsString('test');

        final exists = await service.fileExists(tempFile.path);
        expect(exists, true);

        // 清理
        await tempFile.delete();
      });

      test('fileExists should return false for non-existing file', () async {
        const nonExistentFile = '/non/existent/file.txt';
        final exists = await service.fileExists(nonExistentFile);
        expect(exists, false);
      });

      test('fileExists should return false on exception', () async {
        // 使用无效路径导致异常
        const invalidPath = '';
        final exists = await service.fileExists(invalidPath);
        expect(exists, false);
      });
    });

    group('Error Handling Tests', () {
      test('downloadFile should handle invalid URL gracefully', () async {
        const url = 'invalid-url';
        const fileName = 'test.apk';

        final result = await service.downloadFile(url, fileName);
        expect(result.isError(), true);

        final exception = result.exceptionOrNull() as DownloadException;
        expect(exception, isA<DownloadException>());
        expect(exception.message, contains('下载失败'));
      });

      test('downloadFile should handle network error gracefully', () async {
        // 使用不存在的域名测试网络错误
        const url = 'https://nonexistent-domain-12345.com/file.apk';
        const fileName = 'test.apk';

        final result = await service.downloadFile(url, fileName);
        expect(result.isError(), true);

        final exception = result.exceptionOrNull() as DownloadException;
        expect(exception, isA<DownloadException>());
      });
    });

    group('Progress Callback Tests', () {
      test('downloadFile with progress callback should not throw', () async {
        const url = 'https://nonexistent-domain.com/file.apk';
        const fileName = 'test.apk';

        var progressCalled = false;

        final result = await service.downloadFile(
          url,
          fileName,
          onProgress: (received, total) {
            progressCalled = true;
          },
        );

        // 即使下载失败，也不应该因为回调而抛出异常
        expect(result.isError(), true);
        // 因为是网络错误，进度回调不会被调用
        expect(progressCalled, false);
      });
    });

    group('Boundary Tests', () {
      test('downloadFile should handle empty URL', () async {
        const url = '';
        const fileName = 'test.apk';

        final result = await service.downloadFile(url, fileName);
        expect(result.isError(), true);
      });

      test('downloadFile should handle empty filename', () async {
        const url = 'https://example.com/file.apk';
        const fileName = '';

        final result = await service.downloadFile(url, fileName);
        expect(result.isError(), true);
      });

      test('downloadFile should handle null progress callback', () async {
        const url = 'https://nonexistent-domain.com/file.apk';
        const fileName = 'test.apv';

        // 不传递进度回调，应该正常处理
        final result = await service.downloadFile(url, fileName);
        expect(result.isError(), true);
      });
    });

    group('File Size Tests', () {
      test('getFileSize should handle network error gracefully', () async {
        const url = 'https://nonexistent-domain.com/file.apk';

        final size = await service.getFileSize(url);
        expect(size, 0); // 网络错误应该返回0
      });

      test('getFileSize should handle invalid URL', () async {
        const url = 'invalid-url';

        final size = await service.getFileSize(url);
        expect(size, 0);
      });

      test('getFileSize should handle empty URL', () async {
        const url = '';

        final size = await service.getFileSize(url);
        expect(size, 0);
      });
    });

    group('Integration Tests', () {
      test('service should be instantiable without parameters', () {
        final defaultService = DownloadService();
        expect(defaultService, isNotNull);
      });

      test('multiple instances should work independently', () {
        final service1 = DownloadService();
        final service2 = DownloadService();

        expect(service1, isNotNull);
        expect(service2, isNotNull);
        expect(identical(service1, service2), false);
      });
    });
  });
}
