import 'dart:convert';

import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/bookmark/label_info.dart';
import 'package:http/http.dart' as http;
import 'package:readeck_app/main.dart';
import 'package:readeck_app/utils/api_not_configured_exception.dart';
import 'package:readeck_app/utils/article_empty_exception.dart';
import 'package:readeck_app/utils/network_error_exception.dart';
import 'package:readeck_app/utils/resource_not_found_exception.dart';
import 'package:result_dart/result_dart.dart';

class ReadeckApiClient {
  ReadeckApiClient(this._host, this._token, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  String? _host;
  String? _token;

  /// 更新API配置
  void updateConfig(String? host, String? token) {
    _host = host;
    _token = token;
  }

  /// 释放资源
  void dispose() {
    _httpClient.close();
  }

  bool get _isConfigured =>
      (_host != null && _host != '') && (_token != null && _token != '');

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

  /// 获取书签列表
  ///
  /// 支持所有 Readeck API 查询参数：
  /// - [search]: 全文搜索字符串
  /// - [title]: 书签标题
  /// - [author]: 作者姓名
  /// - [site]: 书签站点名称或域名
  /// - [type]: 书签类型 (article, photo, video)
  /// - [labels]: 一个或多个标签
  /// - [isLoaded]: 按加载状态过滤
  /// - [hasErrors]: 过滤有或没有错误的书签
  /// - [hasLabels]: 过滤有或没有标签的书签
  /// - [isMarked]: 按标记（收藏）状态过滤
  /// - [isArchived]: 按归档状态过滤
  /// - [rangeStart]: 开始日期
  /// - [rangeEnd]: 结束日期
  /// - [readStatus]: 阅读进度状态 (unread, reading, read)
  /// - [updatedSince]: 检索在此日期之后创建的书签
  /// - [ids]: 一个或多个书签 ID
  /// - [collection]: 集合 ID
  /// - [sort]: 排序参数 (created, -created, domain, -domain, duration, -duration, published, -published, site, -site, title, -title)
  /// - [limit]: 每页项目数
  /// - [offset]: 分页偏移量
  AsyncResult<List<Bookmark>> getBookmarks({
    String? search,
    String? title,
    String? author,
    String? site,
    String? type,
    List<String>? labels,
    bool? isLoaded,
    bool? hasErrors,
    bool? hasLabels,
    bool? isMarked,
    bool? isArchived,
    String? rangeStart,
    String? rangeEnd,
    String? readStatus,
    String? updatedSince,
    List<String>? ids,
    String? collection,
    String? sort,
    int? limit,
    int? offset,
  }) async {
    if (!_isConfigured) {
      return Failure(ApiNotConfiguredException());
    }

    // 构建查询参数
    final queryParts = <String>[];

    if (search != null) queryParts.add('search=${Uri.encodeComponent(search)}');
    if (title != null) queryParts.add('title=${Uri.encodeComponent(title)}');
    if (author != null) queryParts.add('author=${Uri.encodeComponent(author)}');
    if (site != null) queryParts.add('site=${Uri.encodeComponent(site)}');
    if (type != null) queryParts.add('type=${Uri.encodeComponent(type)}');
    if (labels != null && labels.isNotEmpty) {
      for (final label in labels) {
        queryParts.add('labels=${Uri.encodeComponent(label)}');
      }
    }
    if (isLoaded != null) queryParts.add('is_loaded=${isLoaded.toString()}');
    if (hasErrors != null) queryParts.add('has_errors=${hasErrors.toString()}');
    if (hasLabels != null) queryParts.add('has_labels=${hasLabels.toString()}');
    if (isMarked != null) queryParts.add('is_marked=${isMarked.toString()}');
    if (isArchived != null) {
      queryParts.add('is_archived=${isArchived.toString()}');
    }
    if (rangeStart != null) {
      queryParts.add('range_start=${Uri.encodeComponent(rangeStart)}');
    }
    if (rangeEnd != null) {
      queryParts.add('range_end=${Uri.encodeComponent(rangeEnd)}');
    }
    if (readStatus != null) {
      queryParts.add('read_status=${Uri.encodeComponent(readStatus)}');
    }
    if (updatedSince != null) {
      queryParts.add('updated_since=${Uri.encodeComponent(updatedSince)}');
    }
    if (ids != null && ids.isNotEmpty) {
      for (final id in ids) {
        queryParts.add('id=${Uri.encodeComponent(id)}');
      }
    }
    if (collection != null) {
      queryParts.add('collection=${Uri.encodeComponent(collection)}');
    }
    if (sort != null) queryParts.add('sort=${Uri.encodeComponent(sort)}');
    if (limit != null) queryParts.add('limit=${limit.toString()}');
    if (offset != null) queryParts.add('offset=${offset.toString()}');

    final queryString = queryParts.isNotEmpty ? '?${queryParts.join('&')}' : '';
    final uri = Uri.parse('$_host/api/bookmarks$queryString');

    try {
      final response = await _httpClient.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        // 检查响应体是否为空或无效
        if (response.body.isEmpty) {
          appLogger.w("服务器返回空响应。uri: $uri");
          return Failure(NetworkErrorException("服务器返回空响应", uri));
        }

        dynamic data;
        try {
          data = json.decode(response.body);
          appLogger.i('getBookmarks response.body: $data');
        } catch (formatException) {
          appLogger.w("JSON解析失败。uri: $uri, 响应体: ${response.body}");
          return Failure(
              NetworkErrorException("JSON解析失败：$formatException", uri));
        }

        // 检查返回的数据结构
        List<dynamic> bookmarksJson;
        if (data is List) {
          // 直接返回书签数组
          bookmarksJson = data;
        } else {
          appLogger.w("无效的响应格式。uri: $uri, 响应体: ${response.body}");
          return Failure(NetworkErrorException("无效的响应格式", uri));
        }

        final result =
            bookmarksJson.map((json) => Bookmark.fromJson(json)).toList();
        return Success(result);
      } else {
        appLogger.w("获取书签失败。uri: $uri, 状态码: ${response.statusCode}");
        return Failure(
            NetworkErrorException('获取书签失败', uri, response.statusCode));
      }
    } catch (e) {
      appLogger.w("网络请求失败。uri: $uri, 错误: $e");
      return Failure(NetworkErrorException('网络请求失败', uri));
    }
  }

