import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/bookmark.dart';

class ReadeckApiService extends ChangeNotifier {
  static const String _baseUrlKey = 'readeck_base_url';
  static const String _tokenKey = 'readeck_token';

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
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey);
    _token = prefs.getString(_tokenKey);
  }

  // 设置API配置
  Future<void> setConfig(String baseUrl, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, baseUrl);
    await prefs.setString(_tokenKey, token);
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

  // 获取未读书签
  Future<List<Bookmark>> getUnreadBookmarks() async {
    if (!isConfigured) {
      throw Exception('API未配置，请先设置服务器地址和令牌');
    }

    _setLoading(true);
    final url =
        Uri.parse('$_baseUrl/api/bookmarks?read_status=unread&limit=100');

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
        throw Exception('获取书签失败: ${response.statusCode}');
      }
    } catch (e) {
      _setLoading(false);
      throw Exception('网络请求失败: $e');
    }
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
