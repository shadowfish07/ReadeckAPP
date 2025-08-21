import 'dart:async';
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
    provideDummy<Stream<void>>(const Stream<void>.empty());

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

      // Setup default mock behaviors
      when(mockSettingsRepository.getAiTagModel()).thenReturn('');
      when(mockSettingsRepository.getAiTagModelName()).thenReturn('');
      when(mockSettingsRepository.settingsChanged)
          .thenAnswer((_) => const Stream<void>.empty());
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

      test('should provide access to aiTagModel property', () {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.getAiTagModel())
            .thenReturn('test-model-id');

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        expect(viewModel.aiTagModel, equals('test-model-id'));
        verify(mockSettingsRepository.getAiTagModel()).called(1);
      });

      test('should provide access to aiTagModelName property', () {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.getAiTagModelName())
            .thenReturn('Test Model');

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        expect(viewModel.aiTagModelName, equals('Test Model'));
        verify(mockSettingsRepository.getAiTagModelName()).called(1);
      });

      test('should listen to settings changes and notify listeners', () async {
        final streamController = StreamController<void>();
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.settingsChanged)
            .thenAnswer((_) => streamController.stream);

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        // Trigger settings change
        streamController.add(null);

        // Wait for async processing
        await Future.delayed(const Duration(milliseconds: 10));

        // Verify that listeners were notified
        expect(listenerCallCount, greaterThanOrEqualTo(1));

        streamController.close();
      });

      test('should handle multiple settings changes', () async {
        final streamController = StreamController<void>();
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.settingsChanged)
            .thenAnswer((_) => streamController.stream);

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        // Trigger multiple settings changes
        streamController.add(null);
        streamController.add(null);
        streamController.add(null);

        // Wait for async processing
        await Future.delayed(const Duration(milliseconds: 10));

        // Verify that listeners were notified multiple times
        expect(listenerCallCount, greaterThanOrEqualTo(3));

        streamController.close();
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

        // After save, mock should return the new language
        when(mockSettingsRepository.getAiTagTargetLanguage())
            .thenReturn(newLanguage);

        await viewModel.saveAiTagTargetLanguage.executeWithFuture(newLanguage);

        expect(viewModel.aiTagTargetLanguage, equals(newLanguage));
        expect(listenerCallCount,
            greaterThanOrEqualTo(1)); // Should notify listeners at least once
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
        // Even on failure, commands may notify listeners during execution
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

          // After save, mock should return the new language
          when(mockSettingsRepository.getAiTagTargetLanguage())
              .thenReturn(language);

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

      test('should cancel settings subscription on dispose', () {
        final streamController = StreamController<void>();
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.settingsChanged)
            .thenAnswer((_) => streamController.stream);

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        // First dispose should work fine
        expect(() => viewModel.dispose(), returnsNormally);

        streamController.close();
      });
    });

    group('模型属性边界条件', () {
      test('should handle empty aiTagModel', () {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.getAiTagModel()).thenReturn('');

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        expect(viewModel.aiTagModel, equals(''));
        verify(mockSettingsRepository.getAiTagModel()).called(1);
      });

      test('should handle default aiTagModel when not set', () {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.getAiTagModel()).thenReturn('');

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        expect(viewModel.aiTagModel, equals(''));
        verify(mockSettingsRepository.getAiTagModel()).called(1);
      });

      test('should handle empty aiTagModelName', () {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.getAiTagModelName()).thenReturn('');

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        expect(viewModel.aiTagModelName, equals(''));
        verify(mockSettingsRepository.getAiTagModelName()).called(1);
      });

      test('should handle default aiTagModelName when not set', () {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.getAiTagModelName()).thenReturn('');

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        expect(viewModel.aiTagModelName, equals(''));
        verify(mockSettingsRepository.getAiTagModelName()).called(1);
      });

      test('should handle repository exceptions for aiTagModel', () {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.getAiTagModel())
            .thenThrow(Exception('Database error'));

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        expect(() => viewModel.aiTagModel, throwsA(isA<Exception>()));
        verify(mockSettingsRepository.getAiTagModel()).called(1);
      });

      test('should handle repository exceptions for aiTagModelName', () {
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.getAiTagModelName())
            .thenThrow(Exception('Database error'));

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        expect(() => viewModel.aiTagModelName, throwsA(isA<Exception>()));
        verify(mockSettingsRepository.getAiTagModelName()).called(1);
      });
    });

    group('边界条件', () {
      test('should handle empty string language', () async {
        const emptyLanguage = '';

        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.saveAiTagTargetLanguage(emptyLanguage))
            .thenAnswer((_) async => const Success(()));

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        // After save, mock should return the new language
        when(mockSettingsRepository.getAiTagTargetLanguage())
            .thenReturn(emptyLanguage);

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

        // After save, mock should return the new language
        when(mockSettingsRepository.getAiTagTargetLanguage())
            .thenReturn(longLanguage);

        await viewModel.saveAiTagTargetLanguage.executeWithFuture(longLanguage);

        expect(viewModel.aiTagTargetLanguage, equals(longLanguage));
        verify(mockSettingsRepository.saveAiTagTargetLanguage(longLanguage))
            .called(1);
      });
    });

    group('配置变更监听详细测试', () {
      test('should properly setup and cancel settings subscription', () {
        final streamController = StreamController<void>();
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.settingsChanged)
            .thenAnswer((_) => streamController.stream);

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        // Verify subscription was created
        verify(mockSettingsRepository.settingsChanged).called(1);

        // Dispose should cancel subscription without errors
        expect(() => viewModel.dispose(), returnsNormally);

        streamController.close();
      });

      test('should handle stream subscription lifecycle correctly', () async {
        final streamController = StreamController<void>();
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.settingsChanged)
            .thenAnswer((_) => streamController.stream);

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        // Verify the subscription is working
        streamController.add(null);
        await Future.delayed(const Duration(milliseconds: 10));
        expect(listenerCallCount, equals(1));

        // ViewModel should remain functional throughout
        expect(viewModel.aiTagTargetLanguage, equals('中文'));

        streamController.close();
      });

      test('should continue working after settings stream closes', () async {
        final streamController = StreamController<void>();
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.settingsChanged)
            .thenAnswer((_) => streamController.stream);

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        // Close the stream
        streamController.close();

        // ViewModel should still work normally
        expect(viewModel.aiTagTargetLanguage, equals('中文'));
        expect(() => viewModel.dispose(), returnsNormally);
      });

      test('should handle rapid successive settings changes', () async {
        final streamController = StreamController<void>();
        when(mockSettingsRepository.getAiTagTargetLanguage()).thenReturn('中文');
        when(mockSettingsRepository.settingsChanged)
            .thenAnswer((_) => streamController.stream);

        viewModel = AiTagSettingsViewModel(mockSettingsRepository);

        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        // Trigger rapid successive changes
        for (int i = 0; i < 10; i++) {
          streamController.add(null);
        }

        // Wait for all async operations to complete
        await Future.delayed(const Duration(milliseconds: 50));

        // All changes should be processed
        expect(listenerCallCount, equals(10));

        streamController.close();
      });
    });
  });
}
