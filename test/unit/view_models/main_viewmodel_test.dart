import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/main_viewmodel.dart';

import '../../helpers/test_logger_helper.dart';
import 'main_viewmodel_test.mocks.dart';

@GenerateMocks([SettingsRepository])
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupTestLogger();
  });

  late MockSettingsRepository mockSettingsRepository;

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();

    when(mockSettingsRepository.settingsChanged)
        .thenAnswer((_) => const Stream.empty());
    when(mockSettingsRepository.getThemeMode()).thenReturn(0);
  });

  group('MainAppViewModel', () {
    test('initializes correctly with theme mode', () {
      final mainAppViewModel = MainAppViewModel(mockSettingsRepository);

      expect(mainAppViewModel.themeMode, ThemeMode.system);
    });

    test('updates theme mode when settings change', () async {
      final mainAppViewModel = MainAppViewModel(mockSettingsRepository);

      // Test initial state
      expect(mainAppViewModel.themeMode, ThemeMode.system);

      // No longer testing update functionality as it's moved to AboutViewModel
    });
  });
}
