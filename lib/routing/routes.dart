abstract final class Routes {
  static const home = '/';
  static const settings = '/$settingsRelative';
  static const settingsRelative = 'settings';
  static const apiConfigSetting =
      '/$settingsRelative/$apiConfigSettingRelative';
  static const apiConfigSettingRelative = 'api-config';
  static const about = '/$settingsRelative/$aboutRelative';
  static const aboutRelative = 'about';
  static const dailyRead = '/$dailyReadRelative';
  static const dailyReadRelative = 'daily-read';
  static const unread = '/$unreadRelative';
  static const unreadRelative = 'unread';
  // static String bookingWithId(int id) => '$booking/$id';
}
