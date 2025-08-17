import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';

class UpdateService {
  final http.Client _client;

  UpdateService({http.Client? client}) : _client = client ?? http.Client();
  static const String _repo = 'shadowfish07/ReadeckAPP';
  static const String _apiUrl =
      'https://api.github.com/repos/$_repo/releases/latest';

  Future<UpdateInfo?> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = Version.parse(packageInfo.version);

    final response = await _client.get(Uri.parse(_apiUrl));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final latestVersionStr =
          (json['tag_name'] as String).replaceFirst('v', '');
      final latestVersion = Version.parse(latestVersionStr);

      if (latestVersion > currentVersion) {
        return UpdateInfo(
          version: latestVersion.toString(),
          downloadUrl: (json['assets'][0]['browser_download_url'] as String),
        );
      }
    }
    return null;
  }
}

class UpdateInfo {
  final String version;
  final String downloadUrl;

  UpdateInfo({required this.version, required this.downloadUrl});
}
