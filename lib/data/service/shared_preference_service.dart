import 'package:flutter/material.dart';
import 'package:result_dart/result_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _kThemeMode = 'themeMode';
  static const String _kReadeckApiHost = 'readeckApiHost';
  static const String _kReadeckApiToken = 'readeckApiToken';
  static const String _kOpenRouterApiKey = 'openRouterApiKey';
  static const String _kSelectedOpenRouterModel = 'selectedOpenRouterModel';
  static const String _kSelectedOpenRouterModelName =
      'selectedOpenRouterModelName';

  static const String _kTranslationProvider = 'translationProvider';
  static const String _kTranslationTargetLanguage = 'translationTargetLanguage';
  static const String _kTranslationCacheEnabled = 'translationCacheEnabled';
  static const String _kAiTagTargetLanguage = 'aiTagTargetLanguage';

  static const String _kTranslationModel = 'translationModel';
  static const String _kTranslationModelName = 'translationModelName';
  static const String _kAiTagModel = 'aiTagModel';
  static const String _kAiTagModelName = 'aiTagModelName';

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

  /// 设置AI标签目标语言
  AsyncResult<void> setAiTagTargetLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_kAiTagTargetLanguage, value);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 获取AI标签目标语言
  /// 默认值为 '中文'
  AsyncResult<String> getAiTagTargetLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = prefs.getString(_kAiTagTargetLanguage) ?? '中文';
      return Success(value);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 设置翻译场景专用模型
  AsyncResult<void> setTranslationModel(String value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_kTranslationModel, value);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 获取翻译场景专用模型
  /// 默认值为空字符串（使用全局模型）
  AsyncResult<String> getTranslationModel() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = prefs.getString(_kTranslationModel) ?? '';
      return Success(value);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 设置翻译场景专用模型名称
  AsyncResult<void> setTranslationModelName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_kTranslationModelName, value);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 获取翻译场景专用模型名称
  AsyncResult<String> getTranslationModelName() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = prefs.getString(_kTranslationModelName) ?? '';
      return Success(value);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 设置AI标签场景专用模型
  AsyncResult<void> setAiTagModel(String value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_kAiTagModel, value);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 获取AI标签场景专用模型
  /// 默认值为空字符串（使用全局模型）
  AsyncResult<String> getAiTagModel() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = prefs.getString(_kAiTagModel) ?? '';
      return Success(value);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 设置AI标签场景专用模型名称
  AsyncResult<void> setAiTagModelName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_kAiTagModelName, value);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 获取AI标签场景专用模型名称
  AsyncResult<String> getAiTagModelName() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = prefs.getString(_kAiTagModelName) ?? '';
      return Success(value);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 设置选中的 OpenRouter 模型名称
  AsyncResult<void> setSelectedOpenRouterModelName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_kSelectedOpenRouterModelName, value);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 获取选中的 OpenRouter 模型名称
  AsyncResult<String> getSelectedOpenRouterModelName() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = prefs.getString(_kSelectedOpenRouterModelName) ?? '';
      return Success(value);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
