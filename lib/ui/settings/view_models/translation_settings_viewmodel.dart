import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/main.dart';

class TranslationSettingsViewModel extends ChangeNotifier {
  TranslationSettingsViewModel(this._settingsRepository) {
    _initCommands();
  }

  final SettingsRepository _settingsRepository;

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

    loadTranslationSettings = Command.createAsyncNoParam(
      _loadTranslationSettingsAsync,
      initialValue: null,
    )..execute();
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

  Future<void> _loadTranslationSettingsAsync() async {
    // 加载翻译服务提供方
    final providerResult = await _settingsRepository.getTranslationProvider();
    if (providerResult.isSuccess()) {
      _translationProvider = providerResult.getOrNull() ?? 'AI';
    } else {
      appLogger.e('获取翻译服务提供方失败', error: providerResult.exceptionOrNull()!);
      _translationProvider = 'AI';
    }

    // 加载翻译目标语种
    final languageResult =
        await _settingsRepository.getTranslationTargetLanguage();
    if (languageResult.isSuccess()) {
      _translationTargetLanguage = languageResult.getOrNull() ?? '中文';
    } else {
      appLogger.e('获取翻译目标语种失败', error: languageResult.exceptionOrNull()!);
      _translationTargetLanguage = '中文';
    }

    // 加载翻译缓存启用状态
    final cacheResult = await _settingsRepository.getTranslationCacheEnabled();
    if (cacheResult.isSuccess()) {
      _translationCacheEnabled = cacheResult.getOrNull() ?? true;
    } else {
      appLogger.e('获取翻译缓存启用状态失败', error: cacheResult.exceptionOrNull()!);
      _translationCacheEnabled = true;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    saveTranslationProvider.dispose();
    saveTranslationTargetLanguage.dispose();
    saveTranslationCacheEnabled.dispose();
    loadTranslationSettings.dispose();
    super.dispose();
  }
}
