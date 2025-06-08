import 'dart:async';

import 'package:flutter/material.dart';

import '../../../utils/result.dart';
import '../../service/shared_preference_service.dart';

class ThemeRepository {
  ThemeRepository(this._service);

  final _themeModeController = StreamController<ThemeMode>.broadcast();

  final SharedPreferencesService _service;

  Future<Result<ThemeMode>> getThemeMode() async {
    try {
      final value = await _service.getThemeMode();
      return Result.ok(ThemeMode.values[value]);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> setThemeMode(ThemeMode value) async {
    try {
      await _service.setThemeMode(value.index);
      _themeModeController.add(value);
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Stream<ThemeMode> observeThemeMode() => _themeModeController.stream;
}
