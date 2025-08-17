import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/data/repository/update/update_repository.dart';
import 'package:readeck_app/data/service/update_service.dart';
import 'package:readeck_app/main_viewmodel.dart';
import 'package:result_dart/result_dart.dart';
import 'package:readeck_app/main.dart';

import 'main_viewmodel_test.mocks.dart';

@GenerateMocks([SettingsRepository, UpdateRepository])
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    provideDummy<Result<UpdateInfo>>(Failure(Exception()));
    appLogger = Logger(level: Level.off);
  });

  late MainAppViewModel mainAppViewModel;
  late MockSettingsRepository mockSettingsRepository;
  late MockUpdateRepository mockUpdateRepository;

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    mockUpdateRepository = MockUpdateRepository();

    when(mockSettingsRepository.settingsChanged)
        .thenAnswer((_) => const Stream.empty());
    when(mockSettingsRepository.getThemeMode()).thenReturn(0);
  });

  group('MainAppViewModel', () {
    test('checks for update on initialization and updates updateInfo',
        () async {
      final updateInfo = UpdateInfo(version: '1.0.0', downloadUrl: 'url');
      when(mockUpdateRepository.checkForUpdate())
          .thenAnswer((_) async => Success(updateInfo));

      mainAppViewModel =
          MainAppViewModel(mockSettingsRepository, mockUpdateRepository);

      // Allow time for the async command to complete
      await Future.delayed(Duration.zero);

      expect(mainAppViewModel.updateInfo, updateInfo);
    });

    test('updateInfo remains null when no update is available', () async {
      when(mockUpdateRepository.checkForUpdate())
          .thenAnswer((_) async => Failure(Exception()));

      mainAppViewModel =
          MainAppViewModel(mockSettingsRepository, mockUpdateRepository);

      await Future.delayed(Duration.zero);

      expect(mainAppViewModel.updateInfo, isNull);
    });
  });
}
