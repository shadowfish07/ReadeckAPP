import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/article/article_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/main.dart';

class TranslationSettingsViewModel extends ChangeNotifier {
  TranslationSettingsViewModel(
      this._settingsRepository, this._articleRepository) {
    _initCommands();
  }

  final SettingsRepository _settingsRepository;
  final ArticleRepository _articleRepository;

  String _translationProvider = 'AI';
  String _translationTargetLanguage = '中文';
  bool _translationCacheEnabled = true;

  String get translationProvider => _translationProvider;
  String get translationTargetLanguage => _translationTargetLanguage;
  bool get translationCacheEnabled => _translationCacheEnabled;

  late Command<String, void> saveTranslationProvider;
  late Command<String, void> saveTranslationTargetLanguage;
  late Command<bool, void> saveTranslationCacheEnabled;
  late Command<void, void> loadTranslationSettings;
  late Command<void, void> clearTranslationCache;

  // 支持的语言列表
  static const List<String> supportedLanguages = [
    '中文',
    'English',
    '日本語',
    '한국어',
    'Français',
    'Deutsch',
    'Español',
    'Italiano',
    'Português',
    'Русский',
  ];

  void _initCommands() {
    saveTranslationProvider = Command.createAsyncNoResult<String>(
      _saveTranslationProvider,
    );

    saveTranslationTargetLanguage = Command.createAsyncNoResult<String>(
      _saveTranslationTargetLanguage,
    );

    saveTranslationCacheEnabled = Command.createAsyncNoResult<bool>(
      _saveTranslationCacheEnabled,
    );

    loadTranslationSettings = Command.createSyncNoParam(
      _loadTranslationSettings,
      initialValue: null,
    )..execute();

    clearTranslationCache = Command.createAsyncNoParam(
      _clearTranslationCacheAsync,
      initialValue: null,
    );
  }

  Future<void> _saveTranslationProvider(String provider) async {
    final result = await _settingsRepository.saveTranslationProvider(provider);
    if (result.isSuccess()) {
      _translationProvider = provider;
      notifyListeners();
    } else {
      appLogger.e('保存翻译服务提供方失败', error: result.exceptionOrNull()!);
      throw result.exceptionOrNull()!;
    }
  }

  Future<void> _saveTranslationTargetLanguage(String language) async {
    final result =
        await _settingsRepository.saveTranslationTargetLanguage(language);
    if (result.isSuccess()) {
      _translationTargetLanguage = language;
      notifyListeners();

      // 切换目标语种时清空翻译缓存
      appLogger.i('切换翻译目标语种到: $language，开始清空翻译缓存');
      final clearResult = await _articleRepository.clearTranslationCache();
      if (clearResult.isSuccess()) {
        appLogger.i('翻译缓存清空成功');
      } else {
        appLogger.e('清空翻译缓存失败', error: clearResult.exceptionOrNull()!);
      }
    } else {
      appLogger.e('保存翻译目标语种失败', error: result.exceptionOrNull()!);
      throw result.exceptionOrNull()!;
    }
  }

  Future<void> _saveTranslationCacheEnabled(bool enabled) async {
    final result =
        await _settingsRepository.saveTranslationCacheEnabled(enabled);
    if (result.isSuccess()) {
      _translationCacheEnabled = enabled;
      notifyListeners();
    } else {
      appLogger.e('保存翻译缓存启用状态失败', error: result.exceptionOrNull()!);
      throw result.exceptionOrNull()!;
    }
  }

  void _loadTranslationSettings() {
    // 由于SettingsRepository已经预加载，直接同步获取翻译设置
    _translationProvider = _settingsRepository.getTranslationProvider();
    _translationTargetLanguage =
        _settingsRepository.getTranslationTargetLanguage();
    _translationCacheEnabled = _settingsRepository.getTranslationCacheEnabled();

    notifyListeners();
  }

  Future<void> _clearTranslationCacheAsync() async {
    appLogger.i('手动清空翻译缓存');
    final result = await _articleRepository.clearTranslationCache();
    if (result.isSuccess()) {
      appLogger.i('翻译缓存清空成功');
    } else {
      appLogger.e('清空翻译缓存失败', error: result.exceptionOrNull()!);
      throw result.exceptionOrNull()!;
    }
  }

  @override
  void dispose() {
    saveTranslationProvider.dispose();
    saveTranslationTargetLanguage.dispose();
    saveTranslationCacheEnabled.dispose();
    loadTranslationSettings.dispose();
    clearTranslationCache.dispose();
    super.dispose();
  }
}
