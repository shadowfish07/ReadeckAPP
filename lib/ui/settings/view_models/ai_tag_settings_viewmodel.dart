import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/openrouter/openrouter_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/domain/models/openrouter_model/openrouter_model.dart';
import 'package:readeck_app/main.dart';

class AiTagSettingsViewModel extends ChangeNotifier {
  AiTagSettingsViewModel(this._settingsRepository, this._openRouterRepository) {
    _loadSettings();
    _initializeCommands();
  }

  final SettingsRepository _settingsRepository;
  final OpenRouterRepository _openRouterRepository;

  String _aiTagTargetLanguage = '中文';
  String _aiTagModel = '';
  List<OpenRouterModel> _availableModels = [];

  late final Command<String, void> saveAiTagTargetLanguage;
  late final Command<String, void> saveAiTagModel;
  late final Command<void, List<OpenRouterModel>> loadModels;

  static const List<String> supportedLanguages = [
    '中文',
    'English',
    '日本語',
    'Français',
    'Deutsch',
    'Español',
    'Русский',
    '한국어',
  ];

  String get aiTagTargetLanguage => _aiTagTargetLanguage;
  String get aiTagModel => _aiTagModel;
  List<OpenRouterModel> get availableModels => _availableModels;

  OpenRouterModel? get selectedAiTagModel {
    if (_aiTagModel.isEmpty || _availableModels.isEmpty) {
      return null;
    }
    return _availableModels
        .where((model) => model.id == _aiTagModel)
        .firstOrNull;
  }

  void _loadSettings() {
    _aiTagTargetLanguage = _settingsRepository.getAiTagTargetLanguage();
    _aiTagModel = _settingsRepository.getAiTagModel();
  }

  void _initializeCommands() {
    saveAiTagTargetLanguage =
        Command.createAsyncNoResult((String language) async {
      appLogger.i('开始保存AI标签目标语言: $language');

      final result =
          await _settingsRepository.saveAiTagTargetLanguage(language);

      if (result.isSuccess()) {
        _aiTagTargetLanguage = language;
        notifyListeners();
        appLogger.i('AI标签目标语言保存成功: $language');
      } else {
        final error = result.exceptionOrNull()!;
        appLogger.e('保存AI标签目标语言失败', error: error);
        throw error;
      }
    });

    saveAiTagModel = Command.createAsyncNoResult((String modelId) async {
      appLogger.i('开始保存AI标签模型: $modelId');

      final result = await _settingsRepository.saveAiTagModel(modelId);

      if (result.isSuccess()) {
        _aiTagModel = modelId;
        notifyListeners();
        appLogger.i('AI标签模型保存成功: $modelId');
      } else {
        final error = result.exceptionOrNull()!;
        appLogger.e('保存AI标签模型失败', error: error);
        throw error;
      }
    });

    loadModels = Command.createAsyncNoParam(_loadModelsAsync,
        initialValue: [], includeLastResultInCommandResults: true)
      ..execute();
  }

  Future<List<OpenRouterModel>> _loadModelsAsync() async {
    final result = await _openRouterRepository.getModels(category: 'ai_tag');
    if (result.isSuccess()) {
      _availableModels = result.getOrNull() ?? [];
      appLogger.d('成功加载 ${_availableModels.length} 个OpenRouter AI标签模型');
      notifyListeners();
      return _availableModels;
    } else {
      appLogger.e('获取OpenRouter AI标签模型列表失败', error: result.exceptionOrNull()!);
      _availableModels = [];
      notifyListeners();
      throw result.exceptionOrNull()!;
    }
  }

  void selectAiTagModel(OpenRouterModel model) {
    saveAiTagModel.execute(model.id);
  }

  void clearAiTagModel() {
    saveAiTagModel.execute('');
  }
}
