import 'package:flutter/foundation.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/openrouter/openrouter_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/domain/models/openrouter_model/openrouter_model.dart';
import 'package:readeck_app/main.dart';

class ModelSelectionViewModel extends ChangeNotifier {
  ModelSelectionViewModel(
      this._settingsRepository, this._openRouterRepository) {
    _initCommands();
  }

  final SettingsRepository _settingsRepository;
  final OpenRouterRepository _openRouterRepository;

  List<OpenRouterModel> _availableModels = [];
  List<OpenRouterModel> get availableModels {
    if (_selectedModelId != null &&
        _selectedModelId!.isNotEmpty &&
        _availableModels.isNotEmpty) {
      // 创建副本以避免修改原始列表
      final sortedModels = List<OpenRouterModel>.from(_availableModels);
      // 找到选中的模型
      final selectedModel = sortedModels
          .where((model) => model.id == _selectedModelId)
          .firstOrNull;
      if (selectedModel != null) {
        // 移除选中的模型
        sortedModels.removeWhere((model) => model.id == _selectedModelId);
        // 将选中的模型插入到第一位
        sortedModels.insert(0, selectedModel);
      }
      return sortedModels;
    }
    return _availableModels;
  }

  String? _selectedModelId;
  OpenRouterModel? get selectedModel {
    if (_selectedModelId == null ||
        _selectedModelId!.isEmpty ||
        _availableModels.isEmpty) {
      return null;
    }
    return _availableModels
        .where((model) => model.id == _selectedModelId)
        .firstOrNull;
  }

  late Command<void, List<OpenRouterModel>> loadModels;
  late Command<void, void> loadSelectedModel;

  void _initCommands() {
    loadModels = Command.createAsyncNoParam(_loadModelsAsync,
        initialValue: [], includeLastResultInCommandResults: true)
      ..execute();

    loadSelectedModel = Command.createAsyncNoParam(
      _loadSelectedModel,
      initialValue: null,
    )..execute();
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

  void selectModel(OpenRouterModel model) {
    _selectedModelId = model.id;
    notifyListeners();
    // 自动保存选中的模型
    _saveSelectedModel(model.id);
  }

  Future<void> _saveSelectedModel(String modelId) async {
    final result =
        await _settingsRepository.saveSelectedOpenRouterModel(modelId);
    if (result.isSuccess()) {
      appLogger.d('成功保存选中的模型: $modelId');
    } else {
      appLogger.e('保存选中的模型失败', error: result.exceptionOrNull()!);
      throw '保存选中的模型失败';
    }
  }

  Future<void> _loadSelectedModel() async {
    try {
      final selectedModelId = _settingsRepository.getSelectedOpenRouterModel();
      if (selectedModelId.isNotEmpty) {
        _selectedModelId = selectedModelId;
        appLogger.d('成功加载选中的模型ID: $selectedModelId');
        notifyListeners();
      }
    } catch (e) {
      appLogger.e('加载选中的模型异常', error: e);
    }
  }

  @override
  void dispose() {
    loadModels.dispose();
    loadSelectedModel.dispose();
    super.dispose();
  }
}