  /// 更新书签
  ///
  /// 支持更新书签的各种属性：
  /// - [title]: 新书签标题
  /// - [isMarked]: 收藏状态
  /// - [isArchived]: 归档状态
  /// - [isDeleted]: 如果为 true，安排书签删除
  /// - [readProgress]: 阅读进度百分比 (0-100)
  /// - [readAnchor]: 最后看到元素的 CSS 选择器
  /// - [labels]: 替换书签的标签
  /// - [addLabels]: 向书签添加给定标签
  /// - [removeLabels]: 从书签中删除给定标签
  AsyncResult<Map<String, dynamic>> updateBookmark(
    String bookmarkId, {
    String? title,
    bool? isMarked,
    bool? isArchived,
    bool? isDeleted,
    int? readProgress,
    String? readAnchor,
    List<String>? labels,
    List<String>? addLabels,
    List<String>? removeLabels,
  }) async {
    if (!_isConfigured) {
      return Failure(ApiNotConfiguredException());
    }

    // 构建请求体
    final Map<String, dynamic> requestBody = {};

    if (title != null) requestBody['title'] = title;
    if (isMarked != null) requestBody['is_marked'] = isMarked;
    if (isArchived != null) requestBody['is_archived'] = isArchived;
    if (isDeleted != null) requestBody['is_deleted'] = isDeleted;
    if (readProgress != null) {
      // 确保阅读进度在 0-100 范围内
      if (readProgress < 0 || readProgress > 100) {
        return Failure(Exception('阅读进度必须在 0-100 范围内'));
      }
      requestBody['read_progress'] = readProgress;
    }
    if (readAnchor != null) requestBody['read_anchor'] = readAnchor;
    if (labels != null) requestBody['labels'] = labels;
    if (addLabels != null) requestBody['add_labels'] = addLabels;
    if (removeLabels != null) requestBody['remove_labels'] = removeLabels;

    // 如果没有任何更新参数，返回错误
    if (requestBody.isEmpty) {
      return Failure(Exception('至少需要提供一个更新参数'));
    }

    final uri =
        Uri.parse('$_host/api/bookmarks/${Uri.encodeComponent(bookmarkId)}');

    try {
      final response = await _httpClient.patch(
        uri,
        headers: _headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        // 检查响应体是否为空或无效
        if (response.body.isEmpty) {
          appLogger.w("服务器返回空响应。uri: $uri");
          return Failure(NetworkErrorException("服务器返回空响应", uri));
        }

        dynamic data;
        try {
          data = json.decode(response.body);
        } catch (formatException) {
          appLogger.w("JSON解析失败。uri: $uri, 响应体: ${response.body}");
          return Failure(
              NetworkErrorException("JSON解析失败：$formatException", uri));
        }

        // 返回更新结果
        if (data is Map<String, dynamic>) {
          return Success(data);
        } else {
          appLogger.w("无效的响应格式。uri: $uri, 响应体: ${response.body}");
          return Failure(NetworkErrorException("无效的响应格式", uri));
        }
      } else {
        appLogger.w("更新书签失败。uri: $uri, 状态码: ${response.statusCode}");
        return Failure(
            NetworkErrorException('更新书签失败', uri, response.statusCode));
      }
    } catch (e) {
      appLogger.w("网络请求失败。uri: $uri, 错误: $e");
      return Failure(NetworkErrorException('网络请求失败', uri));
    }
  }

