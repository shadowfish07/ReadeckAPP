import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/main.dart';

class AiTagSettingsViewModel extends ChangeNotifier {
  AiTagSettingsViewModel(this._settingsRepository) {
    _loadSettings();
    _initializeCommands();
  }

  final SettingsRepository _settingsRepository;

  String _aiTagTargetLanguage = '中文';

  late final Command<String, void> saveAiTagTargetLanguage;

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

  void _loadSettings() {
    _aiTagTargetLanguage = _settingsRepository.getAiTagTargetLanguage();
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
  }
}
