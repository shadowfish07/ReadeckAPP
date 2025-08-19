import 'dart:async';
import 'package:readeck_app/data/service/shared_preference_service.dart';
import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/main.dart';
import 'package:result_dart/result_dart.dart';

class SettingsRepository {
  SettingsRepository(this._prefsService, this._apiClient);

  final StreamController<void> _settingsChangedController =
      StreamController<void>.broadcast();

  /// 设置变更通知流
  Stream<void> get settingsChanged => _settingsChangedController.stream;

  final SharedPreferencesService _prefsService;
  final ReadeckApiClient _apiClient;

  // 缓存的配置数据
  int? _themeMode;
  String? _readeckApiHost;
  String? _readeckApiToken;
  String? _openRouterApiKey;
  String? _selectedOpenRouterModel;
  String? _translationProvider;
  String? _translationTargetLanguage;
  bool? _translationCacheEnabled;
  String? _aiTagTargetLanguage;
  String? _translationModel;
  String? _aiTagModel;

  bool _isLoaded = false;

  /// 预加载所有配置数据
  /// 应在应用启动时调用
  AsyncResult<void> loadSettings() async {
    try {
      appLogger.i('开始加载应用配置');

      // 加载主题模式
      final themeModeResult = await _prefsService.getThemeMode();
      if (themeModeResult.isError()) {
        appLogger.e('加载主题模式失败', error: themeModeResult.exceptionOrNull());
        return Failure(
            Exception('加载主题模式失败: ${themeModeResult.exceptionOrNull()}'));
      }
      _themeMode = themeModeResult.getOrThrow();

      // 加载 Readeck API 配置
      final hostResult = await _prefsService.getReadeckApiHost();
      if (hostResult.isError()) {
        appLogger.e('加载Readeck API Host失败',
            error: hostResult.exceptionOrNull());
        return Failure(
            Exception('加载Readeck API Host失败: ${hostResult.exceptionOrNull()}'));
      }
      _readeckApiHost = hostResult.getOrThrow();

      final tokenResult = await _prefsService.getReadeckApiToken();
      if (tokenResult.isError()) {
        appLogger.e('加载Readeck API Token失败',
            error: tokenResult.exceptionOrNull());
        return Failure(Exception(
            '加载Readeck API Token失败: ${tokenResult.exceptionOrNull()}'));
      }
      _readeckApiToken = tokenResult.getOrThrow();

      // 加载 OpenRouter API Key
      final openRouterKeyResult = await _prefsService.getOpenRouterApiKey();
      if (openRouterKeyResult.isError()) {
        appLogger.e('加载OpenRouter API Key失败',
            error: openRouterKeyResult.exceptionOrNull());
        return Failure(Exception(
            '加载OpenRouter API Key失败: ${openRouterKeyResult.exceptionOrNull()}'));
      }
      _openRouterApiKey = openRouterKeyResult.getOrThrow();

      // 加载选中的 OpenRouter 模型
      final selectedModelResult =
          await _prefsService.getSelectedOpenRouterModel();
      if (selectedModelResult.isError()) {
        appLogger.e('加载选中的OpenRouter模型失败',
            error: selectedModelResult.exceptionOrNull());
        return Failure(Exception(
            '加载选中的OpenRouter模型失败: ${selectedModelResult.exceptionOrNull()}'));
      }
      _selectedOpenRouterModel = selectedModelResult.getOrThrow();

      // 加载翻译服务提供方
      final translationProviderResult =
          await _prefsService.getTranslationProvider();
      if (translationProviderResult.isError()) {
        appLogger.e('加载翻译服务提供方失败',
            error: translationProviderResult.exceptionOrNull());
        return Failure(Exception(
            '加载翻译服务提供方失败: ${translationProviderResult.exceptionOrNull()}'));
      }
      _translationProvider = translationProviderResult.getOrThrow();

      // 加载翻译目标语种
      final translationLanguageResult =
          await _prefsService.getTranslationTargetLanguage();
      if (translationLanguageResult.isError()) {
        appLogger.e('加载翻译目标语种失败',
            error: translationLanguageResult.exceptionOrNull());
        return Failure(Exception(
            '加载翻译目标语种失败: ${translationLanguageResult.exceptionOrNull()}'));
      }
      _translationTargetLanguage = translationLanguageResult.getOrThrow();

      // 加载翻译缓存启用状态
      final translationCacheResult =
          await _prefsService.getTranslationCacheEnabled();
      if (translationCacheResult.isError()) {
        appLogger.e('加载翻译缓存启用状态失败',
            error: translationCacheResult.exceptionOrNull());
        return Failure(Exception(
            '加载翻译缓存启用状态失败: ${translationCacheResult.exceptionOrNull()}'));
      }
      _translationCacheEnabled = translationCacheResult.getOrThrow();

      // 加载AI标签目标语言
      final aiTagLanguageResult = await _prefsService.getAiTagTargetLanguage();
      if (aiTagLanguageResult.isError()) {
        appLogger.e('加载AI标签目标语言失败',
            error: aiTagLanguageResult.exceptionOrNull());
        return Failure(Exception(
            '加载AI标签目标语言失败: ${aiTagLanguageResult.exceptionOrNull()}'));
      }
      _aiTagTargetLanguage = aiTagLanguageResult.getOrThrow();

      // 加载翻译场景专用模型
      final translationModelResult = await _prefsService.getTranslationModel();
      if (translationModelResult.isError()) {
        appLogger.e('加载翻译场景模型失败',
            error: translationModelResult.exceptionOrNull());
        return Failure(Exception(
            '加载翻译场景模型失败: ${translationModelResult.exceptionOrNull()}'));
      }
      _translationModel = translationModelResult.getOrThrow();

      // 加载AI标签场景专用模型
      final aiTagModelResult = await _prefsService.getAiTagModel();
      if (aiTagModelResult.isError()) {
        appLogger.e('加载AI标签场景模型失败', error: aiTagModelResult.exceptionOrNull());
        return Failure(
            Exception('加载AI标签场景模型失败: ${aiTagModelResult.exceptionOrNull()}'));
      }
      _aiTagModel = aiTagModelResult.getOrThrow();

      _isLoaded = true;
      appLogger.i('应用配置加载完成');
      return const Success(unit);
    } catch (e) {
      appLogger.e('加载应用配置时发生未知错误', error: e);
      return Failure(Exception('加载应用配置时发生未知错误: $e'));
    }
  }

