import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:logging/logging.dart';
import 'package:result_dart/result_dart.dart';

class AboutViewModel extends ChangeNotifier {
  AboutViewModel() {
    load = Command.createAsyncNoParamNoResult(_loadVersion)..execute();
  }
  late Command load;

  String _version = 'Unknown';
  String get version => _version;
  final _log = Logger('AboutViewModel');

  AsyncResult<void> _loadVersion() async {
    try {
      final String pubspecContent = await rootBundle.loadString('pubspec.yaml');
      final RegExp versionRegex = RegExp(r'version:\s*([^\s]+)');
      final Match? match = versionRegex.firstMatch(pubspecContent);
      if (match != null) {
        _version = match.group(1)!.split('+')[0];
        notifyListeners();
        return const Success(unit);
      }
      notifyListeners();
      _log.warning("Wrong Version Format. pubspecContent: $pubspecContent");
      return Failure(Exception("Wrong Version Format"));
    } on Exception catch (e) {
      // 如果读取失败，保持默认版本号
      _log.severe('Failed to load version: $e');
      notifyListeners();
      return Failure(e);
    }
  }
}
