import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/update/update_repository.dart';
import 'package:readeck_app/domain/models/update/update_info.dart';
import 'package:readeck_app/domain/use_cases/app_update_use_case.dart';
import 'package:readeck_app/ui/settings/view_models/about_viewmodel.dart';
import 'package:result_dart/result_dart.dart';
import 'package:readeck_app/main.dart';

import 'about_viewmodel_test.mocks.dart';

@GenerateMocks([UpdateRepository, AppUpdateUseCase])
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    provideDummy<Result<UpdateInfo>>(Failure(Exception()));
    appLogger = Logger(level: Level.off);
  });

  late AboutViewModel aboutViewModel;
  late MockUpdateRepository mockUpdateRepository;
  late MockAppUpdateUseCase mockAppUpdateUseCase;

  setUp(() {
    mockUpdateRepository = MockUpdateRepository();
    mockAppUpdateUseCase = MockAppUpdateUseCase();
  });

  group('AboutViewModel', () {
    test('checks for update on initialization and updates updateInfo',
        () async {
      final updateInfo = UpdateInfo(
        version: '1.0.0',
        downloadUrl: 'url',
        releaseNotes: 'Test release notes',
        htmlUrl: 'https://github.com/test/repo/releases/tag/v1.0.0',
      );
      when(mockUpdateRepository.checkForUpdate())
          .thenAnswer((_) async => Success(updateInfo));

      aboutViewModel =
          AboutViewModel(mockUpdateRepository, mockAppUpdateUseCase);

      // Allow time for the async command to complete
      await Future.delayed(const Duration(milliseconds: 100));

      expect(aboutViewModel.updateInfo, updateInfo);
    });

    test('updateInfo remains null when no update is available', () async {
      when(mockUpdateRepository.checkForUpdate())
          .thenAnswer((_) async => Failure(Exception()));

      aboutViewModel =
          AboutViewModel(mockUpdateRepository, mockAppUpdateUseCase);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(aboutViewModel.updateInfo, isNull);
    });

    test('loads version from pubspec correctly', () async {
      aboutViewModel =
          AboutViewModel(mockUpdateRepository, mockAppUpdateUseCase);

      // Wait for version loading
      await Future.delayed(const Duration(milliseconds: 100));

      expect(aboutViewModel.version, isNotNull);
      expect(aboutViewModel.version, isNot('Unknown'));
    });
  });
}
