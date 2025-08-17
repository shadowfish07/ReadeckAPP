import 'dart:convert';
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
      final targetLanguage = _settingsRepository.getAiTagTargetLanguage();

      final systemPrompt = _buildSystemPrompt();
      final userPrompt =
          _buildUserPrompt(webContent, existingTags, maxTags, targetLanguage);

      appLogger.d('使用模型: $selectedModel');
      appLogger.d('目标语言: $targetLanguage');
      appLogger.d('系统提示词长度: ${systemPrompt.length}');
      appLogger.d('用户提示词长度: ${userPrompt.length}');

      // 最多重试3次
      for (int attempt = 1; attempt <= 3; attempt++) {
        appLogger.d('第 $attempt 次尝试生成标签');

        // 调用OpenRouter API
        final result = await _openRouterApiClient.chatCompletion(
          model: selectedModel,
          messages: [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          temperature: 0.3, // 较低的温度确保结果更加一致和可预测
          maxTokens: 200, // 限制token数量
        );

        if (result.isSuccess()) {
          final response = result.getOrThrow();
          final tags = _parseTagsFromResponse(response);

          if (tags.isNotEmpty) {
            appLogger.i('AI标签推荐生成成功，共${tags.length}个标签: ${tags.join(", ")}');
            return Success(tags);
          } else {
            appLogger.w('第 $attempt 次尝试：标签解析失败，AI响应: $response');
            if (attempt == 3) {
              return Failure(Exception('AI标签推荐失败：经过3次尝试，无法解析有效的标签'));
            }
          }
        } else {
          final error = result.exceptionOrNull()!;
          appLogger.e('第 $attempt 次尝试：API调用失败', error: error);
          if (attempt == 3) {
            return Failure(error);
          }
        }
      }

      return Failure(Exception('AI标签推荐失败：经过3次尝试仍然失败'));
    } catch (e) {
      appLogger.e('生成AI标签推荐时发生异常', error: e);
      return Failure(Exception('生成AI标签推荐时发生异常: $e'));
    }
  }

  /// 构建系统提示词
  String _buildSystemPrompt() {
    // 预留系统提示词占位符，等待后续填充
    return '''
Assign the most appropriate label(s) to the provided web page content. You will receive the following inputs: the web page content, a list of existing labels, and the expected label language. If suitable, prioritize using the existing labels. If none of the existing labels fit, generate a new label in the requested language that best describes the web page content.

-  Carefully analyze the web page content to understand its main topics, themes, or purpose.
-  Compare your understanding with the existing labels and select the most relevant ones.
-  If no existing label is appropriate, generate a new, concise, and descriptive label in the specified language.
-  Do not include any explanations or reasoning in your output—only output the final label(s).

# Steps

1. Analyze the provided web page content to identify its main topic or purpose.
2. Review the list of existing labels.
3. Select the most relevant existing label(s) that match the content.
4. If no existing label is suitable, create a new label in the expected language.
5. Output the label(s) as a JSON array of strings.

# Output Format

Output only a JSON array of strings containing the assigned label(s). Do not include any explanations or additional text.

# Examples

**Example 1**

Input:
-  Web page content: "[Placeholder for a news article about electric vehicles]"
-  Existing labels: ["Technology", "Automotive", "Environment"]
-  Expected label language: "English"

Output:
["Automotive"]

**Example 2**

Input:
-  Web page content: "[Placeholder for a tutorial on baking bread]"
-  Existing labels: ["Cooking", "Technology", "Travel"]
-  Expected label language: "English"

Output:
["Cooking"]

**Example 3**

Input:
-  Web page content: "[Placeholder for a blog about meditation techniques]"
-  Existing labels: ["Fitness", "Wellness"]
-  Expected label language: "English"

Output:
["Wellness"]

**Example 4**

Input:
-  Web page content: "[Placeholder for a guide to starting a business in China]"
-  Existing labels: ["Travel", "Technology"]
-  Expected label language: "English"

Output:
["Business"]

# Notes

-  Always use the expected label language for any new label.
-  If multiple existing labels are relevant, output all of them.
-  The output must be a pure JSON array, without code blocks or extra formatting.


''';
  }

  /// 构建用户提示词，包含目标语言、已存在的标签和网页内容
  String _buildUserPrompt(WebContent webContent, List<String> existingTags,
      int maxTags, String targetLanguage) {
    final buffer = StringBuffer();

    // 目标语言
    buffer.writeln('# 目标语言');
    buffer.writeln(targetLanguage);
    buffer.writeln();

    // 已存在的标签
    buffer.writeln('# 已存在的标签');
    if (existingTags.isNotEmpty) {
      buffer.writeln(existingTags.join(', '));
    } else {
      buffer.writeln('无');
    }
    buffer.writeln();

    // 网页内容（全文输入，无需截断）
    buffer.writeln('# 网页内容');
    buffer.writeln('标题: ${webContent.title}');
    buffer.writeln('URL: ${webContent.url}');
    buffer.writeln();
    buffer.writeln('内容:');
    buffer.writeln(webContent.content);

    return buffer.toString();
  }

  /// 从AI响应中解析标签列表
  /// 只处理JSON数组格式，如: ["Wellness", "Technology"]
  List<String> _parseTagsFromResponse(String response) {
    try {
      // 清理响应文本
      String cleanResponse = response.trim();
      appLogger.d('原始AI响应: $cleanResponse');

      // 查找JSON数组的开始和结束位置
      final startIndex = cleanResponse.indexOf('[');
      final endIndex = cleanResponse.lastIndexOf(']');

      if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) {
        appLogger.w('响应中未找到有效的JSON数组格式');
        return [];
      }

      // 提取JSON数组部分
      final jsonPart = cleanResponse.substring(startIndex, endIndex + 1);
      appLogger.d('提取的JSON部分: $jsonPart');

      // 解析JSON数组
      final List<dynamic> jsonList = jsonDecode(jsonPart);
      final tags = jsonList
          .cast<String>()
          .where((tag) => tag.isNotEmpty && tag.length <= 15)
          .take(8)
          .toList();

      appLogger.d('JSON格式解析标签结果: $tags');
      return tags;
    } catch (e) {
      appLogger.w('JSON解析失败: $e, 原始响应: $response');
      return [];
    }
  }
}
