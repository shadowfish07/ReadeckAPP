import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/main.dart';
import 'package:result_dart/result_dart.dart';
import '../../../data/repository/update/update_repository.dart';
import '../../../domain/models/update/update_info.dart';
import '../../../domain/use_cases/app_update_use_case.dart';

class AboutViewModel extends ChangeNotifier {
  final UpdateRepository _updateRepository;
  final AppUpdateUseCase _appUpdateUseCase;

  AboutViewModel(this._updateRepository, this._appUpdateUseCase) {
    load = Command.createAsyncNoParamNoResult(_loadVersion)..execute();
    _initializeUpdateCommands();
    _checkForUpdate();
  }

  late Command load;
  late final Command<void, UpdateInfo?> _checkUpdateCommand;
  late final Command<UpdateInfo, void> _downloadAndInstallUpdateCommand;
  late final Command<UpdateInfo, String> _downloadUpdateCommand;
  late final Command<String, void> _installUpdateCommand;

  String _version = 'Unknown';
  String get version => _version;

  UpdateInfo? _updateInfo;
  UpdateInfo? get updateInfo => _updateInfo;

  // 下载进度相关
  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  bool _isInstalling = false;
  bool get isInstalling => _isInstalling;

  // 暴露更新相关的Commands
  Command<UpdateInfo, void> get downloadAndInstallUpdateCommand =>
      _downloadAndInstallUpdateCommand;
  Command<UpdateInfo, String> get downloadUpdateCommand =>
      _downloadUpdateCommand;
  Command<String, void> get installUpdateCommand => _installUpdateCommand;

  void _initializeUpdateCommands() {
    _checkUpdateCommand = Command.createAsyncNoParam<UpdateInfo?>(() async {
      final result = await _updateRepository.checkForUpdate();
      return result.getOrNull();
    }, initialValue: null);

    _checkUpdateCommand.results.listen((commandResult, _) {
      _updateInfo = commandResult.data;
      notifyListeners();
    });

    // 初始化下载并安装更新命令
    _downloadAndInstallUpdateCommand =
        Command.createAsyncNoResult<UpdateInfo>((updateInfo) async {
      appLogger.i('开始下载并安装更新: ${updateInfo.version}');
      _isDownloading = true;
      _downloadProgress = 0.0;
      notifyListeners();

      final result = await _appUpdateUseCase.downloadAndInstallUpdate(
        updateInfo,
        onProgress: (received, total) {
          if (total > 0) {
            _downloadProgress = received / total;
            notifyListeners();
          }
        },
      );

      _isDownloading = false;

      if (result.isError()) {
        appLogger.e('更新失败: ${result.exceptionOrNull()}');
        notifyListeners();
        throw result.exceptionOrNull()!;
      }

      appLogger.i('更新完成');
      notifyListeners();
    });

    // 初始化仅下载更新命令
    _downloadUpdateCommand =
        Command.createAsync<UpdateInfo, String>((updateInfo) async {
      appLogger.i('开始下载更新文件: ${updateInfo.version}');
      _isDownloading = true;
      _downloadProgress = 0.0;
      notifyListeners();

      final result = await _appUpdateUseCase.downloadUpdate(
        updateInfo,
        onProgress: (received, total) {
          if (total > 0) {
            _downloadProgress = received / total;
            notifyListeners();
          }
        },
      );

      _isDownloading = false;

      if (result.isError()) {
        appLogger.e('下载失败: ${result.exceptionOrNull()}');
        notifyListeners();
        throw result.exceptionOrNull()!;
      }

      final filePath = result.getOrThrow();
      appLogger.i('下载完成: $filePath');
      notifyListeners();
      return filePath;
    }, initialValue: '');

    // 初始化安装更新命令
    _installUpdateCommand =
        Command.createAsyncNoResult<String>((filePath) async {
      appLogger.i('开始安装更新文件: $filePath');
      _isInstalling = true;
      notifyListeners();

      final result = await _appUpdateUseCase.installUpdate(filePath);

      _isInstalling = false;

      if (result.isError()) {
        appLogger.e('安装失败: ${result.exceptionOrNull()}');
        notifyListeners();
        throw result.exceptionOrNull()!;
      }

      appLogger.i('安装完成');
      notifyListeners();
    });
  }

  void _checkForUpdate() {
    _checkUpdateCommand.execute();
  }

  AsyncResult<void> _loadVersion() async {
    try {
      final String pubspecContent = await rootBundle.loadString('pubspec.yaml');
      final RegExp versionRegex = RegExp(r'version:\s*([^\s]+)');
      final Match? match = versionRegex.firstMatch(pubspecContent);
      if (match != null) {
        _version = match.group(1)!.split('+')[0];
        notifyListeners();
        return const Success(unit);
      }
      notifyListeners();
      appLogger.w("Wrong Version Format. pubspecContent: $pubspecContent");
      return Failure(Exception("Wrong Version Format"));
    } on Exception catch (e) {
      // 如果读取失败，保持默认版本号
      appLogger.e('Failed to load version: $e');
      notifyListeners();
      return Failure(e);
    }
  }
}
