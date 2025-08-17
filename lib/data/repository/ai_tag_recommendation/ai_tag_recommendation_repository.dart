import 'package:readeck_app/data/service/openrouter_api_client.dart';
import 'package:readeck_app/data/service/web_content_service.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/main.dart';
import 'package:result_dart/result_dart.dart';

/// AI标签推荐Repository
/// 基于网页内容和现有标签，通过OpenRouter API提供智能标签推荐
class AiTagRecommendationRepository {
  AiTagRecommendationRepository(
    this._openRouterApiClient,
    this._settingsRepository,
  );

  final OpenRouterApiClient _openRouterApiClient;
  final SettingsRepository _settingsRepository;

  /// 检查AI标签推荐是否可用
  bool get isAvailable {
    final apiKey = _settingsRepository.getOpenRouterApiKey();
    final selectedModel = _settingsRepository.getSelectedOpenRouterModel();
    return apiKey.isNotEmpty && selectedModel.isNotEmpty;
  }

  /// 基于网页内容生成标签推荐
  ///
  /// [webContent] - 网页内容
  /// [existingTags] - 现有的标签列表，用于参考
  /// [maxTags] - 最大推荐标签数量，默认5个
  ///
  /// 返回推荐的标签列表
  AsyncResult<List<String>> generateTagRecommendations(
    WebContent webContent,
    List<String> existingTags, {
    int maxTags = 5,
  }) async {
    if (!isAvailable) {
      appLogger.w('AI标签推荐功能不可用：未配置API密钥或模型');
      return Failure(Exception('AI标签推荐功能不可用：请先配置OpenRouter API密钥和模型'));
    }

    try {
      appLogger.i('开始生成AI标签推荐 - URL: ${webContent.url}');

      final selectedModel = _settingsRepository.getSelectedOpenRouterModel();
      final prompt = _buildPrompt(webContent, existingTags, maxTags);

      appLogger.d('使用模型: $selectedModel');
      appLogger.d('生成的prompt长度: ${prompt.length}');

      // 调用OpenRouter API
      final result = await _openRouterApiClient.chatCompletion(
        model: selectedModel,
        messages: [
          {'role': 'user', 'content': prompt},
        ],
        temperature: 0.3, // 较低的温度确保结果更加一致和可预测
        maxTokens: 200, // 限制token数量
      );

      if (result.isSuccess()) {
        final response = result.getOrThrow();
        final tags = _parseTagsFromResponse(response);

        appLogger.i('AI标签推荐生成成功，共${tags.length}个标签: ${tags.join(", ")}');
        return Success(tags);
      } else {
        final error = result.exceptionOrNull()!;
        appLogger.e('AI标签推荐失败', error: error);
        return Failure(error);
      }
    } catch (e) {
      appLogger.e('生成AI标签推荐时发生异常', error: e);
      return Failure(Exception('生成AI标签推荐时发生异常: $e'));
    }
  }

  /// 构建发送给AI的prompt
  String _buildPrompt(
      WebContent webContent, List<String> existingTags, int maxTags) {
    final buffer = StringBuffer();

    buffer.writeln('请基于以下网页内容为这个书签推荐合适的标签。');
    buffer.writeln();

    // 网页信息
    buffer.writeln('网页标题: ${webContent.title}');
    buffer.writeln('网页URL: ${webContent.url}');
    buffer.writeln();

    // 网页内容（截取前1000字符避免token过多）
    final contentPreview = webContent.content.length > 1000
        ? '${webContent.content.substring(0, 1000)}...'
        : webContent.content;
    buffer.writeln('网页内容摘要:');
    buffer.writeln(contentPreview);
    buffer.writeln();

    // 现有标签
    if (existingTags.isNotEmpty) {
      buffer.writeln('系统中已有的标签供参考（优先使用这些标签）:');
      buffer.writeln(existingTags.join(', '));
      buffer.writeln();
    }

    // 要求和约束
    buffer.writeln('要求:');
    buffer.writeln('1. 推荐最多$maxTags个最相关的标签');
    buffer.writeln('2. 标签应该简洁、准确地描述内容主题');
    buffer.writeln('3. 优先使用已有标签，如果不合适再创建新标签');
    buffer.writeln('4. 标签使用中文，长度控制在2-8个字符');
    buffer.writeln('5. 只返回标签名称，用逗号分隔，不要其他解释文字');
    buffer.writeln();

    buffer.writeln('请直接返回推荐的标签（用逗号分隔）:');

    return buffer.toString();
  }

  /// 从AI响应中解析标签列表
  List<String> _parseTagsFromResponse(String response) {
    try {
      // 清理响应文本
      String cleanResponse = response.trim();

      // 移除可能的前缀文字
      final prefixPatterns = [
        RegExp(r'^推荐的标签[:：]\s*'),
        RegExp(r'^标签[:：]\s*'),
        RegExp(r'^建议标签[:：]\s*'),
        RegExp(r'^Tags[:：]\s*'),
      ];

      for (final pattern in prefixPatterns) {
        cleanResponse = cleanResponse.replaceFirst(pattern, '');
      }

      // 按逗号、分号或换行符分割
      final tags = cleanResponse
          .split(RegExp(r'[,，;；\n]'))
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty && tag.length <= 10) // 过滤空标签和过长标签
          .take(8) // 限制最大数量
          .toList();

      appLogger.d('解析标签结果: $tags');
      return tags;
    } catch (e) {
      appLogger.w('解析AI响应时出错: $e, 原始响应: $response');
      return [];
    }
  }
}
