import 'dart:async';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;
import 'package:readeck_app/main.dart';
import 'package:readeck_app/utils/network_error_exception.dart';
import 'package:result_dart/result_dart.dart';

/// 网页内容获取服务
/// 负责抓取URL对应的网页内容并解析标题
class WebContentService {
  WebContentService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  /// 释放资源
  void dispose() {
    _httpClient.close();
  }

  /// 获取网页内容和标题
  ///
  /// [url] - 要抓取的网页URL
  /// [timeout] - 请求超时时间，默认10秒
  ///
  /// 返回包含标题和内容的WebContent对象
  AsyncResult<WebContent> fetchWebContent(
    String url, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      appLogger.i('开始获取网页内容: $url');

      // 验证URL格式
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        appLogger.w('无效的URL格式: $url');
        return Failure(Exception('无效的URL格式'));
      }

      // 发起HTTP请求
      final response =
          await _httpClient.get(uri, headers: _getHeaders()).timeout(timeout);

      if (response.statusCode == 200) {
        // 解析HTML内容
        final document = html_parser.parse(response.body);
        final title = _extractTitle(document);
        final content = _extractContent(document);

        appLogger.i('成功获取网页内容 - 标题: $title');

        return Success(WebContent(
          url: url,
          title: title,
          content: content,
        ));
      } else {
        appLogger.w('网页请求失败，状态码: ${response.statusCode}');
        return Failure(NetworkErrorException(
          '网页请求失败',
          uri,
          response.statusCode,
        ));
      }
    } on TimeoutException {
      appLogger.w('网页请求超时: $url');
      return Failure(TimeoutException('网页请求超时', timeout));
    } catch (e) {
      appLogger.e('获取网页内容失败: $url', error: e);
      return Failure(Exception('获取网页内容失败: $e'));
    }
  }

  /// 获取请求头
  Map<String, String> _getHeaders() => {
        'User-Agent': 'Mozilla/5.0 (compatible; ReadeckApp/1.0)',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate',
        'Connection': 'keep-alive',
      };

  /// 提取网页标题
  String _extractTitle(dom.Document document) {
    // 优先级：title标签 > og:title > h1标签

    // 1. 尝试获取title标签
    final titleElement = document.querySelector('title');
    if (titleElement != null && titleElement.text.trim().isNotEmpty) {
      return titleElement.text.trim();
    }

    // 2. 尝试获取og:title
    final ogTitleElement = document.querySelector('meta[property="og:title"]');
    if (ogTitleElement != null) {
      final ogTitle = ogTitleElement.attributes['content'];
      if (ogTitle != null && ogTitle.trim().isNotEmpty) {
        return ogTitle.trim();
      }
    }

    // 3. 尝试获取第一个h1标签
    final h1Element = document.querySelector('h1');
    if (h1Element != null && h1Element.text.trim().isNotEmpty) {
      return h1Element.text.trim();
    }

    // 4. 如果都没有，返回空字符串
    appLogger.w('无法提取网页标题');
    return '';
  }

  /// 提取网页主要内容
  String _extractContent(dom.Document document) {
    // 移除不需要的元素
    _removeUnwantedElements(document);

    // 尝试获取主要内容
    final contentSelectors = [
      'article',
      'main',
      '.content',
      '.post-content',
      '.article-content',
      '.entry-content',
      '#content',
      '#main-content',
    ];

    for (final selector in contentSelectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final text = element.text.trim();
        if (text.length > 100) {
          // 限制内容长度，避免过长
          return text.length > 5000 ? text.substring(0, 5000) : text;
        }
      }
    }

    // 如果没找到主要内容区域，返回body的文本（去除脚本和样式）
    final bodyText = document.body?.text.trim() ?? '';
    return bodyText.length > 5000 ? bodyText.substring(0, 5000) : bodyText;
  }

  /// 移除不需要的HTML元素
  void _removeUnwantedElements(dom.Document document) {
    final unwantedSelectors = [
      'script',
      'style',
      'nav',
      'header',
      'footer',
      '.navigation',
      '.sidebar',
      '.comments',
      '.advertisement',
      '.ads',
    ];

    for (final selector in unwantedSelectors) {
      document.querySelectorAll(selector).forEach((element) {
        element.remove();
      });
    }
  }
}

/// 网页内容数据模型
class WebContent {
  const WebContent({
    required this.url,
    required this.title,
    required this.content,
  });

  final String url;
  final String title;
  final String content;

  @override
  String toString() {
    return 'WebContent(url: $url, title: $title, contentLength: ${content.length})';
  }
}
