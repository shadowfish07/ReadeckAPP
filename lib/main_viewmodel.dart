import 'dart:async';
import 'package:flutter/material.dart';

import 'data/repository/settings/settings_repository.dart';
import 'data/service/share_intent_service.dart';

class MainAppViewModel extends ChangeNotifier {
  MainAppViewModel(this._settingsRepository) {
    _load();
    // 监听SettingsRepository的变化
    _settingsSubscription =
        _settingsRepository.settingsChanged.listen(_onSettingsChanged);

    // 初始化分享Intent服务
    _shareIntentService.initialize();
  }

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
    super.dispose();
  }
}
