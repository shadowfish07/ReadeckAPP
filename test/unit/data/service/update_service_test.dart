import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:readeck_app/data/service/update_service.dart';

import 'update_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late UpdateService updateService;
  late MockClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockClient();
    updateService = UpdateService(client: mockHttpClient);
  });

  group('UpdateService', () {
    test('returns UpdateInfo when a newer version is available', () async {
      PackageInfo.setMockInitialValues(
        appName: 'readeck_app',
        packageName: 'com.example.readeck_app',
        version: '0.4.1',
        buildNumber: '1',
        buildSignature: '',
      );

      final responsePayload = {
        'tag_name': 'v0.5.0',
        'assets': [
          {
            'name': 'app.apk',
            'browser_download_url': 'http://example.com/download'
          }
        ]
      };
      when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(jsonEncode(responsePayload), 200));

      final updateInfo = await updateService.checkForUpdate();

      expect(updateInfo, isNotNull);
      expect(updateInfo!.version, '0.5.0');
      expect(updateInfo.downloadUrl, 'http://example.com/download');
    });

    test('returns null when the version is the same or older', () async {
      PackageInfo.setMockInitialValues(
        appName: 'readeck_app',
        packageName: 'com.example.readeck_app',
        version: '0.5.0',
        buildNumber: '1',
        buildSignature: '',
      );

      final responsePayload = {
        'tag_name': 'v0.5.0',
        'assets': [
          {
            'name': 'app.apk',
            'browser_download_url': 'http://example.com/download'
          }
        ]
      };
      when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(jsonEncode(responsePayload), 200));

      final updateInfo = await updateService.checkForUpdate();

      expect(updateInfo, isNull);
    });

    test('returns null on http error', () async {
      PackageInfo.setMockInitialValues(
        appName: 'readeck_app',
        packageName: 'com.example.readeck_app',
        version: '0.4.1',
        buildNumber: '1',
        buildSignature: '',
      );

      when(mockHttpClient.get(any))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      final updateInfo = await updateService.checkForUpdate();

      expect(updateInfo, isNull);
    });
  });
}
