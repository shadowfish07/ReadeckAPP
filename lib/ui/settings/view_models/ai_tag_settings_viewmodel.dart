import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/main.dart';

class AiTagSettingsViewModel extends ChangeNotifier {
  AiTagSettingsViewModel(this._settingsRepository) {
    _loadSettings();
    _initializeCommands();
    _listenToSettingsChanges();
  }

  final SettingsRepository _settingsRepository;

  StreamSubscription<void>? _settingsSubscription;

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

  String get aiTagTargetLanguage =>
      _settingsRepository.getAiTagTargetLanguage();
  String get aiTagModel => _settingsRepository.getAiTagModel();
  String get aiTagModelName => _settingsRepository.getAiTagModelName();

  void _loadSettings() {
    // 不需要在ViewModel中缓存数据，直接通过getter访问Repository即可
  }

  void _initializeCommands() {
    saveAiTagTargetLanguage =
        Command.createAsyncNoResult((String language) async {
      appLogger.i('开始保存AI标签目标语言: $language');

      final result =
          await _settingsRepository.saveAiTagTargetLanguage(language);

      if (result.isSuccess()) {
        notifyListeners();
        appLogger.i('AI标签目标语言保存成功: $language');
      } else {
        final error = result.exceptionOrNull()!;
        appLogger.e('保存AI标签目标语言失败', error: error);
        throw error;
      }
    });
  }

  void _listenToSettingsChanges() {
    _settingsSubscription = _settingsRepository.settingsChanged.listen((_) {
      appLogger.d('AI标签设置页面收到配置变更通知，刷新页面');
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    saveAiTagTargetLanguage.dispose();
    super.dispose();
  }
}
