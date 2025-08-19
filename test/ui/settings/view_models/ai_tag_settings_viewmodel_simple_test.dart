import 'package:flutter_command/flutter_command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/ui/settings/view_models/ai_tag_settings_viewmodel.dart';
import 'package:result_dart/result_dart.dart';

import 'ai_tag_settings_viewmodel_simple_test.mocks.dart';

// Generate mock classes
@GenerateMocks([SettingsRepository])
void main() {
  setUpAll(() {
    // Provide dummy values for Mockito
    provideDummy<Result<void>>(Success.unit());

    Command.globalExceptionHandler = (error, stackTrace) {
      // Handle errors in tests
    };

    // Initialize appLogger for tests
    appLogger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        dateTimeFormat: DateTimeFormat.none,
      ),
      level: Level.warning, // Reduce log noise in tests
    );
  });

  group('AiTagSettingsViewModel', () {
    late MockSettingsRepository mockSettingsRepository;
    late AiTagSettingsViewModel viewModel;

    setUp(() {
      mockSettingsRepository = MockSettingsRepository();
    });

    tearDown(() {
      // viewModel.dispose() is called in individual tests if needed
    });

    group('初始化', () {
      test('should load current AI tag target language on initialization', () {
        // 设置mock行为
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        expect(viewModel.aiTagTargetLanguage, equals('中文'));
        verify(mockSettingsRepository.getAiTagTargetLanguage()).called(1);
      });

      test('should load different language when repository returns it', () {
        when(mockSettingsRepository.getAiTagTargetLanguage())
            .thenReturn('English');

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        expect(viewModel.aiTagTargetLanguage, equals('English'));
        verify(mockSettingsRepository.getAiTagTargetLanguage()).called(1);
      });

      test('should initialize saveAiTagTargetLanguage command', () {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        expect(viewModel.saveAiTagTargetLanguage, isA<Command<String, void>>());
        expect(viewModel.saveAiTagTargetLanguage, isNotNull);
      });
    });

    group('支持的语言列表', () {
      test('should contain expected languages', () {
        const expectedLanguages = [
          '中文',
          'English',
          '日本語',
          'Français',
          'Deutsch',
          'Español',
          'Русский',
          '한국어',
        ];

        expect(AiTagSettingsViewModel.supportedLanguages,
            equals(expectedLanguages));
        expect(AiTagSettingsViewModel.supportedLanguages.length, equals(8));
      });

      test('should include Chinese as first option', () {
        expect(AiTagSettingsViewModel.supportedLanguages.first, equals('中文'));
      });

      test('should include English as second option', () {
        expect(AiTagSettingsViewModel.supportedLanguages[1], equals('English'));
      });
    });

    group('保存AI标签目标语言', () {
      test('should save language successfully and update local state',
          () async {
        const newLanguage = 'English';

        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.saveAiTagTargetLanguage(newLanguage))
            .thenAnswer((_) async => const Success(()));

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        await viewModel.saveAiTagTargetLanguage.executeWithFuture(newLanguage);

        expect(viewModel.aiTagTargetLanguage, equals(newLanguage));
        expect(listenerCallCount, equals(1)); // Should notify listeners
        verify(mockSettingsRepository.saveAiTagTargetLanguage(newLanguage))
            .called(1);
      });

      test('should handle save failure and throw exception', () async {
        const newLanguage = 'Français';
        final exception = Exception('Save failed');

        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.saveAiTagTargetLanguage(newLanguage))
            .thenAnswer((_) async => Failure(exception));

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        await expectLater(
          viewModel.saveAiTagTargetLanguage.executeWithFuture(newLanguage),
          throwsA(isA<Exception>()),
        );

        // State should not change when save fails
        expect(viewModel.aiTagTargetLanguage, equals('中文'));
        expect(listenerCallCount, equals(0));
        verify(mockSettingsRepository.saveAiTagTargetLanguage(newLanguage))
            .called(1);
      });

      test('should save different supported languages', () async {
        const testLanguages = ['English', '日本語', 'Français', 'Deutsch'];

        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        for (final language in testLanguages) {
          when(mockSettingsRepository.saveAiTagTargetLanguage(language))
              .thenAnswer((_) async => const Success(()));

          await viewModel.saveAiTagTargetLanguage.executeWithFuture(language);

          expect(viewModel.aiTagTargetLanguage, equals(language));
          verify(mockSettingsRepository.saveAiTagTargetLanguage(language))
              .called(1);
        }
      });
    });

    group('Command 状态', () {
      test('should have correct initial command state', () {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        expect(viewModel.saveAiTagTargetLanguage.isExecuting.value, isFalse);
      });
    });

    group('内存管理', () {
      test('should dispose without errors', () {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        expect(() => viewModel.dispose(), returnsNormally);
      });

      test('should not crash when accessing properties after dispose', () {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);
        viewModel.dispose();

        // Should still be able to access properties
        expect(() => viewModel.aiTagTargetLanguage, returnsNormally);
        expect(() => viewModel.saveAiTagTargetLanguage, returnsNormally);
      });
    });

    group('边界条件', () {
      test('should handle empty string language', () async {
        const emptyLanguage = '';

        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.saveAiTagTargetLanguage(emptyLanguage))
            .thenAnswer((_) async => const Success(()));

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        await viewModel.saveAiTagTargetLanguage
            .executeWithFuture(emptyLanguage);

        expect(viewModel.aiTagTargetLanguage, equals(emptyLanguage));
        verify(mockSettingsRepository.saveAiTagTargetLanguage(emptyLanguage))
            .called(1);
      });

      test('should handle very long language string', () async {
        const longLanguage = 'VeryLongLanguageNameThatExceedsNormalLength';

        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.saveAiTagTargetLanguage(longLanguage))
            .thenAnswer((_) async => const Success(()));

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        await viewModel.saveAiTagTargetLanguage.executeWithFuture(longLanguage);

        expect(viewModel.aiTagTargetLanguage, equals(longLanguage));
        verify(mockSettingsRepository.saveAiTagTargetLanguage(longLanguage))
            .called(1);
      });
    });
  });
}
