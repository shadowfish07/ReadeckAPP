import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReadeckApiService {
  static const String _baseUrlKey = 'readeck_base_url';
  static const String _tokenKey = 'readeck_token';

  String? _baseUrl;
  String? _token;

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

        return bookmarksJson.map((json) => Bookmark.fromJson(json)).toList();
      } else {
        throw Exception('获取书签失败: ${response.statusCode}');
      }
    } catch (e) {
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
}

// 辅助方法：将动态类型转换为int
int? _parseIntFromDynamic(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) {
    return int.tryParse(value);
  }
  if (value is double) return value.toInt();
  return null;
}

// 书签数据模型
class Bookmark {
  final String id;
  final String title;
  final String url;
  final String? siteName;
  final String? description;
  final DateTime created;
  final bool isMarked;
  final bool isArchived;
  final int readProgress;
  final List<String> labels;
  final String? imageUrl;

  Bookmark({
    required this.id,
    required this.title,
    required this.url,
    this.siteName,
    this.description,
    required this.created,
    required this.isMarked,
    required this.isArchived,
    required this.readProgress,
    required this.labels,
    this.imageUrl,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] ?? '',
      title: json['title'] ?? '无标题',
      url: json['url'] ?? '',
      siteName: json['site_name'],
      description: json['description'],
      created:
          DateTime.parse(json['created'] ?? DateTime.now().toIso8601String()),
      isMarked: json['is_marked'] ?? false,
      isArchived: json['is_archived'] ?? false,
      readProgress: _parseIntFromDynamic(json['read_progress']) ?? 0,
      labels: List<String>.from(json['labels'] ?? []),
      imageUrl: json['resources']?['image']?['src'],
    );
  }
}
