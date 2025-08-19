import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/openrouter/openrouter_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/domain/models/openrouter_model/openrouter_model.dart';
import 'package:readeck_app/main.dart';

class AiSettingsViewModel extends ChangeNotifier {
  AiSettingsViewModel(this._settingsRepository, this._openRouterRepository) {
    _initCommands();
  }

  final SettingsRepository _settingsRepository;
  final OpenRouterRepository _openRouterRepository;

  String get openRouterApiKey => _settingsRepository.getOpenRouterApiKey();

  // 缓存从API获取的模型详情，用于selectedModel getter
  OpenRouterModel? _selectedModel;
  OpenRouterModel? get selectedModel => _selectedModel;

  String get selectedModelName =>
      _settingsRepository.getSelectedOpenRouterModelName();

  late Command<String, void> saveApiKey;
  late Command<void, void> loadApiKey;
  late Command<void, void> loadSelectedModel;
  late Command<String, String> textChangedCommand;

  void _initCommands() {
    saveApiKey = Command.createAsyncNoResult<String>(
      _saveApiKey,
    );

    loadApiKey = Command.createAsyncNoParam(
      _loadApiKeyAsync,
      initialValue: null,
    )..execute();

    loadSelectedModel = Command.createAsyncNoParam(
      _loadSelectedModelAsync,
      initialValue: null,
    )..execute();

    // 文本变化命令，用于防抖处理
    textChangedCommand = Command.createSync((s) => s, initialValue: '');

    // 设置防抖，500ms 后执行保存
    textChangedCommand.debounce(const Duration(milliseconds: 500)).listen(
      (filterText, _) {
        if (filterText.trim() != _settingsRepository.getOpenRouterApiKey()) {
          saveApiKey.execute(filterText.trim());
        }
      },
    );
  }

  Future<void> _saveApiKey(String apiKey) async {
    final result = await _settingsRepository.saveOpenRouterApiKey(apiKey);
    if (result.isSuccess()) {
      notifyListeners();
    } else {
      appLogger.e('保存 OpenRouter API 密钥失败', error: result.exceptionOrNull()!);
      throw result.exceptionOrNull()!;
    }
  }

  Future<void> _loadApiKeyAsync() async {
    // 不需要在ViewModel中缓存数据，直接通过getter访问Repository即可
    notifyListeners();
  }

  Future<void> _loadSelectedModelAsync() async {
    try {
      final selectedModelId = _settingsRepository.getSelectedOpenRouterModel();

      // 优先显示缓存的模型名称，避免闪动
      final cachedModelName =
          _settingsRepository.getSelectedOpenRouterModelName();
      if (cachedModelName.isNotEmpty) {
        appLogger.d('成功加载缓存的模型名称: $cachedModelName');
        notifyListeners();
      }

      if (selectedModelId.isNotEmpty) {
        // 需要从 Repository 获取模型详情
        final modelsResult = await _openRouterRepository.getModels();
        if (modelsResult.isSuccess()) {
          final availableModels = modelsResult.getOrNull() ?? [];
          final matchedModel = availableModels
              .where((model) => model.id == selectedModelId)
              .firstOrNull;
          if (matchedModel != null) {
            _selectedModel = matchedModel;
            // 如果API返回的模型名称与缓存不一致，更新缓存
            if (cachedModelName != matchedModel.name) {
              appLogger.d('更新模型名称缓存: ${matchedModel.name}');
            }
            appLogger.d('成功加载选中的模型: $selectedModelId (${matchedModel.name})');
            notifyListeners();
          }
        } else {
          appLogger.e('加载模型列表失败', error: modelsResult.exceptionOrNull()!);
        }
      }
    } catch (e) {
      appLogger.e('加载选中的模型异常', error: e);
    }
  }

  @override
  void dispose() {
    saveApiKey.dispose();
    loadApiKey.dispose();
    loadSelectedModel.dispose();
    textChangedCommand.dispose();
    super.dispose();
  }
}
