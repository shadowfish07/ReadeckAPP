class ApiNotConfiguredException implements Exception {
  @override
  String toString() => 'ApiNotConfiguredException: API未配置，请先设置服务器地址和令牌';
}
