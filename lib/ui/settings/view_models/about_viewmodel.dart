import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:readeck_app/utils/command.dart';
import 'package:readeck_app/utils/result.dart';

class AboutViewModel extends ChangeNotifier {
  AboutViewModel() {
    load = Command0(_loadVersion)..execute();
  }
  late Command0 load;

  String _version = 'Unknown';
  String get version => _version;
  final _log = Logger('AboutViewModel');

  Future<Result<void>> _loadVersion() async {
    try {
      final String pubspecContent = await rootBundle.loadString('pubspec.yaml');
      final RegExp versionRegex = RegExp(r'version:\s*([^\s]+)');
      final Match? match = versionRegex.firstMatch(pubspecContent);
      if (match != null) {
        _version = match.group(1)!.split('+')[0];
        notifyListeners();
        return const Result.ok(null);
      }
      notifyListeners();
      _log.warning("Wrong Version Format. pubspecContent: $pubspecContent");
      return Result.error(Exception("Wrong Version Format"));
    } on Exception catch (e) {
      // 如果读取失败，保持默认版本号
      _log.severe('Failed to load version: $e');
      notifyListeners();
      return Result.error(e);
    }
  }
}
