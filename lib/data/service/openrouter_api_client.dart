import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:readeck_app/data/service/shared_preference_service.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/utils/api_not_configured_exception.dart';
import 'package:readeck_app/utils/network_error_exception.dart';
import 'package:result_dart/result_dart.dart';

/// OpenRouter API 客户端
/// 提供与 OpenRouter API 的交互功能，支持流式聊天完成
class OpenRouterApiClient {
  OpenRouterApiClient(this._sharedPreferencesService,
      {String? baseUrl, http.Client? httpClient})
      : _baseUrl = baseUrl ?? 'https://openrouter.ai/api/v1',
        _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final SharedPreferencesService _sharedPreferencesService;
  final http.Client _httpClient;
  String? _apiKey;

  /// 释放资源
  void dispose() {
    _httpClient.close();
  }

  /// 初始化API密钥
  Future<void> _initApiKey() async {
    if (_apiKey == null) {
      final result = await _sharedPreferencesService.getOpenRouterApiKey();
      if (result.isSuccess()) {
        _apiKey = result.getOrNull();
      }
    }
  }

  /// 检查 API 是否已配置
  Future<bool> get isConfigured async {
    await _initApiKey();
    return _apiKey != null && _apiKey!.isNotEmpty;
  }

  /// 获取请求头
  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'X-Title': 'ReadeckApp',
      };

  /// 流式聊天完成
  ///
  /// [model] - 使用的模型名称，如 'openai/gpt-3.5-turbo'
  /// [messages] - 聊天消息列表
  /// [temperature] - 温度参数，控制输出的随机性 (0.0-2.0)
  /// [maxTokens] - 最大生成令牌数
  /// [topP] - 核采样参数
  /// [frequencyPenalty] - 频率惩罚
  /// [presencePenalty] - 存在惩罚
  Stream<Result<String>> streamChatCompletion({
    required String model,
    required List<Map<String, String>> messages,
    double? temperature,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
  }) async* {
    if (!(await isConfigured)) {
      yield Failure(ApiNotConfiguredException());
      return;
    }

    try {
      final uri = Uri.parse('$_baseUrl/chat/completions');
      final request = http.Request('POST', uri);

      request.headers.addAll(_headers);

      appLogger.d('OpenRouter API headers: $_headers');

      final requestBody = {
        'model': model,
        'messages': messages,
        'stream': true,
        if (temperature != null) 'temperature': temperature,
        if (maxTokens != null) 'max_tokens': maxTokens,
        if (topP != null) 'top_p': topP,
        if (frequencyPenalty != null) 'frequency_penalty': frequencyPenalty,
        if (presencePenalty != null) 'presence_penalty': presencePenalty,
      };

      request.body = jsonEncode(requestBody);

      appLogger.d('发送流式聊天请求到 OpenRouter: $uri');
      appLogger.d('请求体: ${jsonEncode(requestBody)}');

      final streamedResponse = await _httpClient.send(request);

      if (streamedResponse.statusCode != 200) {
        appLogger.w('OpenRouter API 请求失败。状态码: ${streamedResponse.statusCode}');
        // 读取错误响应的body内容
        final responseBody = await streamedResponse.stream.bytesToString();
        appLogger.w('响应body: $responseBody');
        yield Failure(NetworkErrorException(
          'OpenRouter API 请求失败: $responseBody',
          uri,
          streamedResponse.statusCode,
        ));
        return;
      }

      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();

            if (data == '[DONE]') {
              appLogger.d('OpenRouter 流式响应完成');
              return;
            }

            if (data.isEmpty) {
              continue;
            }

            try {
              final json = jsonDecode(data);
              final content = json['choices']?[0]?['delta']?['content'];

              if (content != null && content is String) {
                yield Success(content);
              }
            } catch (e) {
              appLogger.w('解析 OpenRouter 响应数据失败: $e, 数据: $data');
              // 忽略解析错误，继续处理下一行
              continue;
            }
          }
        }
      }
    } catch (e) {
      appLogger.w('OpenRouter 流式请求失败: $e');
      final uri = Uri.parse('$_baseUrl/chat/completions');
      yield Failure(NetworkErrorException('OpenRouter 流式请求失败', uri));
    }
  }

  /// 非流式聊天完成
  ///
  /// [model] - 使用的模型名称
  /// [messages] - 聊天消息列表
  /// [temperature] - 温度参数
  /// [maxTokens] - 最大生成令牌数
  /// [topP] - 核采样参数
  /// [frequencyPenalty] - 频率惩罚
  /// [presencePenalty] - 存在惩罚
  AsyncResult<String> chatCompletion({
    required String model,
    required List<Map<String, String>> messages,
    double? temperature,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
  }) async {
    if (!(await isConfigured)) {
      return Failure(ApiNotConfiguredException());
    }

    try {
      final uri = Uri.parse('$_baseUrl/chat/completions');

      final requestBody = {
        'model': model,
        'messages': messages,
        'stream': false,
        if (temperature != null) 'temperature': temperature,
        if (maxTokens != null) 'max_tokens': maxTokens,
        if (topP != null) 'top_p': topP,
        if (frequencyPenalty != null) 'frequency_penalty': frequencyPenalty,
        if (presencePenalty != null) 'presence_penalty': presencePenalty,
      };

      appLogger.d('发送聊天请求到 OpenRouter: $uri');

      final response = await _httpClient.post(
        uri,
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final content = responseData['choices']?[0]?['message']?['content'];

        if (content != null && content is String) {
          appLogger.d('OpenRouter 聊天请求成功');
          return Success(content);
        } else {
          appLogger.w('OpenRouter 响应格式异常: ${response.body}');
          return Failure(Exception('OpenRouter 响应格式异常'));
        }
      } else {
        appLogger.w('OpenRouter API 请求失败。状态码: ${response.statusCode}');
        return Failure(NetworkErrorException(
          'OpenRouter API 请求失败',
          uri,
          response.statusCode,
        ));
      }
    } catch (e) {
      appLogger.w('OpenRouter 请求失败: $e');
      final uri = Uri.parse('$_baseUrl/chat/completions');
      return Failure(NetworkErrorException('OpenRouter 请求失败', uri));
    }
  }

  /// 流式文本完成
  ///
  /// [model] - 使用的模型名称，如 'openai/gpt-3.5-turbo-instruct'
  /// [prompt] - 输入提示文本
  /// [temperature] - 温度参数，控制输出的随机性 (0.0-2.0)
  /// [maxTokens] - 最大生成令牌数
  /// [topP] - 核采样参数
  /// [frequencyPenalty] - 频率惩罚
  /// [presencePenalty] - 存在惩罚
  /// [stop] - 停止序列
  Stream<Result<String>> streamCompletion({
    required String model,
    required String prompt,
    double? temperature,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    List<String>? stop,
  }) async* {
    if (!(await isConfigured)) {
      yield Failure(ApiNotConfiguredException());
      return;
    }

    try {
      final uri = Uri.parse('$_baseUrl/completions');
      final request = http.Request('POST', uri);

      request.headers.addAll(_headers);

      appLogger.d('OpenRouter API headers: $_headers');

      final requestBody = {
        'model': model,
        'prompt': prompt,
        'stream': true,
        if (temperature != null) 'temperature': temperature,
        if (maxTokens != null) 'max_tokens': maxTokens,
        if (topP != null) 'top_p': topP,
        if (frequencyPenalty != null) 'frequency_penalty': frequencyPenalty,
        if (presencePenalty != null) 'presence_penalty': presencePenalty,
        if (stop != null) 'stop': stop,
      };

      request.body = jsonEncode(requestBody);

      appLogger.d('发送流式文本完成请求到 OpenRouter: $uri');
      appLogger.d('请求体: ${jsonEncode(requestBody)}');

      final streamedResponse = await _httpClient.send(request);

      if (streamedResponse.statusCode != 200) {
        appLogger.w('OpenRouter API 请求失败。状态码: ${streamedResponse.statusCode}');
        // 读取错误响应的body内容
        final responseBody = await streamedResponse.stream.bytesToString();
        appLogger.w('响应body: $responseBody');
        yield Failure(NetworkErrorException(
          'OpenRouter API 请求失败: $responseBody',
          uri,
          streamedResponse.statusCode,
        ));
        return;
      }

      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();

            if (data == '[DONE]') {
              appLogger.d('OpenRouter 流式响应完成');
              return;
            }

            if (data.isEmpty) {
              continue;
            }

            try {
              final json = jsonDecode(data);
              final content = json['choices']?[0]?['text'];

              if (content != null && content is String) {
                yield Success(content);
              }
            } catch (e) {
              appLogger.w('解析 OpenRouter 响应数据失败: $e, 数据: $data');
              // 忽略解析错误，继续处理下一行
              continue;
            }
          }
        }
      }
    } catch (e) {
      appLogger.w('OpenRouter 流式请求失败: $e');
      final uri = Uri.parse('$_baseUrl/completions');
      yield Failure(NetworkErrorException('OpenRouter 流式请求失败', uri));
    }
  }

  /// 非流式文本完成
  ///
  /// [model] - 使用的模型名称
  /// [prompt] - 输入提示文本
  /// [temperature] - 温度参数
  /// [maxTokens] - 最大生成令牌数
  /// [topP] - 核采样参数
  /// [frequencyPenalty] - 频率惩罚
  /// [presencePenalty] - 存在惩罚
  /// [stop] - 停止序列
  AsyncResult<String> completion({
    required String model,
    required String prompt,
    double? temperature,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    List<String>? stop,
  }) async {
    if (!(await isConfigured)) {
      return Failure(ApiNotConfiguredException());
    }

    try {
      final uri = Uri.parse('$_baseUrl/completions');

      final requestBody = {
        'model': model,
        'prompt': prompt,
        'stream': false,
        if (temperature != null) 'temperature': temperature,
        if (maxTokens != null) 'max_tokens': maxTokens,
        if (topP != null) 'top_p': topP,
        if (frequencyPenalty != null) 'frequency_penalty': frequencyPenalty,
        if (presencePenalty != null) 'presence_penalty': presencePenalty,
        if (stop != null) 'stop': stop,
      };

      appLogger.d('发送文本完成请求到 OpenRouter: $uri');

      final response = await _httpClient.post(
        uri,
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final content = responseData['choices']?[0]?['text'];

        if (content != null && content is String) {
          appLogger.d('OpenRouter 文本完成请求成功');
          return Success(content);
        } else {
          appLogger.w('OpenRouter 响应格式异常: ${response.body}');
          return Failure(Exception('OpenRouter 响应格式异常'));
        }
      } else {
        appLogger.w('OpenRouter API 请求失败。状态码: ${response.statusCode}');
        return Failure(NetworkErrorException(
          'OpenRouter API 请求失败',
          uri,
          response.statusCode,
        ));
      }
    } catch (e) {
      appLogger.w('OpenRouter 请求失败: $e');
      final uri = Uri.parse('$_baseUrl/completions');
      return Failure(NetworkErrorException('OpenRouter 请求失败', uri));
    }
  }

  /// 获取可用模型列表
  AsyncResult<List<Map<String, dynamic>>> getModels() async {
    if (!(await isConfigured)) {
      return Failure(ApiNotConfiguredException());
    }

    try {
      final uri = Uri.parse('$_baseUrl/models');

      appLogger.d('获取 OpenRouter 模型列表: $uri');

      final response = await _httpClient.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final models = responseData['data'] as List<dynamic>?;

        if (models != null) {
          appLogger.d('成功获取 ${models.length} 个模型');
          return Success(models.cast<Map<String, dynamic>>());
        } else {
          appLogger.w('模型列表响应格式异常: ${response.body}');
          return Failure(Exception('模型列表响应格式异常'));
        }
      } else {
        appLogger.w('获取模型列表失败。状态码: ${response.statusCode}');
        return Failure(NetworkErrorException(
          '获取模型列表失败',
          uri,
          response.statusCode,
        ));
      }
    } catch (e) {
      appLogger.w('获取模型列表请求失败: $e');
      final uri = Uri.parse('$_baseUrl/models');
      return Failure(NetworkErrorException('获取模型列表请求失败', uri));
    }
  }
}
