abstract final class Routes {
  // static const home = '/';
  static const settings = '/$settingsRelative';
  static const settingsRelative = 'settings';
  static const apiConfigSetting =
      '/$settingsRelative/$apiConfigSettingRelative';
  static const apiConfigSettingRelative = 'api-config';
  static const about = '/about';
  static const dailyRead = '/$dailyReadRelative';
  static const dailyReadRelative = 'daily-read';
  static const unarchived = '/$unarchivedRelative';
  static const unarchivedRelative = 'unarchived';
  static const bookmarkDetail = '/$bookmarkDetailRelative';
  static const bookmarkDetailRelative = 'bookmark-detail';
  static String bookmarkDetailWithId(String id) => '$bookmarkDetail/$id';
}
