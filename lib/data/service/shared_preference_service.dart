import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _kThemeMode = 'themeMode';
  static const String _kReadeckApiHost = 'readeckApiHost';
  static const String _kReadeckApiToken = 'readeckApiToken';

  Future<void> setThemeMode(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeMode, value);
  }

  Future<int> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kThemeMode) ?? ThemeMode.system.index;
  }

  Future<void> setReadeckApiHost(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kReadeckApiHost, value);
  }

  Future<String> getReadeckApiHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kReadeckApiHost) ?? '';
  }

  Future<void> setReadeckApiToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kReadeckApiToken, value);
  }

  Future<String> getReadeckApiToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kReadeckApiToken) ?? '';
  }
}
