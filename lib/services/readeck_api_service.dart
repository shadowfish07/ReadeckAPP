import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/bookmark.dart';
import 'storage_service.dart';

class ReadeckApiService extends ChangeNotifier {
  final StorageService _storageService = StorageService.instance;

  String? _baseUrl;
  String? _token;
  bool _isLoading = false;

  // 获取加载状态
  bool get isLoading => _isLoading;

  // 设置加载状态
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // 初始化服务，从本地存储加载配置
  Future<void> initialize() async {
    await _storageService.initialize();
    final config = _storageService.getApiConfig();
    _baseUrl = config['baseUrl'];
    _token = config['token'];
  }

  // 设置API配置
  Future<void> setConfig(String baseUrl, String token) async {
    await _storageService.saveApiConfig(baseUrl, token);
    _baseUrl = baseUrl;
    _token = token;
  }

  // 检查是否已配置
  bool get isConfigured => _baseUrl != null && _token != null;

  // 获取当前配置的基础URL
  String? get baseUrl => _baseUrl;

  // 获取当前配置的令牌
  String? get token => _token;

  // 获取请求头
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
  Future<List<Bookmark>> getBookmarks({
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
    if (!isConfigured) {
      throw Exception('API未配置，请先设置服务器地址和令牌');
    }

    _setLoading(true);

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
    final uri = Uri.parse('$_baseUrl/api/bookmarks$queryString');

    try {
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        // 检查响应体是否为空或无效
        if (response.body.isEmpty) {
          throw Exception('服务器返回空响应');
        }

        dynamic data;
        try {
          data = json.decode(response.body);
        } catch (formatException) {
          throw Exception('JSON解析失败: $formatException');
        }

        // 检查返回的数据结构
        List<dynamic> bookmarksJson;
        if (data is List) {
          // 直接返回书签数组
          bookmarksJson = data;
        } else if (data is Map && data.containsKey('bookmarks')) {
          // 包含bookmarks字段的对象
          bookmarksJson = data['bookmarks'] ?? [];
        } else {
          throw Exception('未知的API响应格式');
        }

        final result =
            bookmarksJson.map((json) => Bookmark.fromJson(json)).toList();
        _setLoading(false);
        return result;
      } else {
        _setLoading(false);
        throw Exception('获取书签失败: ${response.statusCode}');
      }
    } catch (e) {
      _setLoading(false);
      throw Exception('网络请求失败: $e');
    }
  }

  /// 获取未读书签（保持向后兼容性）
  Future<List<Bookmark>> getUnreadBookmarks() async {
    return getBookmarks(
      readStatus: 'unread',
      limit: 100,
    );
  }

  // 随机获取5个未读书签
  Future<List<Bookmark>> getRandomUnreadBookmarks() async {
    final allBookmarks = await getUnreadBookmarks();

    if (allBookmarks.isEmpty) {
      return [];
    }

    // 随机打乱并取前5个
    final shuffled = List<Bookmark>.from(allBookmarks);
    shuffled.shuffle(Random());

    return shuffled.take(5).toList();
  }

  // 标记/取消标记书签为喜爱
  Future<bool> toggleBookmarkMark(String bookmarkId, bool isMarked) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先设置服务器地址和令牌');
    }

    _setLoading(true);
    final url = Uri.parse('$_baseUrl/api/bookmarks/$bookmarkId');

    try {
      final response = await http.patch(
        url,
        headers: _headers,
        body: json.encode({
          'is_marked': !isMarked, // 切换标记状态
        }),
      );

      if (response.statusCode == 200) {
        _setLoading(false);
        return !isMarked; // 返回新的标记状态
      } else {
        _setLoading(false);
        throw Exception('标记书签失败: ${response.statusCode}');
      }
    } catch (e) {
      _setLoading(false);
      throw Exception('网络请求失败: $e');
    }
  }

  // 存档/取消存档书签
  Future<bool> toggleBookmarkArchive(String bookmarkId, bool isArchived) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先设置服务器地址和令牌');
    }

    _setLoading(true);
    final url = Uri.parse('$_baseUrl/api/bookmarks/$bookmarkId');

    try {
      final response = await http.patch(
        url,
        headers: _headers,
        body: json.encode({
          'is_archived': !isArchived, // 切换存档状态
        }),
      );

      if (response.statusCode == 200) {
        _setLoading(false);
        return !isArchived; // 返回新的存档状态
      } else {
        _setLoading(false);
        throw Exception('存档书签失败: ${response.statusCode}');
      }
    } catch (e) {
      _setLoading(false);
      throw Exception('网络请求失败: $e');
    }
  }

  // 批量获取书签的最新信息
  Future<List<Bookmark>> getBatchBookmarksInfo(List<String> bookmarkIds) async {
    if (!isConfigured) {
      throw Exception('API未配置，请先设置服务器地址和令牌');
    }

    if (bookmarkIds.isEmpty) {
      return [];
    }

    _setLoading(true);
    // 构建查询参数，使用id=1&id=2的格式
    final queryParams = bookmarkIds.map((id) => 'id=$id').join('&');
    final url = Uri.parse('$_baseUrl/api/bookmarks?$queryParams');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        // 检查响应体是否为空或无效
        if (response.body.isEmpty) {
          throw Exception('服务器返回空响应');
        }

        dynamic data;
        try {
          data = json.decode(response.body);
        } catch (formatException) {
          throw Exception('JSON解析失败: $formatException');
        }

        // 检查返回的数据结构
        List<dynamic> bookmarksJson;
        if (data is List) {
          // 直接返回书签数组
          bookmarksJson = data;
        } else if (data is Map && data.containsKey('bookmarks')) {
          // 包含bookmarks字段的对象
          bookmarksJson = data['bookmarks'] ?? [];
        } else {
          throw Exception('未知的API响应格式');
        }

        final result =
            bookmarksJson.map((json) => Bookmark.fromJson(json)).toList();
        _setLoading(false);
        return result;
      } else {
        _setLoading(false);
        throw Exception('批量获取书签失败: ${response.statusCode}');
      }
    } catch (e) {
      _setLoading(false);
      throw Exception('网络请求失败: $e');
    }
  }
}
