import 'dart:io';
import 'package:result_dart/result_dart.dart';
import 'package:logger/logger.dart';
import '../../data/service/download_service.dart';
import '../../data/service/app_installer_service.dart';
import '../../data/service/update_service.dart';

class AppUpdateUseCase {
  final DownloadService _downloadService;
  final AppInstallerService _installerService;
  final Logger _logger;

  AppUpdateUseCase({
    required DownloadService downloadService,
    required AppInstallerService installerService,
    Logger? logger,
  })  : _downloadService = downloadService,
        _installerService = installerService,
        _logger = logger ?? Logger();

  /// 下载并安装应用更新
  /// [updateInfo] 更新信息
  /// [onProgress] 下载进度回调 (已下载字节数, 总字节数)
  Future<Result<void>> downloadAndInstallUpdate(
    UpdateInfo updateInfo, {
    Function(int received, int total)? onProgress,
  }) async {
    try {
      _logger.i('开始应用更新流程，版本: ${updateInfo.version}');

      // 检查当前平台是否支持自动安装
      if (!_installerService.isSupportedPlatform()) {
        return Failure(AppUpdateException('当前平台不支持自动安装更新'));
      }

      // 检查是否有安装权限，如果没有则尝试请求
      final hasInstallPermission =
          await _installerService.hasInstallPermission();
      if (!hasInstallPermission) {
        _logger.w('没有安装权限，尝试请求权限');
        // 尝试请求权限，该方法内部会处理权限请求
        final permissionGranted =
            await _installerService.requestInstallPermission();
        if (!permissionGranted) {
          return Failure(
              AppUpdateException('需要安装权限才能自动更新应用。请在设置中授权"安装未知应用"权限。'));
        }
        _logger.i('安装权限请求成功');
      }

      // 生成文件名
      final fileExtension = _installerService.getInstallFileExtension();
      final fileName = 'readeck_app_${updateInfo.version}.$fileExtension';

      _logger.i('开始下载更新文件: $fileName');

      // 下载更新文件
      final downloadResult = await _downloadService.downloadFile(
        updateInfo.downloadUrl,
        fileName,
        onProgress: onProgress,
      );

      if (downloadResult.isError()) {
        final error = downloadResult.exceptionOrNull()!;
        _logger.e('下载更新文件失败: $error');
        return Failure(AppUpdateException('下载更新文件失败: ${error.toString()}'));
      }

      final filePath = downloadResult.getOrNull()!;
      _logger.i('更新文件下载完成: $filePath');

      // 安装更新（目前只支持Android APK）
      if (Platform.isAndroid) {
        _logger.i('开始安装APK');
        final installResult = await _installerService.installApk(filePath);

        if (installResult.isError()) {
          final error = installResult.exceptionOrNull()!;
          _logger.e('安装APK失败: $error');
          return Failure(AppUpdateException('安装失败: ${error.toString()}'));
        }

        _logger.i('APK安装成功');
        return const Success(());
      } else {
        // 其他平台的处理逻辑可以在这里添加
        return Failure(AppUpdateException('当前平台尚不支持自动安装'));
      }
    } catch (e, stackTrace) {
      _logger.e('应用更新失败', error: e, stackTrace: stackTrace);
      return Failure(AppUpdateException('应用更新失败: ${e.toString()}'));
    }
  }

  /// 仅下载更新文件（不安装）
  /// [updateInfo] 更新信息
  /// [onProgress] 下载进度回调 (已下载字节数, 总字节数)
  Future<Result<String>> downloadUpdate(
    UpdateInfo updateInfo, {
    Function(int received, int total)? onProgress,
  }) async {
    try {
      _logger.i('开始下载应用更新文件，版本: ${updateInfo.version}');

      // 生成文件名
      final fileExtension = _installerService.getInstallFileExtension();
      final fileName = 'readeck_app_${updateInfo.version}.$fileExtension';

      // 下载更新文件
      final downloadResult = await _downloadService.downloadFile(
        updateInfo.downloadUrl,
        fileName,
        onProgress: onProgress,
      );

      if (downloadResult.isError()) {
        _logger.e('下载更新文件失败');
        return Failure(downloadResult.exceptionOrNull()!);
      }

      final filePath = downloadResult.getOrNull()!;
      _logger.i('更新文件下载完成: $filePath');

      return Success(filePath);
    } catch (e, stackTrace) {
      _logger.e('下载应用更新文件失败', error: e, stackTrace: stackTrace);
      return Failure(AppUpdateException('下载更新文件失败: ${e.toString()}'));
    }
  }

  /// 安装已下载的更新文件
  /// [filePath] 更新文件路径
  Future<Result<void>> installUpdate(String filePath) async {
    try {
      _logger.i('开始安装更新文件: $filePath');

      // 检查文件是否存在
      final fileExists = await _downloadService.fileExists(filePath);
      if (!fileExists) {
        return Failure(AppUpdateException('更新文件不存在: $filePath'));
      }

      // 检查当前平台是否支持自动安装
      if (!_installerService.isSupportedPlatform()) {
        return Failure(AppUpdateException('当前平台不支持自动安装更新'));
      }

      // 检查是否有安装权限，如果没有则尝试请求
      final hasInstallPermission =
          await _installerService.hasInstallPermission();
      if (!hasInstallPermission) {
        _logger.w('没有安装权限，尝试请求权限');
        // 尝试请求权限
        final permissionGranted =
            await _installerService.requestInstallPermission();
        if (!permissionGranted) {
          return Failure(
              AppUpdateException('需要安装权限才能自动更新应用。请在设置中授权"安装未知应用"权限。'));
        }
        _logger.i('安装权限请求成功');
      }

      // 安装更新
      if (Platform.isAndroid) {
        final installResult = await _installerService.installApk(filePath);

        if (installResult.isError()) {
          _logger.e('安装APK失败');
          return Failure(installResult.exceptionOrNull()!);
        }

        _logger.i('APK安装成功');
        return const Success(());
      } else {
        return Failure(AppUpdateException('当前平台尚不支持自动安装'));
      }
    } catch (e, stackTrace) {
      _logger.e('安装更新失败', error: e, stackTrace: stackTrace);
      return Failure(AppUpdateException('安装更新失败: ${e.toString()}'));
    }
  }

  /// 获取更新文件大小
  /// [updateInfo] 更新信息
  Future<int> getUpdateFileSize(UpdateInfo updateInfo) async {
    try {
      return await _downloadService.getFileSize(updateInfo.downloadUrl);
    } catch (e) {
      _logger.w('获取更新文件大小失败: $e');
      return 0;
    }
  }
}

class AppUpdateException implements Exception {
  final String message;

  AppUpdateException(this.message);

  @override
  String toString() => 'AppUpdateException: $message';
}
