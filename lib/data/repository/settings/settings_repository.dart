import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/data/service/database_service.dart';
import 'package:readeck_app/data/service/openrouter_api_client.dart';
import 'package:readeck_app/data/service/shared_preference_service.dart';
import 'package:readeck_app/domain/models/openrouter_model/openrouter_model.dart';
import 'package:readeck_app/main.dart';
import 'package:result_dart/result_dart.dart';

class SettingsRepository {
  SettingsRepository(this._apiClient, this._prefsService, this._databaseService,
      this._openRouterApiClient);

  final ReadeckApiClient _apiClient;
  final SharedPreferencesService _prefsService;
  final DatabaseService _databaseService;
  final OpenRouterApiClient _openRouterApiClient;

  AsyncResult<bool> isApiConfigured() async {
    if (await _prefsService.getReadeckApiHost().getOrDefault('') == '') {
      return const Success(false);
    }
    if (await _prefsService.getReadeckApiToken().getOrDefault('') == '') {
      return const Success(false);
    }
    return const Success(true);
  }

  AsyncResult<void> saveApiConfig(String host, String token) async {
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

    // 更新 API 客户端的配置
    _apiClient.updateConfig(host, token);

    return const Success(unit);
  }

  AsyncResult<(String, String)> getApiConfig() async {
    var host = await _prefsService.getReadeckApiHost();
    if (host.isError()) {
      appLogger.e("获取API配置失败(host)", error: host.exceptionOrNull());
      return Failure(Exception(host.exceptionOrNull()));
    }

    var token = await _prefsService.getReadeckApiToken();
    if (token.isError()) {
      appLogger.e("获取API配置失败(token)", error: token.exceptionOrNull());
      return Failure(Exception(token.exceptionOrNull()));
    }

    return Success((host.getOrThrow(), token.getOrThrow()));
  }

  /// 保存 OpenRouter API Key
  AsyncResult<void> saveOpenRouterApiKey(String apiKey) async {
    final result = await _prefsService.setOpenRouterApiKey(apiKey);
    if (result.isError()) {
      appLogger.e("保存OpenRouter API Key失败", error: result.exceptionOrNull());
      return result;
    }
    return const Success(unit);
  }

  /// 获取 OpenRouter API Key
  AsyncResult<String> getOpenRouterApiKey() async {
    final result = await _prefsService.getOpenRouterApiKey();
    if (result.isError()) {
      appLogger.e("获取OpenRouter API Key失败", error: result.exceptionOrNull());
      return Failure(Exception(result.exceptionOrNull()));
    }

    return Success(result.getOrThrow());
  }

  /// 保存翻译服务提供方
  AsyncResult<void> saveTranslationProvider(String provider) async {
    final result = await _prefsService.setTranslationProvider(provider);
    if (result.isError()) {
      appLogger.e("保存翻译服务提供方失败", error: result.exceptionOrNull());
      return result;
    }
    return const Success(unit);
  }

  /// 获取翻译服务提供方
  AsyncResult<String> getTranslationProvider() async {
    final result = await _prefsService.getTranslationProvider();
    if (result.isError()) {
      appLogger.e("获取翻译服务提供方失败", error: result.exceptionOrNull());
      return Failure(Exception(result.exceptionOrNull()));
    }
    return Success(result.getOrThrow());
  }

  /// 保存翻译目标语种
  AsyncResult<void> saveTranslationTargetLanguage(String language) async {
    final result = await _prefsService.setTranslationTargetLanguage(language);
    if (result.isError()) {
      appLogger.e("保存翻译目标语种失败", error: result.exceptionOrNull());
      return result;
    }
    return const Success(unit);
  }

  /// 获取翻译目标语种
  AsyncResult<String> getTranslationTargetLanguage() async {
    final result = await _prefsService.getTranslationTargetLanguage();
    if (result.isError()) {
      appLogger.e("获取翻译目标语种失败", error: result.exceptionOrNull());
      return Failure(Exception(result.exceptionOrNull()));
    }
    return Success(result.getOrThrow());
  }

  /// 保存翻译缓存启用状态
  AsyncResult<void> saveTranslationCacheEnabled(bool enabled) async {
    final result = await _prefsService.setTranslationCacheEnabled(enabled);
    if (result.isError()) {
      appLogger.e("保存翻译缓存启用状态失败", error: result.exceptionOrNull());
      return result;
    }
    return const Success(unit);
  }

  /// 获取翻译缓存启用状态
  AsyncResult<bool> getTranslationCacheEnabled() async {
    final result = await _prefsService.getTranslationCacheEnabled();
    if (result.isError()) {
      appLogger.e("获取翻译缓存启用状态失败", error: result.exceptionOrNull());
      return Failure(Exception(result.exceptionOrNull()));
    }
    return Success(result.getOrThrow());
  }

  /// 清空所有翻译缓存
  AsyncResult<void> clearTranslationCache() async {
    final result = await _databaseService.clearAllTranslationCache();
    if (result.isError()) {
      appLogger.e("清空翻译缓存失败", error: result.exceptionOrNull());
      return result;
    }
    return const Success(unit);
  }

  /// 获取 OpenRouter 可用模型列表
  AsyncResult<List<OpenRouterModel>> getOpenRouterModels(
      {String? category}) async {
    final result = await _openRouterApiClient.getModels(category: category);
    if (result.isError()) {
      appLogger.e("获取OpenRouter模型列表失败", error: result.exceptionOrNull());
      return result;
    }
    return result;
  }

  /// 保存选中的 OpenRouter 模型
  AsyncResult<void> saveSelectedOpenRouterModel(String modelId) async {
    final result = await _prefsService.setSelectedOpenRouterModel(modelId);
    if (result.isError()) {
      appLogger.e("保存选中的OpenRouter模型失败", error: result.exceptionOrNull());
      return result;
    }
    return const Success(unit);
  }

  /// 获取选中的 OpenRouter 模型
  AsyncResult<String> getSelectedOpenRouterModel() async {
    final result = await _prefsService.getSelectedOpenRouterModel();
    if (result.isError()) {
      appLogger.e("获取选中的OpenRouter模型失败", error: result.exceptionOrNull());
      return Failure(Exception(result.exceptionOrNull()));
    }
    return Success(result.getOrThrow());
  }
}
