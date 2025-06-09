import 'dart:async';

import 'package:flutter/material.dart';
import 'package:result_dart/result_dart.dart';

import '../../service/shared_preference_service.dart';

class ThemeRepository {
  ThemeRepository(this._service);

  final _themeModeController = StreamController<ThemeMode>.broadcast();

  final SharedPreferencesService _service;

  AsyncResult<ThemeMode> getThemeMode() async {
    final value = await _service.getThemeMode();
    if (value.isError()) {
      return Failure(Exception(value.exceptionOrNull()));
    }
    return Success(ThemeMode.values[value.getOrNull()!]);
  }

  AsyncResult<void> setThemeMode(ThemeMode value) async {
    try {
      await _service.setThemeMode(value.index);
      _themeModeController.add(value);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  Stream<ThemeMode> observeThemeMode() => _themeModeController.stream;
}
