import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/theme/theme_repository.dart';
import 'package:result_dart/result_dart.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._themeRepository) {
    // 主题切换时整个页面都会重建，这里就不用监听了
    _initializeThemeMode();
    setThemeMode = Command.createAsyncNoResult<ThemeMode>(_setThemeMode);
  }
  final ThemeRepository _themeRepository;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  late Command setThemeMode;

  Future<void> _initializeThemeMode() async {
    final result = await _themeRepository.getThemeMode();
    if (result.isSuccess()) {
      _themeMode = result.getOrNull()!;
      notifyListeners();
    }
  }

  AsyncResult<void> _setThemeMode(ThemeMode themeMode) async {
    try {
      await _themeRepository.setThemeMode(themeMode);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
