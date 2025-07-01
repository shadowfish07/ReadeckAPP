import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:result_dart/result_dart.dart';

class ApiConfigViewModel {
  ApiConfigViewModel(this._settingsRepository) {
    save = Command.createAsyncNoResult<(String, String)>(_save);
  }

  final SettingsRepository _settingsRepository;
  late Command save;

  AsyncResult<(String, String)> load() async {
    return Success(_settingsRepository.getApiConfig());
  }

  Future<void> _save((String host, String token) params) async {
    final (host, token) = params;
    final result = await _settingsRepository.saveApiConfig(host, token);
    if (result.isError()) {
      throw Exception(result.exceptionOrNull());
    }

    return;
  }
}
