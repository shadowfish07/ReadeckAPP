import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/main.dart';

class AiSettingsViewModel extends ChangeNotifier {
  AiSettingsViewModel(this._settingsRepository) {
    _initCommands();
  }

  final SettingsRepository _settingsRepository;

  String _openRouterApiKey = '';
  String get openRouterApiKey => _openRouterApiKey;

  late Command<String, void> saveApiKey;
  late Command<void, void> loadApiKey;

  void _initCommands() {
    saveApiKey = Command.createAsyncNoResult<String>(
      _saveApiKey,
    );

    loadApiKey = Command.createAsyncNoParam(
      _loadApiKeyAsync,
      initialValue: null,
    )..execute();
  }

  Future<void> _saveApiKey(String apiKey) async {
    final result = await _settingsRepository.saveOpenRouterApiKey(apiKey);
    if (result.isSuccess()) {
      _openRouterApiKey = apiKey;
      notifyListeners();
    } else {
      appLogger.e('保存 OpenRouter API 密钥失败', error: result.exceptionOrNull()!);
      throw result.exceptionOrNull()!;
    }
  }

  Future<void> _loadApiKeyAsync() async {
    final result = await _settingsRepository.getOpenRouterApiKey();
    if (result.isSuccess()) {
      _openRouterApiKey = result.getOrNull() ?? '';
      notifyListeners();
    } else {
      appLogger.e('获取 OpenRouter API 密钥失败', error: result.exceptionOrNull()!);
      _openRouterApiKey = '';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    saveApiKey.dispose();
    loadApiKey.dispose();
    super.dispose();
  }
}
