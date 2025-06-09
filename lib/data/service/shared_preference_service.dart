import 'package:flutter/material.dart';
import 'package:result_dart/result_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _kThemeMode = 'themeMode';
  static const String _kReadeckApiHost = 'readeckApiHost';
  static const String _kReadeckApiToken = 'readeckApiToken';

  AsyncResult<void> setThemeMode(int value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setInt(_kThemeMode, value);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  AsyncResult<int> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = prefs.getInt(_kThemeMode) ?? ThemeMode.system.index;
      return Success(value);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  AsyncResult<void> setReadeckApiHost(String value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_kReadeckApiHost, value);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  AsyncResult<String> getReadeckApiHost() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = prefs.getString(_kReadeckApiHost) ?? '';
      return Success(value);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  AsyncResult<void> setReadeckApiToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_kReadeckApiToken, value);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  AsyncResult<String> getReadeckApiToken() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = prefs.getString(_kReadeckApiToken) ?? '';
      return Success(value);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
