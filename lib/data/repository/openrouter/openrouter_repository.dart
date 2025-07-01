import 'package:readeck_app/data/service/openrouter_api_client.dart';
import 'package:readeck_app/domain/models/openrouter_model/openrouter_model.dart';
import 'package:readeck_app/main.dart';
import 'package:result_dart/result_dart.dart';

class OpenRouterRepository {
  OpenRouterRepository(this._openRouterApiClient);

  final OpenRouterApiClient _openRouterApiClient;

  /// 获取 OpenRouter 可用模型列表
  /// 此方法需要网络请求，保持异步
  AsyncResult<List<OpenRouterModel>> getModels({String? category}) async {
    final result = await _openRouterApiClient.getModels(category: category);
    if (result.isError()) {
      appLogger.e("获取OpenRouter模型列表失败", error: result.exceptionOrNull());
      return result;
    }
    return result;
  }
}