  /// 获取标签列表
  ///
  /// 返回当前用户与书签关联的所有标签
  AsyncResult<List<LabelInfo>> getLabels() async {
    if (!_isConfigured) {
      return Failure(ApiNotConfiguredException());
    }

    final uri = Uri.parse('$_host/api/bookmarks/labels');

    try {
      final response = await _httpClient.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        // 检查响应体是否为空或无效
        if (response.body.isEmpty) {
          appLogger.w("服务器返回空响应。uri: $uri");
          return Failure(NetworkErrorException("服务器返回空响应", uri));
        }

        dynamic data;
        try {
          data = json.decode(response.body);
          appLogger.i('getLabels response.body: $data');
        } catch (formatException) {
          appLogger.w("JSON解析失败。uri: $uri, 响应体: ${response.body}");
          return Failure(
              NetworkErrorException("JSON解析失败：$formatException", uri));
        }

        // 检查返回的数据结构
        List<dynamic> labelsJson;
        if (data is List) {
          // 直接返回标签数组
          labelsJson = data;
        } else {
          appLogger.w("无效的响应格式。uri: $uri, 响应体: ${response.body}");
          return Failure(NetworkErrorException("无效的响应格式", uri));
        }

        final result =
            labelsJson.map((json) => LabelInfo.fromJson(json)).toList();
        return Success(result);
      } else {
        appLogger.w("获取标签列表失败。uri: $uri, 状态码: ${response.statusCode}");
        return Failure(
            NetworkErrorException('获取标签列表失败', uri, response.statusCode));
      }
    } catch (e) {
      appLogger.w("网络请求失败。uri: $uri, 错误: $e");
      return Failure(NetworkErrorException('网络请求失败', uri));
    }
  }

  /// 获取书签文章内容
  ///
  /// 返回书签的文章正文（如果存在）
  /// [bookmarkId]: 书签ID
  /// 返回包含文章正文的 HTML 内容
  AsyncResult<String> getBookmarkArticle(String bookmarkId) async {
    if (!_isConfigured) {
      return Failure(ApiNotConfiguredException());
    }

    final uri = Uri.parse(
        '$_host/api/bookmarks/${Uri.encodeComponent(bookmarkId)}/article');

    try {
      final response = await _httpClient.get(uri, headers: {
        'Authorization': 'Bearer $_token',
        'Accept': 'text/html',
      });

      if (response.statusCode == 200) {
        // 检查响应体是否为空
        if (response.body.isEmpty) {
          appLogger.w("服务器返回空响应。uri: $uri");
          return const Failure(ArticleEmptyException());
        }

        appLogger.i(
            'getBookmarkArticle response received for bookmark: $bookmarkId');
        return Success(response.body);
      } else if (response.statusCode == 404) {
        appLogger.w("书签不存在。uri: $uri, 状态码: ${response.statusCode}");
        return Failure(
            ResourceNotFoundException("书签不存在", uri, response.statusCode));
      } else {
        appLogger.w("获取书签文章失败。uri: $uri, 状态码: ${response.statusCode}");
        return Failure(
            NetworkErrorException('获取书签文章失败', uri, response.statusCode));
      }
    } catch (e) {
      appLogger.w("网络请求失败。uri: $uri, 错误: $e");
      return Failure(NetworkErrorException(
        '获取书签文章失败',
        uri,
      ));
    }
  }

  /// 创建书签
  ///
  /// 创建新的书签
  /// [url]: 书签URL（必填）
  /// [title]: 书签标题（可选）
  /// [labels]: 书签标签列表（可选）
  /// 返回创建的书签对象
  AsyncResult<void> createBookmark({
    required String url,
    String? title,
    List<String>? labels,
  }) async {
    if (!_isConfigured) {
      return Failure(ApiNotConfiguredException());
    }

    // 构建请求体
    final Map<String, dynamic> requestBody = {
      'url': url,
    };

    if (title != null && title.isNotEmpty) {
      requestBody['title'] = title;
    }
    if (labels != null && labels.isNotEmpty) {
      requestBody['labels'] = labels;
    }

    final uri = Uri.parse('$_host/api/bookmarks');

    try {
      final response = await _httpClient.post(
        uri,
        headers: _headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 202) {
        // 检查响应体是否为空或无效
        if (response.body.isEmpty) {
          appLogger.w("服务器返回空响应。uri: $uri");
          return Failure(NetworkErrorException("服务器返回空响应", uri));
        }

        dynamic data;
        try {
          data = json.decode(response.body);
        } catch (formatException) {
          appLogger.w("JSON解析失败。uri: $uri, 响应体: ${response.body}");
          return Failure(
              NetworkErrorException("JSON解析失败：$formatException", uri));
        }

        // 检查创建响应格式
        if (data is Map<String, dynamic>) {
          // 检查是否是创建成功的响应格式 {"message": "string", "status": 0}
          if (data.containsKey('message') && data.containsKey('status')) {
            final status = data['status'];
            if (status == 202) {
              // 创建成功，异步处理中
              appLogger.i('书签创建请求已提交，正在异步处理: $url');
              return const Success(());
            } else {
              appLogger.w("创建书签失败，状态码: $status");
              return Failure(NetworkErrorException("创建书签失败", uri));
            }
          } else {
            appLogger.w("无效的响应格式。uri: $uri, 响应体: ${response.body}");
            return Failure(NetworkErrorException("无效的响应格式", uri));
          }
        } else {
          appLogger.w("无效的响应格式。uri: $uri, 响应体: ${response.body}");
          return Failure(NetworkErrorException("无效的响应格式", uri));
        }
      } else {
        appLogger.w("创建书签失败。uri: $uri, 状态码: ${response.statusCode}");
        return Failure(
            NetworkErrorException('创建书签失败', uri, response.statusCode));
      }
    } catch (e) {
      appLogger.w("网络请求失败。uri: $uri, 错误: $e");
      return Failure(NetworkErrorException('网络请求失败', uri));
    }
  }

  /// 删除书签
  ///
  /// 删除保存的书签
  /// [bookmarkId]: 要删除的书签ID
  /// 返回删除操作的结果
  AsyncResult<void> deleteBookmark(String bookmarkId) async {
    if (!_isConfigured) {
      return Failure(ApiNotConfiguredException());
    }

    final uri =
        Uri.parse('$_host/api/bookmarks/${Uri.encodeComponent(bookmarkId)}');

    try {
      final response = await _httpClient.delete(uri, headers: _headers);

      if (response.statusCode == 204) {
        appLogger.i('deleteBookmark success for bookmark: $bookmarkId');
        return const Success(unit);
      } else {
        appLogger.w("删除书签失败。uri: $uri, 状态码: ${response.statusCode}");
        return Failure(
            NetworkErrorException('删除书签失败', uri, response.statusCode));
      }
    } catch (e) {
      appLogger.w("网络请求失败。uri: $uri, 错误: $e");
      return Failure(NetworkErrorException('网络请求失败', uri));
    }
  }
}
