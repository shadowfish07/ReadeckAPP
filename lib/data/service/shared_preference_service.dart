import 'package:flutter/material.dart';
import 'package:result_dart/result_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _kThemeMode = 'themeMode';
  static const String _kReadeckApiHost = 'readeckApiHost';
  static const String _kReadeckApiToken = 'readeckApiToken';
  static const String _kOpenRouterApiKey = 'openRouterApiKey';
  static const String _kSelectedOpenRouterModel = 'selectedOpenRouterModel';

  static const String _kTranslationProvider = 'translationProvider';
  static const String _kTranslationTargetLanguage = 'translationTargetLanguage';
  static const String _kTranslationCacheEnabled = 'translationCacheEnabled';

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

  AsyncResult<void> setOpenRouterApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_kOpenRouterApiKey, value);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  AsyncResult<String> getOpenRouterApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = prefs.getString(_kOpenRouterApiKey) ?? '';
      return Success(value);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  AsyncResult<void> setSelectedOpenRouterModel(String value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_kSelectedOpenRouterModel, value);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  AsyncResult<String> getSelectedOpenRouterModel() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = prefs.getString(_kSelectedOpenRouterModel) ?? '';
      return Success(value);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 设置翻译服务提供方
  AsyncResult<void> setTranslationProvider(String value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_kTranslationProvider, value);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 获取翻译服务提供方
  AsyncResult<String> getTranslationProvider() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = prefs.getString(_kTranslationProvider) ?? 'AI';
      return Success(value);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 设置翻译目标语种
  AsyncResult<void> setTranslationTargetLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_kTranslationTargetLanguage, value);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 获取翻译目标语种
  AsyncResult<String> getTranslationTargetLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = prefs.getString(_kTranslationTargetLanguage) ?? '中文';
      return Success(value);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 设置翻译缓存启用状态
  AsyncResult<void> setTranslationCacheEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setBool(_kTranslationCacheEnabled, value);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 获取翻译缓存启用状态
  /// 默认值为 true
  AsyncResult<bool> getTranslationCacheEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = prefs.getBool(_kTranslationCacheEnabled) ?? true;
      return Success(value);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