  /// 检查配置是否已加载
  void _ensureLoaded() {
    if (!_isLoaded) {
      throw Exception('配置尚未加载，请先调用 loadSettings()');
    }
  }

  /// 同步检查 API 是否已配置
  bool isApiConfigured() {
    _ensureLoaded();
    return _readeckApiHost!.isNotEmpty && _readeckApiToken!.isNotEmpty;
  }

  /// 保存 API 配置
  AsyncResult<void> saveApiConfig(String host, String token) async {
    _ensureLoaded();

    var res = await _prefsService.setReadeckApiHost(host);
    if (res.isError()) {
      appLogger.e("保存API配置失败(host)", error: res.exceptionOrNull());
      return res;
    }

    res = await _prefsService.setReadeckApiToken(token);
    if (res.isError()) {
      appLogger.e("保存API配置失败(token)", error: res.exceptionOrNull());
      return res;
    }

    // 更新缓存
    _readeckApiHost = host;
    _readeckApiToken = token;

    // 更新 API 客户端配置
    _apiClient.updateConfig(host, token);

    return const Success(unit);
  }

  /// 同步获取 API 配置
  (String, String) getApiConfig() {
    _ensureLoaded();
    return (_readeckApiHost!, _readeckApiToken!);
  }

  /// 同步获取主题模式
  int getThemeMode() {
    _ensureLoaded();
    return _themeMode!;
  }

  /// 保存主题模式
  AsyncResult<void> saveThemeMode(int themeMode) async {
    _ensureLoaded();

    final result = await _prefsService.setThemeMode(themeMode);
    if (result.isError()) {
      appLogger.e("保存主题模式失败", error: result.exceptionOrNull());
      return result;
    }

    // 更新缓存
    _themeMode = themeMode;
    // 通知监听者主题已变更
    _settingsChangedController.add(null);
    return const Success(unit);
  }

  /// 保存 OpenRouter API Key
  AsyncResult<void> saveOpenRouterApiKey(String apiKey) async {
    _ensureLoaded();

    final result = await _prefsService.setOpenRouterApiKey(apiKey);
    if (result.isError()) {
      appLogger.e("保存OpenRouter API Key失败", error: result.exceptionOrNull());
      return result;
    }

    // 更新缓存
    _openRouterApiKey = apiKey;
    return const Success(unit);
  }

