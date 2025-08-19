import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/article/article_repository.dart';
import 'package:readeck_app/data/repository/openrouter/openrouter_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/domain/models/openrouter_model/openrouter_model.dart';
import 'package:readeck_app/main.dart';

class TranslationSettingsViewModel extends ChangeNotifier {
  TranslationSettingsViewModel(this._settingsRepository,
      this._articleRepository, this._openRouterRepository) {
    _initCommands();
    _listenToSettingsChanges();
  }

  final SettingsRepository _settingsRepository;
  final ArticleRepository _articleRepository;
  final OpenRouterRepository _openRouterRepository;

  StreamSubscription<void>? _settingsSubscription;

  List<OpenRouterModel> _availableModels = [];

  String get translationProvider =>
      _settingsRepository.getTranslationProvider();
  String get translationTargetLanguage =>
      _settingsRepository.getTranslationTargetLanguage();
  bool get translationCacheEnabled =>
      _settingsRepository.getTranslationCacheEnabled();
  String get translationModel => _settingsRepository.getTranslationModel();
  String get translationModelName =>
      _settingsRepository.getTranslationModelName();
  List<OpenRouterModel> get availableModels => _availableModels;

  OpenRouterModel? get selectedTranslationModel {
    final translationModel = _settingsRepository.getTranslationModel();
    if (translationModel.isEmpty || _availableModels.isEmpty) {
      return null;
    }
    return _availableModels
        .where((model) => model.id == translationModel)
        .firstOrNull;
  }

  late Command<String, void> saveTranslationProvider;
  late Command<String, void> saveTranslationTargetLanguage;
  late Command<bool, void> saveTranslationCacheEnabled;
  late Command<String, void> saveTranslationModel;
  late Command<void, void> loadTranslationSettings;
  late Command<void, List<OpenRouterModel>> loadModels;
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

    saveTranslationModel = Command.createAsyncNoResult<String>(
      _saveTranslationModel,
    );

    loadTranslationSettings = Command.createSyncNoParam(
      _loadTranslationSettings,
      initialValue: null,
    )..execute();

    loadModels = Command.createAsyncNoParam(_loadModelsAsync,
        initialValue: [], includeLastResultInCommandResults: true)
      ..execute();

    clearTranslationCache = Command.createAsyncNoParam(
      _clearTranslationCacheAsync,
      initialValue: null,
    );
  }

  Future<void> _saveTranslationProvider(String provider) async {
    final result = await _settingsRepository.saveTranslationProvider(provider);
    if (result.isSuccess()) {
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
      notifyListeners();
    } else {
      appLogger.e('保存翻译缓存启用状态失败', error: result.exceptionOrNull()!);
      throw result.exceptionOrNull()!;
    }
  }

  void _loadTranslationSettings() {
    // 由于SettingsRepository已经预加载，直接同步获取翻译设置
    // 不需要在ViewModel中缓存数据，直接通过getter访问Repository即可
    notifyListeners();
  }

  Future<void> _saveTranslationModel(String modelId) async {
    final result = await _settingsRepository.saveTranslationModel(modelId, '');
    if (result.isSuccess()) {
      notifyListeners();
      appLogger.d('成功保存翻译场景模型: $modelId');
    } else {
      appLogger.e('保存翻译场景模型失败', error: result.exceptionOrNull()!);
      throw result.exceptionOrNull()!;
    }
  }

  Future<List<OpenRouterModel>> _loadModelsAsync() async {
    final result =
        await _openRouterRepository.getModels(category: 'translation');
    if (result.isSuccess()) {
      _availableModels = result.getOrNull() ?? [];
      appLogger.d('成功加载 ${_availableModels.length} 个OpenRouter翻译模型');
      notifyListeners();
      return _availableModels;
    } else {
      appLogger.e('获取OpenRouter翻译模型列表失败', error: result.exceptionOrNull()!);
      _availableModels = [];
      notifyListeners();
      throw result.exceptionOrNull()!;
    }
  }

  void selectTranslationModel(OpenRouterModel model) {
    saveTranslationModel.execute(model.id);
  }

  void clearTranslationModel() {
    saveTranslationModel.execute('');
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

  void _listenToSettingsChanges() {
    _settingsSubscription = _settingsRepository.settingsChanged.listen((_) {
      appLogger.d('翻译设置页面收到配置变更通知，刷新页面');
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    saveTranslationProvider.dispose();
    saveTranslationTargetLanguage.dispose();
    saveTranslationCacheEnabled.dispose();
    saveTranslationModel.dispose();
    loadTranslationSettings.dispose();
    loadModels.dispose();
    clearTranslationCache.dispose();
    super.dispose();
  }
}
