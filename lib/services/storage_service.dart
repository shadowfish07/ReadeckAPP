import 'package:shared_preferences/shared_preferences.dart';

/// 统一的本地存储管理服务
class StorageService {
  static const String _baseUrlKey = 'readeck_base_url';
  static const String _tokenKey = 'readeck_token';

  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  /// 获取单例实例
  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  /// 初始化存储服务
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 确保已初始化
  void _ensureInitialized() {
    if (_prefs == null) {
      throw Exception('StorageService未初始化，请先调用initialize()');
    }
  }

  /// 保存API基础URL
  Future<void> saveBaseUrl(String baseUrl) async {
    _ensureInitialized();
    await _prefs!.setString(_baseUrlKey, baseUrl);
  }

  /// 获取API基础URL
  String? getBaseUrl() {
    _ensureInitialized();
    return _prefs!.getString(_baseUrlKey);
  }

  /// 保存API令牌
  Future<void> saveToken(String token) async {
    _ensureInitialized();
    await _prefs!.setString(_tokenKey, token);
  }

  /// 获取API令牌
  String? getToken() {
    _ensureInitialized();
    return _prefs!.getString(_tokenKey);
  }

  /// 保存API配置
  Future<void> saveApiConfig(String baseUrl, String token) async {
    _ensureInitialized();
    await Future.wait([
      _prefs!.setString(_baseUrlKey, baseUrl),
      _prefs!.setString(_tokenKey, token),
    ]);
  }

  /// 获取API配置
  Map<String, String?> getApiConfig() {
    _ensureInitialized();
    return {
      'baseUrl': _prefs!.getString(_baseUrlKey),
      'token': _prefs!.getString(_tokenKey),
    };
  }

  /// 检查API是否已配置
  bool isApiConfigured() {
    _ensureInitialized();
    final baseUrl = _prefs!.getString(_baseUrlKey);
    final token = _prefs!.getString(_tokenKey);
    return baseUrl != null && token != null;
  }

  /// 清除API配置
  Future<void> clearApiConfig() async {
    _ensureInitialized();
    await Future.wait([
      _prefs!.remove(_baseUrlKey),
      _prefs!.remove(_tokenKey),
    ]);
  }

  /// 保存字符串值
  Future<void> saveString(String key, String value) async {
    _ensureInitialized();
    await _prefs!.setString(key, value);
  }

  /// 获取字符串值
  String? getString(String key) {
    _ensureInitialized();
    return _prefs!.getString(key);
  }

  /// 保存布尔值
  Future<void> saveBool(String key, bool value) async {
    _ensureInitialized();
    await _prefs!.setBool(key, value);
  }

  /// 获取布尔值
  bool? getBool(String key) {
    _ensureInitialized();
    return _prefs!.getBool(key);
  }

  /// 保存整数值
  Future<void> saveInt(String key, int value) async {
    _ensureInitialized();
    await _prefs!.setInt(key, value);
  }

  /// 获取整数值
  int? getInt(String key) {
    _ensureInitialized();
    return _prefs!.getInt(key);
  }

  /// 删除指定键的值
  Future<void> remove(String key) async {
    _ensureInitialized();
    await _prefs!.remove(key);
  }

  /// 清除所有存储的数据
  Future<void> clear() async {
    _ensureInitialized();
    await _prefs!.clear();
  }
}
