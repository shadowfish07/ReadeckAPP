import 'dart:async';

import 'package:flutter/material.dart';

import 'data/repository/theme/theme_repository.dart';

class MainAppViewModel extends ChangeNotifier {
  MainAppViewModel(this._themeRepository) {
    _subscription = _themeRepository.observeThemeMode().listen((themeMode) {
      _themeMode = themeMode;
      notifyListeners();
    });
    _load();
  }

  final ThemeRepository _themeRepository;
  StreamSubscription<ThemeMode>? _subscription;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> _load() async {
    try {
      final result = await _themeRepository.getThemeMode();
      if (result.isSuccess()) {
        _themeMode = result.getOrNull()!;
      }
    } on Exception catch (_) {
      // handle error
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
