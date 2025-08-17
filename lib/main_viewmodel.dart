import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';

import 'data/repository/settings/settings_repository.dart';
import 'data/repository/update/update_repository.dart';
import 'data/service/share_intent_service.dart';
import 'data/service/update_service.dart';

class MainAppViewModel extends ChangeNotifier {
  final _updateAvailableController = StreamController<UpdateInfo>.broadcast();
  Stream<UpdateInfo> get onUpdateAvailable => _updateAvailableController.stream;

  MainAppViewModel(this._settingsRepository, this._updateRepository) {
    _load();
    // 监听SettingsRepository的变化
    _settingsSubscription =
        _settingsRepository.settingsChanged.listen(_onSettingsChanged);

    // 初始化分享Intent服务
    _shareIntentService.initialize();

    _checkUpdateCommand = Command.createAsyncNoParam<UpdateInfo?>(() async {
      final result = await _updateRepository.checkForUpdate();
      return result.getOrNull();
    }, initialValue: null);

    _checkUpdateCommand.results.listen((commandResult, _) {
      _updateInfo = commandResult.data;
      if (_updateInfo != null) {
        _updateAvailableController.add(_updateInfo!);
      }
      notifyListeners();
    });

    _checkUpdateCommand.execute();
  }

  final UpdateRepository _updateRepository;
  late final Command<void, UpdateInfo?> _checkUpdateCommand;
  UpdateInfo? _updateInfo;
  UpdateInfo? get updateInfo => _updateInfo;

  final SettingsRepository _settingsRepository;
  final ShareIntentService _shareIntentService = ShareIntentService();
  late final StreamSubscription<void> _settingsSubscription;

  ThemeMode _themeMode = ThemeMode.system;
  String? _pendingSharedText;

  ThemeMode get themeMode => _themeMode;
  String? get pendingSharedText => _pendingSharedText;
  Stream<String> get shareTextStream => _shareIntentService.shareTextStream;

  void _load() {
    // 由于SettingsRepository已经预加载，直接同步获取主题模式
    final themeModeIndex = _settingsRepository.getThemeMode();
    _themeMode = ThemeMode.values[themeModeIndex];
    notifyListeners();
  }

  void _onSettingsChanged(void _) {
    // 当SettingsRepository发生变化时，更新主题模式
    final themeModeIndex = _settingsRepository.getThemeMode();
    final newThemeMode = ThemeMode.values[themeModeIndex];
    if (_themeMode != newThemeMode) {
      _themeMode = newThemeMode;
      notifyListeners();
    }
  }

  void setPendingSharedText(String? text) {
    _pendingSharedText = text;
    notifyListeners();
  }

  void clearPendingSharedText() {
    _pendingSharedText = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _settingsSubscription.cancel();
    _shareIntentService.dispose();
    _updateAvailableController.close();
    super.dispose();
  }
}
