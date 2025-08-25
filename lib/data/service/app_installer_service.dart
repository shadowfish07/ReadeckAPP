import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:result_dart/result_dart.dart';
import 'package:logger/logger.dart';
import '../../main.dart';

class AppInstallerService {
  final Logger _logger;

  AppInstallerService({Logger? logger}) : _logger = logger ?? appLogger;

  /// 安装APK文件
  /// [filePath] APK文件路径
  Future<Result<void>> installApk(String filePath) async {
    try {
      if (!Platform.isAndroid) {
        return Failure(InstallException('当前平台不支持APK安装'));
      }

      _logger.i('开始安装APK: $filePath');

      // 简单检查文件是否存在
      final file = File(filePath);
      if (!await file.exists()) {
        return Failure(InstallException('APK文件不存在: $filePath'));
      }

      final fileSize = await file.length();
      _logger.i('APK文件大小: $fileSize 字节');

      if (fileSize < 1024) {
        // 小于1KB的文件肯定不是正常的APK
        return Failure(InstallException('APK文件太小，可能已损坏'));
      }

      // 请求安装权限
      final hasPermission = await _requestInstallPermission();
      if (!hasPermission) {
        return Failure(InstallException('没有安装权限。请在设置中允许本应用安装未知来源的应用。'));
      }

      // 修改文件权限，确保文件可读
      await _ensureFilePermissions(filePath);

      _logger.i('开始打开APK文件进行安装');

      // 使用open_filex打开APK文件，让系统处理安装
      final result = await OpenFilex.open(filePath);

      _logger.i('OpenFilex结果: type=${result.type}, message=${result.message}');

      if (result.type == ResultType.done) {
        _logger.i('APK文件已打开，系统安装程序已启动');
        return const Success(unit);
      } else if (result.type == ResultType.fileNotFound) {
        _logger.e('APK文件未找到: $filePath');
        return Failure(InstallException('APK文件不存在或已损坏'));
      } else if (result.type == ResultType.noAppToOpen) {
        _logger.e('没有找到可以处理APK文件的应用');
        return Failure(InstallException('系统无法处理APK文件。请检查文件是否损坏。'));
      } else if (result.type == ResultType.permissionDenied) {
        _logger.e('没有权限打开APK文件');
        return Failure(InstallException('没有权限安装应用。请在设置中允许本应用安装未知来源的应用。'));
      } else {
        final errorMsg = result.message;
        _logger.e('打开APK文件失败: $errorMsg');
        return Failure(InstallException('打开安装文件失败: $errorMsg'));
      }
    } catch (e, stackTrace) {
      _logger.e('APK安装异常', error: e, stackTrace: stackTrace);
      return Failure(InstallException('安装异常: ${e.toString()}'));
    }
  }

  /// 确保文件权限正确
  Future<void> _ensureFilePermissions(String filePath) async {
    try {
      // 在Android上，使用chmod命令设置文件权限
      if (Platform.isAndroid) {
        final result = await Process.run('chmod', ['644', filePath]);
        if (result.exitCode == 0) {
          _logger.i('文件权限设置成功: $filePath');
        } else {
          _logger.w('文件权限设置失败: ${result.stderr}');
        }
      }
    } catch (e) {
      _logger.w('设置文件权限时出现错误: $e');
      // 不抛出异常，继续安装流程
    }
  }

  /// 请求安装权限（公有方法）
  Future<bool> requestInstallPermission() async {
    return await _requestInstallPermission();
  }

  /// 请求安装权限
  Future<bool> _requestInstallPermission() async {
    try {
      if (Platform.isAndroid) {
        // 检查是否已有安装权限
        final status = await Permission.requestInstallPackages.status;

        if (status.isGranted) {
          return true;
        }

        // 请求安装权限
        final result = await Permission.requestInstallPackages.request();
        return result.isGranted;
      }
      return false;
    } catch (e) {
      _logger.e('请求安装权限失败，可能是插件未正确初始化', error: e);
      return false;
    }
  }

  /// 检查是否有安装权限
  Future<bool> hasInstallPermission() async {
    try {
      if (Platform.isAndroid) {
        // 添加更详细的错误处理
        final status = await Permission.requestInstallPackages.status;
        _logger.i('安装权限状态: $status');
        return status.isGranted;
      }
      return false;
    } catch (e) {
      _logger.w('检查安装权限失败，可能是插件未正确初始化', error: e);
      return false;
    }
  }

  /// 根据平台获取正确的文件扩展名
  String getInstallFileExtension() {
    if (Platform.isAndroid) {
      return 'apk';
    } else if (Platform.isIOS) {
      return 'ipa';
    } else if (Platform.isMacOS) {
      return 'dmg';
    } else if (Platform.isWindows) {
      return 'exe';
    } else if (Platform.isLinux) {
      return 'deb';
    }
    return 'unknown';
  }

  /// 检查当前平台是否支持自动安装
  bool isSupportedPlatform() {
    // 目前主要支持Android平台的自动安装
    return Platform.isAndroid;
  }
}

class InstallException implements Exception {
  final String message;

  InstallException(this.message);

  @override
  String toString() => 'InstallException: $message';
}
