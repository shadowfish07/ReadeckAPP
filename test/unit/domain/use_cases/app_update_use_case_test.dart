import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:readeck_app/data/service/app_installer_service.dart';
import 'package:readeck_app/data/service/download_service.dart';
import 'package:readeck_app/domain/models/update/update_info.dart';
import 'package:readeck_app/domain/use_cases/app_update_use_case.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AppUpdateUseCase', () {
    late AppUpdateUseCase useCase;
    late UpdateInfo testUpdateInfo;

    setUp(() {
      // Create a mock logger for testing to avoid appLogger dependency
      final mockLogger = Logger(
        printer: PrettyPrinter(),
        output: null, // Don't output during tests
      );

      final downloadService = DownloadService(logger: mockLogger);
      final installerService = AppInstallerService(logger: mockLogger);

      useCase = AppUpdateUseCase(
        downloadService: downloadService,
        installerService: installerService,
        logger: mockLogger,
      );

      testUpdateInfo = UpdateInfo(
        version: '1.0.1',
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: 'Test release',
        htmlUrl: 'https://example.com/release',
      );
    });

    group('Exception Handling', () {
      test('AppUpdateException should format message correctly', () {
        const message = 'Test update error';
        final exception = AppUpdateException(message);

        expect(exception.message, message);
        expect(exception.toString(), 'AppUpdateException: $message');
      });
    });

    group('Basic Functionality Tests', () {
      test('useCase should be instantiable', () {
        expect(useCase, isNotNull);
      });

      test('getUpdateFileSize should handle network error gracefully',
          () async {
        // 使用无效URL测试错误处理
        final invalidUpdateInfo = UpdateInfo(
          version: '1.0.1',
          downloadUrl: 'https://nonexistent-domain-12345.com/app.apk',
          releaseNotes: 'Test release',
          htmlUrl: 'https://example.com/release',
        );

        final size = await useCase.getUpdateFileSize(invalidUpdateInfo);

        // 网络错误应该返回0
        expect(size, 0);
      });

      test('downloadUpdate should handle network error', () async {
        // 使用无效URL测试下载错误处理
        final invalidUpdateInfo = UpdateInfo(
          version: '1.0.1',
          downloadUrl: 'https://nonexistent-domain-12345.com/app.apk',
          releaseNotes: 'Test release',
          htmlUrl: 'https://example.com/release',
        );

        final result = await useCase.downloadUpdate(invalidUpdateInfo);

        expect(result.isError(), true);
        expect(result.exceptionOrNull(), isA<DownloadException>());
      });

      test('downloadUpdate should pass progress callback correctly', () async {
        var progressCalled = false;

        // 使用无效URL，但验证进度回调不会导致崩溃
        final result = await useCase.downloadUpdate(
          testUpdateInfo,
          onProgress: (received, total) {
            progressCalled = true;
          },
        );

        // 下载应该失败，但不应该因为进度回调而崩溃
        expect(result.isError(), true);
        // 由于网络错误，进度回调不会被调用
        expect(progressCalled, false);
      });
    });

    group('File Validation Tests', () {
      test('installUpdate should handle non-existent file', () async {
        const nonExistentFile = '/non/existent/file.apk';

        final result = await useCase.installUpdate(nonExistentFile);

        expect(result.isError(), true);
        final exception = result.exceptionOrNull() as AppUpdateException;
        expect(exception.message, contains('更新文件不存在'));
      });
    });

    group('Error Handling Tests', () {
      test('downloadAndInstallUpdate should handle invalid URL', () async {
        final invalidUpdateInfo = UpdateInfo(
          version: '1.0.1',
          downloadUrl: 'invalid-url',
          releaseNotes: 'Test release',
          htmlUrl: 'https://example.com/release',
        );

        final result =
            await useCase.downloadAndInstallUpdate(invalidUpdateInfo);

        expect(result.isError(), true);
        final exception = result.exceptionOrNull() as AppUpdateException;
        expect(exception, isA<AppUpdateException>());
      });

      test('downloadAndInstallUpdate should handle empty URL', () async {
        final invalidUpdateInfo = UpdateInfo(
          version: '1.0.1',
          downloadUrl: '',
          releaseNotes: 'Test release',
          htmlUrl: 'https://example.com/release',
        );

        final result =
            await useCase.downloadAndInstallUpdate(invalidUpdateInfo);

        expect(result.isError(), true);
      });

      test('downloadUpdate should handle empty URL', () async {
        final invalidUpdateInfo = UpdateInfo(
          version: '1.0.1',
          downloadUrl: '',
          releaseNotes: 'Test release',
          htmlUrl: 'https://example.com/release',
        );

        final result = await useCase.downloadUpdate(invalidUpdateInfo);

        expect(result.isError(), true);
      });
    });

    group('Progress Callback Tests', () {
      test(
          'downloadAndInstallUpdate should handle progress callback without crash',
          () async {
        final result = await useCase.downloadAndInstallUpdate(
          testUpdateInfo,
          onProgress: (received, total) {
            // 进度回调不应该导致崩溃
          },
        );

        // 应该失败（因为无效URL），但不应该崩溃
        expect(result.isError(), true);
      });
    });

    group('Boundary Tests', () {
      test('should handle UpdateInfo with empty version', () async {
        final updateInfo = UpdateInfo(
          version: '',
          downloadUrl: 'https://example.com/app.apk',
          releaseNotes: 'Test release',
          htmlUrl: 'https://example.com/release',
        );

        final result = await useCase.downloadUpdate(updateInfo);

        // 应该处理空版本号的情况
        expect(result.isError(), true);
      });

      test('should handle UpdateInfo with empty release notes', () async {
        final updateInfo = UpdateInfo(
          version: '1.0.1',
          downloadUrl: 'https://nonexistent-domain.com/app.apk',
          releaseNotes: '',
          htmlUrl: 'https://example.com/release',
        );

        final result = await useCase.downloadUpdate(updateInfo);

        // 应该处理空发布说明的情况
        expect(result.isError(), true);
      });

      test('getUpdateFileSize should handle empty URL', () async {
        final updateInfo = UpdateInfo(
          version: '1.0.1',
          downloadUrl: '',
          releaseNotes: 'Test release',
          htmlUrl: 'https://example.com/release',
        );

        final size = await useCase.getUpdateFileSize(updateInfo);

        // 空URL应该返回0
        expect(size, 0);
      });
    });

    group('Integration Tests', () {
      test('multiple use case instances should work independently', () {
        // Create mock loggers for this test
        final mockLogger1 = Logger(
          printer: PrettyPrinter(),
          output: null, // Don't output during tests
        );
        final mockLogger2 = Logger(
          printer: PrettyPrinter(),
          output: null, // Don't output during tests
        );

        final useCase1 = AppUpdateUseCase(
          downloadService: DownloadService(logger: mockLogger1),
          installerService: AppInstallerService(logger: mockLogger1),
          logger: mockLogger1,
        );

        final useCase2 = AppUpdateUseCase(
          downloadService: DownloadService(logger: mockLogger2),
          installerService: AppInstallerService(logger: mockLogger2),
          logger: mockLogger2,
        );

        expect(useCase1, isNotNull);
        expect(useCase2, isNotNull);
        expect(identical(useCase1, useCase2), false);
      });
    });
  });
}
