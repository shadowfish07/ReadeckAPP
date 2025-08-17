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
        // 从 assets 中找到 APK 文件
        final assets = json['assets'] as List;
        String? apkDownloadUrl;

        for (final asset in assets) {
          final name = asset['name'];
          if (name is String && name.toLowerCase().endsWith('.apk')) {
            final downloadUrl = asset['browser_download_url'];
            if (downloadUrl is String) {
              apkDownloadUrl = downloadUrl;
              break;
            }
          }
        }

        if (apkDownloadUrl == null) {
          // 如果没有找到 APK 文件，返回 null
          return null;
        }

        return UpdateInfo(
          version: latestVersion.toString(),
          downloadUrl: apkDownloadUrl,
          releaseNotes: json['body'] as String? ?? '',
          htmlUrl: json['html_url'] as String? ?? '',
        );
      }
    }
    return null;
  }
}

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final String htmlUrl;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.htmlUrl,
  });
}
