import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:readeck_app/data/service/app_installer_service.dart';

void main() {
  group('AppInstallerService', () {
    late AppInstallerService service;

    setUp(() {
      service = AppInstallerService(logger: Logger());
    });

    group('Platform Support Tests', () {
      test('should return correct file extension for current platform', () {
        final extension = service.getInstallFileExtension();

        if (Platform.isAndroid) {
          expect(extension, 'apk');
        } else if (Platform.isIOS) {
          expect(extension, 'ipa');
        } else if (Platform.isMacOS) {
          expect(extension, 'dmg');
        } else if (Platform.isWindows) {
          expect(extension, 'exe');
        } else if (Platform.isLinux) {
          expect(extension, 'deb');
        } else {
          expect(extension, 'unknown');
        }
      });

      test('should support Android platform correctly', () {
        final isSupported = service.isSupportedPlatform();
        expect(isSupported, Platform.isAndroid);
      });
    });

    group('Exception Handling', () {
      test('InstallException should format message correctly', () {
        const message = 'Test error message';
        final exception = InstallException(message);

        expect(exception.message, message);
        expect(exception.toString(), 'InstallException: $message');
      });
    });

    group('Platform-specific Error Tests', () {
      test('installApk should fail on non-Android platforms', () async {
        if (!Platform.isAndroid) {
          final result = await service.installApk('/fake/path.apk');

          expect(result.isError(), true);
          final exception = result.exceptionOrNull() as InstallException;
          expect(exception, isA<InstallException>());
          expect(exception.message, contains('当前平台不支持APK安装'));
        }
      });

      test('should return false for install permission check on non-Android',
          () async {
        if (!Platform.isAndroid) {
          final hasPermission = await service.hasInstallPermission();
          expect(hasPermission, false);
        }
      });

      test('should return false for request install permission on non-Android',
          () async {
        if (!Platform.isAndroid) {
          final granted = await service.requestInstallPermission();
          expect(granted, false);
        }
      });
    });

    group('Android-specific Tests', () {
      testWidgets('installApk should check file existence', (tester) async {
        if (!Platform.isAndroid) {
          return; // 跳过非Android平台的测试
        }

        const nonExistentFile = '/non/existent/file.apk';
        final result = await service.installApk(nonExistentFile);

        expect(result.isError(), true);
        final exception = result.exceptionOrNull() as InstallException;
        expect(exception, isA<InstallException>());
        expect(exception.message, contains('APK文件不存在'));
      });

      test('should handle file size validation', () async {
        if (!Platform.isAndroid) {
          return;
        }

        // 创建一个非常小的临时文件来测试文件大小验证
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/tiny_test.apk');

        try {
          await tempFile.writeAsString('x'); // 写入一个字符，文件大小会小于1KB

          final result = await service.installApk(tempFile.path);

          expect(result.isError(), true);
          final exception = result.exceptionOrNull() as InstallException;
          expect(exception, isA<InstallException>());
          expect(exception.message, contains('APK文件太小'));
        } finally {
          // 清理临时文件
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      });
    }, skip: !Platform.isAndroid);

    group('Permission Tests', () {
      test('should handle permission check gracefully', () async {
        // 测试权限检查不会抛出异常
        expect(
            () async => await service.hasInstallPermission(), returnsNormally);
      });

      test('should handle permission request gracefully', () async {
        // 测试权限请求不会抛出异常
        expect(() async => await service.requestInstallPermission(),
            returnsNormally);
      });
    });

    group('Boundary Tests', () {
      test('should handle empty file path gracefully', () async {
        if (!Platform.isAndroid) {
          return;
        }

        final result = await service.installApk('');
        expect(result.isError(), true);
      });
    });
  });
}
