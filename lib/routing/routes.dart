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
  static const archived = '/$archivedRelative';
  static const archivedRelative = 'archived';
  static const marked = '/$markedRelative';
  static const markedRelative = 'marked';
  static const bookmarkDetail = '/$bookmarkDetailRelative';
  static const bookmarkDetailRelative = 'bookmark-detail';
  static String bookmarkDetailWithId(String id) => '$bookmarkDetail/$id';
}