  /// 同步获取 OpenRouter API Key
  String getOpenRouterApiKey() {
    _ensureLoaded();
    return _openRouterApiKey!;
  }

  /// 保存翻译服务提供方
  AsyncResult<void> saveTranslationProvider(String provider) async {
    _ensureLoaded();

    final result = await _prefsService.setTranslationProvider(provider);
    if (result.isError()) {
      appLogger.e("保存翻译服务提供方失败", error: result.exceptionOrNull());
      return result;
    }

    // 更新缓存
    _translationProvider = provider;
    return const Success(unit);
  }

  /// 同步获取翻译服务提供方
  String getTranslationProvider() {
    _ensureLoaded();
    return _translationProvider!;
  }

  /// 保存翻译目标语种
  AsyncResult<void> saveTranslationTargetLanguage(String language) async {
    _ensureLoaded();

    final result = await _prefsService.setTranslationTargetLanguage(language);
    if (result.isError()) {
      appLogger.e("保存翻译目标语种失败", error: result.exceptionOrNull());
      return result;
    }

    // 更新缓存
    _translationTargetLanguage = language;
    return const Success(unit);
  }

  /// 同步获取翻译目标语种
  String getTranslationTargetLanguage() {
    _ensureLoaded();
    return _translationTargetLanguage!;
  }

  /// 保存翻译缓存启用状态
  AsyncResult<void> saveTranslationCacheEnabled(bool enabled) async {
    _ensureLoaded();

    final result = await _prefsService.setTranslationCacheEnabled(enabled);
    if (result.isError()) {
      appLogger.e("保存翻译缓存启用状态失败", error: result.exceptionOrNull());
      return result;
    }

    // 更新缓存
    _translationCacheEnabled = enabled;
    return const Success(unit);
  }

  /// 同步获取翻译缓存启用状态
  bool getTranslationCacheEnabled() {
    _ensureLoaded();
    return _translationCacheEnabled!;
  }

  /// 保存选中的 OpenRouter 模型
  AsyncResult<void> saveSelectedOpenRouterModel(String modelId) async {
    _ensureLoaded();

    final result = await _prefsService.setSelectedOpenRouterModel(modelId);
    if (result.isError()) {
      appLogger.e("保存选中的OpenRouter模型失败", error: result.exceptionOrNull());
      return result;
    }

    // 更新缓存
    _selectedOpenRouterModel = modelId;
    return const Success(unit);
  }

  /// 同步获取选中的 OpenRouter 模型
  String getSelectedOpenRouterModel() {
    _ensureLoaded();
    return _selectedOpenRouterModel!;
  }

  /// 保存AI标签目标语言
  AsyncResult<void> saveAiTagTargetLanguage(String language) async {
    _ensureLoaded();

    final result = await _prefsService.setAiTagTargetLanguage(language);
    if (result.isError()) {
      appLogger.e("保存AI标签目标语言失败", error: result.exceptionOrNull());
      return result;
    }

    // 更新缓存
    _aiTagTargetLanguage = language;
    return const Success(unit);
  }

  /// 同步获取AI标签目标语言
  String getAiTagTargetLanguage() {
    _ensureLoaded();
    return _aiTagTargetLanguage!;
  }

  /// 保存翻译场景专用模型
  AsyncResult<void> saveTranslationModel(String modelId) async {
    _ensureLoaded();

    final result = await _prefsService.setTranslationModel(modelId);
    if (result.isError()) {
      appLogger.e("保存翻译场景模型失败", error: result.exceptionOrNull());
      return result;
    }

    // 更新缓存
    _translationModel = modelId;
    return const Success(unit);
  }

  /// 同步获取翻译场景专用模型
  String getTranslationModel() {
    _ensureLoaded();
    return _translationModel!;
  }

  /// 保存AI标签场景专用模型
  AsyncResult<void> saveAiTagModel(String modelId) async {
    _ensureLoaded();

    final result = await _prefsService.setAiTagModel(modelId);
    if (result.isError()) {
      appLogger.e("保存AI标签场景模型失败", error: result.exceptionOrNull());
      return result;
    }

    // 更新缓存
    _aiTagModel = modelId;
    return const Success(unit);
  }

  /// 同步获取AI标签场景专用模型
  String getAiTagModel() {
    _ensureLoaded();
    return _aiTagModel!;
  }

  /// 释放资源
  void dispose() {
    _settingsChangedController.close();
  }
}
