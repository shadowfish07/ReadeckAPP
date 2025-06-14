import 'package:logger/logger.dart';
import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/data/service/shared_preference_service.dart';
import 'package:result_dart/result_dart.dart';

class SettingsRepository {
  SettingsRepository(this._apiClient, this._prefsService);

  final ReadeckApiClient _apiClient;
  final SharedPreferencesService _prefsService;
  final _log = Logger();

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
      _log.e("保存API配置失败(host)", error: res.exceptionOrNull());
      return res;
    }

    res = await _prefsService.setReadeckApiToken(token);
    if (res.isError()) {
      _log.e("保存API配置失败(token)", error: res.exceptionOrNull());
      return res;
    }

    // 更新 API 客户端的配置
    _apiClient.updateConfig(host, token);

    return const Success(unit);
  }

  AsyncResult<(String, String)> getApiConfig() async {
    var host = await _prefsService.getReadeckApiHost();
    if (host.isError()) {
      _log.e("获取API配置失败(host)", error: host.exceptionOrNull());
      return Failure(Exception(host.exceptionOrNull()));
    }

    var token = await _prefsService.getReadeckApiToken();
    if (token.isError()) {
      _log.e("获取API配置失败(token)", error: token.exceptionOrNull());
      return Failure(Exception(token.exceptionOrNull()));
    }

    return Success((host.getOrNull()!, token.getOrNull()!));
  }
}
