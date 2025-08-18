import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/update/update_repository.dart';
import 'package:readeck_app/data/service/update_service.dart';
import 'package:readeck_app/domain/models/update/update_info.dart';
import 'package:result_dart/result_dart.dart' as rd;

import 'update_repository_test.mocks.dart';

@GenerateMocks([UpdateService])
void main() {
  late UpdateRepository updateRepository;
  late MockUpdateService mockUpdateService;

  setUp(() {
    mockUpdateService = MockUpdateService();
    updateRepository = UpdateRepository(mockUpdateService);
  });

  group('UpdateRepository', () {
    test('returns success when update service finds an update', () async {
      final updateInfo = UpdateInfo(
        version: '1.0.0',
        downloadUrl: 'url',
        releaseNotes: 'Test release notes',
        htmlUrl: 'https://github.com/test/repo/releases/tag/v1.0.0',
      );
      when(mockUpdateService.checkForUpdate())
          .thenAnswer((_) async => updateInfo);

      final result = await updateRepository.checkForUpdate();

      expect(result, isA<rd.Success>());
      expect(result.getOrNull(), updateInfo);
    });

    test('returns failure when update service finds no update', () async {
      when(mockUpdateService.checkForUpdate()).thenAnswer((_) async => null);

      final result = await updateRepository.checkForUpdate();

      expect(result, isA<rd.Failure>());
    });

    test('returns failure when update service throws an exception', () async {
      when(mockUpdateService.checkForUpdate()).thenThrow(Exception('test'));

      final result = await updateRepository.checkForUpdate();

      expect(result, isA<rd.Failure>());
    });
  });
}
