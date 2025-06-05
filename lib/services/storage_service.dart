import 'package:shared_preferences/shared_preferences.dart';
import '../utils/storage_keys.dart';

/// 统一的本地存储管理服务
class StorageService {
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

  // ==================== 便利方法 ====================

  /// 保存API基础URL
  Future<void> saveBaseUrl(String baseUrl) async {
    _ensureInitialized();
    await _prefs!.setString(StorageKeys.apiBaseUrl, baseUrl);
  }

  /// 获取API基础URL
  String? getBaseUrl() {
    _ensureInitialized();
    return _prefs!.getString(StorageKeys.apiBaseUrl);
  }

  /// 保存API令牌
  Future<void> saveToken(String token) async {
    _ensureInitialized();
    await _prefs!.setString(StorageKeys.apiToken, token);
  }

  /// 获取API令牌
  String? getToken() {
    _ensureInitialized();
    return _prefs!.getString(StorageKeys.apiToken);
  }

  /// 保存API配置
  Future<void> saveApiConfig(String baseUrl, String token) async {
    _ensureInitialized();
    await Future.wait([
      _prefs!.setString(StorageKeys.apiBaseUrl, baseUrl),
      _prefs!.setString(StorageKeys.apiToken, token),
    ]);
  }

  /// 获取API配置
  Map<String, String?> getApiConfig() {
    _ensureInitialized();
    return {
      'baseUrl': _prefs!.getString(StorageKeys.apiBaseUrl),
      'token': _prefs!.getString(StorageKeys.apiToken),
    };
  }

  /// 检查API是否已配置
  bool isApiConfigured() {
    _ensureInitialized();
    final baseUrl = _prefs!.getString(StorageKeys.apiBaseUrl);
    final token = _prefs!.getString(StorageKeys.apiToken);
    return baseUrl != null && token != null;
  }

  /// 清除API配置
  Future<void> clearApiConfig() async {
    _ensureInitialized();
    await Future.wait([
      _prefs!.remove(StorageKeys.apiBaseUrl),
      _prefs!.remove(StorageKeys.apiToken),
    ]);
  }

  // ==================== 通用存储方法 ====================

  /// 保存字符串值
  /// [key] 建议使用 StorageKeys 中定义的常量
  Future<void> saveString(String key, String value) async {
    _ensureInitialized();
    _validateKey(key);
    await _prefs!.setString(key, value);
  }

  /// 获取字符串值
  /// [key] 建议使用 StorageKeys 中定义的常量
  String? getString(String key) {
    _ensureInitialized();
    _validateKey(key);
    return _prefs!.getString(key);
  }

  /// 保存布尔值
  /// [key] 建议使用 StorageKeys 中定义的常量
  Future<void> saveBool(String key, bool value) async {
    _ensureInitialized();
    _validateKey(key);
    await _prefs!.setBool(key, value);
  }

  /// 获取布尔值
  /// [key] 建议使用 StorageKeys 中定义的常量
  bool? getBool(String key) {
    _ensureInitialized();
    _validateKey(key);
    return _prefs!.getBool(key);
  }

  /// 保存整数值
  /// [key] 建议使用 StorageKeys 中定义的常量
  Future<void> saveInt(String key, int value) async {
    _ensureInitialized();
    _validateKey(key);
    await _prefs!.setInt(key, value);
  }

  /// 获取整数值
  /// [key] 建议使用 StorageKeys 中定义的常量
  int? getInt(String key) {
    _ensureInitialized();
    _validateKey(key);
    return _prefs!.getInt(key);
  }

  /// 保存 double 值
  Future<void> saveDouble(String key, double value) async {
    _validateKey(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  /// 获取 double 值
  Future<double?> getDouble(String key) async {
    _validateKey(key);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key);
  }

  /// 验证键名是否有效
  void _validateKey(String key) {
    if (!StorageKeys.isValidKey(key)) {
      throw ArgumentError(
          'Invalid storage key: $key. Use keys from StorageKeys class.');
    }
  }
}
