/// 统一的存储键管理
///
/// 集中管理所有用于 SharedPreferences 的键名，避免硬编码和重复定义
class StorageKeys {
  // 私有构造函数，防止实例化
  StorageKeys._();

  // ==================== API 配置相关 ====================
  /// Readeck API 基础 URL
  static const String apiBaseUrl = 'readeck_base_url';

  /// Readeck API 访问令牌
  static const String apiToken = 'readeck_token';

  // ==================== 应用设置相关 ====================
  /// 应用主题模式 (存储 ThemeMode.index)
  static const String themeMode = 'theme_mode';

  // ==================== 缓存相关 ====================
  /// 最后刷新日期
  static const String lastRefreshDate = 'last_refresh_date';

  /// 缓存的每日书签
  static const String cachedDailyBookmarks = 'cached_daily_bookmarks';

  // ==================== 辅助方法 ====================

  /// 获取所有键的列表
  static List<String> get allKeys => [
        apiBaseUrl,
        apiToken,
        themeMode,
        lastRefreshDate,
        cachedDailyBookmarks,
      ];

  /// 验证键名是否有效
  static bool isValidKey(String key) {
    return allKeys.contains(key);
  }
}
