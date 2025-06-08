import 'dart:async';

import 'package:flutter/material.dart';
import 'package:readeck_app/data/repository/theme/theme_repository.dart';
import 'package:readeck_app/utils/command.dart';
import 'package:readeck_app/utils/result.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._themeRepository) {
    // 主题切换时整个页面都会重建，这里就不用监听了
    _initializeThemeMode();
    setThemeMode = Command1<void, ThemeMode>(_setThemeMode);
  }
  final ThemeRepository _themeRepository;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  late Command1 setThemeMode;

  Future<void> _initializeThemeMode() async {
    final result = await _themeRepository.getThemeMode();
    if (result is Ok<ThemeMode>) {
      _themeMode = result.value;
      notifyListeners();
    }
  }

  Future<Result<void>> _setThemeMode(ThemeMode themeMode) async {
    try {
      await _themeRepository.setThemeMode(themeMode);
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
