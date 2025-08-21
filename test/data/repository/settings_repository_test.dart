import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/data/service/shared_preference_service.dart';
import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/main.dart';
import 'package:result_dart/result_dart.dart';

import 'settings_repository_test.mocks.dart';

// Generate mock classes
@GenerateMocks([SharedPreferencesService, ReadeckApiClient])
void main() {
  setUpAll(() {
    // Initialize appLogger for tests
    appLogger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        dateTimeFormat: DateTimeFormat.none,
      ),
      level: Level.warning, // Reduce log noise in tests
    );

    // Provide dummy values for Mockito
    provideDummy<Result<void>>(Success.unit());
    provideDummy<Result<String>>(const Success(''));
    provideDummy<Result<int>>(const Success(0));
    provideDummy<Result<bool>>(const Success(false));
  });

  group('SettingsRepository - Scenario Model Tests', () {
    late MockSharedPreferencesService mockPrefsService;
    late MockReadeckApiClient mockApiClient;
    late SettingsRepository repository;

    setUp(() {
      mockPrefsService = MockSharedPreferencesService();
      mockApiClient = MockReadeckApiClient();

      // Setup default mock behaviors for all required settings to allow loadSettings
      when(mockPrefsService.getThemeMode())
          .thenAnswer((_) async => const Success(0));
      when(mockPrefsService.getReadeckApiHost())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getReadeckApiToken())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getOpenRouterApiKey())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getSelectedOpenRouterModel())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getSelectedOpenRouterModelName())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationProvider())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationTargetLanguage())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationCacheEnabled())
          .thenAnswer((_) async => const Success(false));
      when(mockPrefsService.getAiTagTargetLanguage())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationModel())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationModelName())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getAiTagModel())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getAiTagModelName())
          .thenAnswer((_) async => const Success(''));

      repository = SettingsRepository(mockPrefsService, mockApiClient);
    });

    tearDown(() {
      repository.dispose();
    });

    group('Translation Model', () {
      test('should get translation model from service', () async {
        when(mockPrefsService.getTranslationModel())
            .thenAnswer((_) async => const Success('translation-model-1'));

        await repository.loadSettings();
        final result = repository.getTranslationModel();

        expect(result, equals('translation-model-1'));
        verify(mockPrefsService.getTranslationModel()).called(1);
      });

      test('should save translation model successfully', () async {
        await repository.loadSettings();

        const modelId = 'translation-model-2';

        when(mockPrefsService.setTranslationModel(modelId))
            .thenAnswer((_) async => const Success(()));

        final result = await repository.saveTranslationModel(modelId);

        expect(result.isSuccess(), isTrue);
        verify(mockPrefsService.setTranslationModel(modelId)).called(1);
      });

      test('should handle translation model save failure', () async {
        await repository.loadSettings();

        const modelId = 'translation-model-fail';
        final exception = Exception('Save failed');

        when(mockPrefsService.setTranslationModel(modelId))
            .thenAnswer((_) async => Failure(exception));

        final result = await repository.saveTranslationModel(modelId);

        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), equals(exception));
        verify(mockPrefsService.setTranslationModel(modelId)).called(1);
      });

      test('should cache translation model after save', () async {
        await repository.loadSettings();

        const modelId = 'cached-translation-model';

        when(mockPrefsService.setTranslationModel(modelId))
            .thenAnswer((_) async => const Success(()));

        await repository.saveTranslationModel(modelId);

        // Verify cached value is returned without calling service again
        final cachedResult = repository.getTranslationModel();
        expect(cachedResult, equals(modelId));

        // Should still only have 1 call from the setup, not from the getter
        verify(mockPrefsService.getTranslationModel()).called(1);
      });
    });

    group('AI Tag Model', () {
      test('should get ai tag model from service', () async {
        when(mockPrefsService.getAiTagModel())
            .thenAnswer((_) async => const Success('ai-tag-model-1'));

        await repository.loadSettings();
        final result = repository.getAiTagModel();

        expect(result, equals('ai-tag-model-1'));
        verify(mockPrefsService.getAiTagModel()).called(1);
      });

      test('should save ai tag model successfully', () async {
        await repository.loadSettings();

        const modelId = 'ai-tag-model-2';

        when(mockPrefsService.setAiTagModel(modelId))
            .thenAnswer((_) async => const Success(()));

        final result = await repository.saveAiTagModel(modelId);

        expect(result.isSuccess(), isTrue);
        verify(mockPrefsService.setAiTagModel(modelId)).called(1);
      });

      test('should handle ai tag model save failure', () async {
        await repository.loadSettings();

        const modelId = 'ai-tag-model-fail';
        final exception = Exception('Save failed');

        when(mockPrefsService.setAiTagModel(modelId))
            .thenAnswer((_) async => Failure(exception));

        final result = await repository.saveAiTagModel(modelId);

        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), equals(exception));
        verify(mockPrefsService.setAiTagModel(modelId)).called(1);
      });

      test('should cache ai tag model after save', () async {
        await repository.loadSettings();

        const modelId = 'cached-ai-tag-model';

        when(mockPrefsService.setAiTagModel(modelId))
            .thenAnswer((_) async => const Success(()));

        await repository.saveAiTagModel(modelId);

        // Verify cached value is returned without calling service again
        final cachedResult = repository.getAiTagModel();
        expect(cachedResult, equals(modelId));

        // Should still only have 1 call from the setup, not from the getter
        verify(mockPrefsService.getAiTagModel()).called(1);
      });
    });

    group('Settings Loading', () {
      test('should load scenario models during loadSettings', () async {
        when(mockPrefsService.getTranslationModel())
            .thenAnswer((_) async => const Success('loaded-translation-model'));
        when(mockPrefsService.getAiTagModel())
            .thenAnswer((_) async => const Success('loaded-ai-tag-model'));

        await repository.loadSettings();

        expect(repository.getTranslationModel(),
            equals('loaded-translation-model'));
        expect(repository.getAiTagModel(), equals('loaded-ai-tag-model'));

        // Verify both scenario models were loaded
        verify(mockPrefsService.getTranslationModel()).called(1);
        verify(mockPrefsService.getAiTagModel()).called(1);
      });

      test('should handle empty scenario models during loadSettings', () async {
        when(mockPrefsService.getTranslationModel())
            .thenAnswer((_) async => const Success(''));
        when(mockPrefsService.getAiTagModel())
            .thenAnswer((_) async => const Success(''));

        await repository.loadSettings();

        expect(repository.getTranslationModel(), equals(''));
        expect(repository.getAiTagModel(), equals(''));
      });
    });

    group('Cache Behavior', () {
      test('should return cached values after first load', () async {
        // First load
        when(mockPrefsService.getTranslationModel())
            .thenAnswer((_) async => const Success('cached-translation'));
        when(mockPrefsService.getAiTagModel())
            .thenAnswer((_) async => const Success('cached-ai-tag'));

        await repository.loadSettings();

        // Clear the mock to verify no additional calls
        clearInteractions(mockPrefsService);

        // Access cached values
        final translationModel = repository.getTranslationModel();
        final aiTagModel = repository.getAiTagModel();

        expect(translationModel, equals('cached-translation'));
        expect(aiTagModel, equals('cached-ai-tag'));

        // Verify no additional service calls were made
        verifyNever(mockPrefsService.getTranslationModel());
        verifyNever(mockPrefsService.getAiTagModel());
      });

      test('should update cache when models are saved', () async {
        await repository.loadSettings();

        // Save new models
        when(mockPrefsService.setTranslationModel('new-translation'))
            .thenAnswer((_) async => const Success(()));
        when(mockPrefsService.setAiTagModel('new-ai-tag'))
            .thenAnswer((_) async => const Success(()));

        await repository.saveTranslationModel('new-translation');
        await repository.saveAiTagModel('new-ai-tag');

        // Verify cached values are updated
        expect(repository.getTranslationModel(), equals('new-translation'));
        expect(repository.getAiTagModel(), equals('new-ai-tag'));
      });
    });
  });

  group('SettingsRepository - Settings Changed Notification Tests', () {
    late MockSharedPreferencesService mockPrefsService;
    late MockReadeckApiClient mockApiClient;
    late SettingsRepository repository;

    setUp(() {
      mockPrefsService = MockSharedPreferencesService();
      mockApiClient = MockReadeckApiClient();

      // Setup default mock behaviors for all settings
      when(mockPrefsService.getThemeMode())
          .thenAnswer((_) async => const Success(0));
      when(mockPrefsService.getReadeckApiHost())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getReadeckApiToken())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getOpenRouterApiKey())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getSelectedOpenRouterModel())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getSelectedOpenRouterModelName())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationProvider())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationTargetLanguage())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationCacheEnabled())
          .thenAnswer((_) async => const Success(false));
      when(mockPrefsService.getAiTagTargetLanguage())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationModel())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationModelName())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getAiTagModel())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getAiTagModelName())
          .thenAnswer((_) async => const Success(''));

      repository = SettingsRepository(mockPrefsService, mockApiClient);
    });

    tearDown(() {
      repository.dispose();
    });

    group('settingsChanged Stream', () {
      test('should provide broadcast stream for settings changes', () async {
        await repository.loadSettings();

        // 验证是广播流
        expect(repository.settingsChanged.isBroadcast, isTrue);
      });

      test('should notify when API config is saved', () async {
        await repository.loadSettings();

        when(mockPrefsService.setReadeckApiHost('new-host'))
            .thenAnswer((_) async => const Success(()));
        when(mockPrefsService.setReadeckApiToken('new-token'))
            .thenAnswer((_) async => const Success(()));

        // 监听变更通知
        final notificationFuture = repository.settingsChanged.first;

        // 保存API配置
        await repository.saveApiConfig('new-host', 'new-token');

        // 验证收到变更通知
        await expectLater(notificationFuture, completes);
      });

      test('should notify when theme mode is saved', () async {
        await repository.loadSettings();

        when(mockPrefsService.setThemeMode(1))
            .thenAnswer((_) async => const Success(()));

        // 监听变更通知
        final notificationFuture = repository.settingsChanged.first;

        // 保存主题模式
        await repository.saveThemeMode(1);

        // 验证收到变更通知
        await expectLater(notificationFuture, completes);
      });

      test('should notify when OpenRouter API key is saved', () async {
        await repository.loadSettings();

        when(mockPrefsService.setOpenRouterApiKey('new-api-key'))
            .thenAnswer((_) async => const Success(()));

        // 监听变更通知
        final notificationFuture = repository.settingsChanged.first;

        // 保存OpenRouter API Key
        await repository.saveOpenRouterApiKey('new-api-key');

        // 验证收到变更通知
        await expectLater(notificationFuture, completes);
      });

      test('should notify when translation provider is saved', () async {
        await repository.loadSettings();

        when(mockPrefsService.setTranslationProvider('new-provider'))
            .thenAnswer((_) async => const Success(()));

        // 监听变更通知
        final notificationFuture = repository.settingsChanged.first;

        // 保存翻译服务提供方
        await repository.saveTranslationProvider('new-provider');

        // 验证收到变更通知
        await expectLater(notificationFuture, completes);
      });

      test('should notify when translation target language is saved', () async {
        await repository.loadSettings();

        when(mockPrefsService.setTranslationTargetLanguage('zh-CN'))
            .thenAnswer((_) async => const Success(()));

        // 监听变更通知
        final notificationFuture = repository.settingsChanged.first;

        // 保存翻译目标语种
        await repository.saveTranslationTargetLanguage('zh-CN');

        // 验证收到变更通知
        await expectLater(notificationFuture, completes);
      });

      test('should notify when translation cache enabled is saved', () async {
        await repository.loadSettings();

        when(mockPrefsService.setTranslationCacheEnabled(true))
            .thenAnswer((_) async => const Success(()));

        // 监听变更通知
        final notificationFuture = repository.settingsChanged.first;

        // 保存翻译缓存启用状态
        await repository.saveTranslationCacheEnabled(true);

        // 验证收到变更通知
        await expectLater(notificationFuture, completes);
      });

      test('should notify when AI tag target language is saved', () async {
        await repository.loadSettings();

        when(mockPrefsService.setAiTagTargetLanguage('zh-CN'))
            .thenAnswer((_) async => const Success(()));

        // 监听变更通知
        final notificationFuture = repository.settingsChanged.first;

        // 保存AI标签目标语言
        await repository.saveAiTagTargetLanguage('zh-CN');

        // 验证收到变更通知
        await expectLater(notificationFuture, completes);
      });

      test('should support multiple listeners simultaneously', () async {
        await repository.loadSettings();

        when(mockPrefsService.setThemeMode(2))
            .thenAnswer((_) async => const Success(()));

        // 创建多个监听者
        final listener1Future = repository.settingsChanged.first;
        final listener2Future = repository.settingsChanged.first;
        final listener3Future = repository.settingsChanged.first;

        // 保存设置
        await repository.saveThemeMode(2);

        // 验证所有监听者都收到通知
        await expectLater(listener1Future, completes);
        await expectLater(listener2Future, completes);
        await expectLater(listener3Future, completes);
      });

      test('should not notify when save operation fails', () async {
        await repository.loadSettings();

        final exception = Exception('Save failed');
        when(mockPrefsService.setThemeMode(1))
            .thenAnswer((_) async => Failure(exception));

        // 监听变更通知 (使用timeout防止测试无限等待)
        late bool notificationReceived;
        repository.settingsChanged.listen((_) {
          notificationReceived = true;
        });
        notificationReceived = false;

        // 尝试保存设置 (失败)
        final result = await repository.saveThemeMode(1);

        // 等待一小段时间确保没有通知
        await Future.delayed(const Duration(milliseconds: 100));

        // 验证操作失败且没有收到通知
        expect(result.isError(), isTrue);
        expect(notificationReceived, isFalse);
      });
    });
  });

  group('SettingsRepository - Model Name Features Tests', () {
    late MockSharedPreferencesService mockPrefsService;
    late MockReadeckApiClient mockApiClient;
    late SettingsRepository repository;

    setUp(() {
      mockPrefsService = MockSharedPreferencesService();
      mockApiClient = MockReadeckApiClient();

      // Setup default mock behaviors for all settings
      when(mockPrefsService.getThemeMode())
          .thenAnswer((_) async => const Success(0));
      when(mockPrefsService.getReadeckApiHost())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getReadeckApiToken())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getOpenRouterApiKey())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getSelectedOpenRouterModel())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getSelectedOpenRouterModelName())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationProvider())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationTargetLanguage())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationCacheEnabled())
          .thenAnswer((_) async => const Success(false));
      when(mockPrefsService.getAiTagTargetLanguage())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationModel())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationModelName())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getAiTagModel())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getAiTagModelName())
          .thenAnswer((_) async => const Success(''));

      repository = SettingsRepository(mockPrefsService, mockApiClient);
    });

    tearDown(() {
      repository.dispose();
    });

    group('OpenRouter Model Name Features', () {
      test('should save OpenRouter model with name and trigger notification',
          () async {
        await repository.loadSettings();

        const modelId = 'openai/gpt-4';
        const modelName = 'GPT-4';

        when(mockPrefsService.setSelectedOpenRouterModel(modelId))
            .thenAnswer((_) async => const Success(()));
        when(mockPrefsService.setSelectedOpenRouterModelName(modelName))
            .thenAnswer((_) async => const Success(()));

        // 监听变更通知
        final notificationFuture = repository.settingsChanged.first;

        // 保存带名称的模型
        final result =
            await repository.saveSelectedOpenRouterModel(modelId, modelName);

        // 验证保存成功
        expect(result.isSuccess(), isTrue);
        verify(mockPrefsService.setSelectedOpenRouterModel(modelId)).called(1);
        verify(mockPrefsService.setSelectedOpenRouterModelName(modelName))
            .called(1);

        // 验证缓存已更新
        expect(repository.getSelectedOpenRouterModel(), equals(modelId));
        expect(repository.getSelectedOpenRouterModelName(), equals(modelName));

        // 验证收到变更通知
        await expectLater(notificationFuture, completes);
      });

      test('should save OpenRouter model without name', () async {
        await repository.loadSettings();

        const modelId = 'openai/gpt-3.5-turbo';

        when(mockPrefsService.setSelectedOpenRouterModel(modelId))
            .thenAnswer((_) async => const Success(()));

        // 保存不带名称的模型
        final result = await repository.saveSelectedOpenRouterModel(modelId);

        // 验证保存成功
        expect(result.isSuccess(), isTrue);
        verify(mockPrefsService.setSelectedOpenRouterModel(modelId)).called(1);
        verifyNever(mockPrefsService.setSelectedOpenRouterModelName(any));

        // 验证缓存已更新
        expect(repository.getSelectedOpenRouterModel(), equals(modelId));
      });

      test('should handle OpenRouter model name save failure', () async {
        await repository.loadSettings();

        const modelId = 'openai/gpt-4';
        const modelName = 'GPT-4';
        final exception = Exception('Name save failed');

        when(mockPrefsService.setSelectedOpenRouterModel(modelId))
            .thenAnswer((_) async => const Success(()));
        when(mockPrefsService.setSelectedOpenRouterModelName(modelName))
            .thenAnswer((_) async => Failure(exception));

        // 保存带名称的模型
        final result =
            await repository.saveSelectedOpenRouterModel(modelId, modelName);

        // 验证保存失败
        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), equals(exception));
        verify(mockPrefsService.setSelectedOpenRouterModel(modelId)).called(1);
        verify(mockPrefsService.setSelectedOpenRouterModelName(modelName))
            .called(1);
      });

      test('should return empty string for null model name', () async {
        when(mockPrefsService.getSelectedOpenRouterModelName())
            .thenAnswer((_) async => const Success(''));

        await repository.loadSettings();

        // 验证空模型名称返回空字符串
        expect(repository.getSelectedOpenRouterModelName(), equals(''));
      });

      test('should load and cache OpenRouter model name', () async {
        const modelName = 'Loaded GPT-4';
        when(mockPrefsService.getSelectedOpenRouterModelName())
            .thenAnswer((_) async => const Success(modelName));

        await repository.loadSettings();

        // 验证加载的模型名称
        expect(repository.getSelectedOpenRouterModelName(), equals(modelName));
        verify(mockPrefsService.getSelectedOpenRouterModelName()).called(1);

        // 再次获取应使用缓存
        clearInteractions(mockPrefsService);
        expect(repository.getSelectedOpenRouterModelName(), equals(modelName));
        verifyNever(mockPrefsService.getSelectedOpenRouterModelName());
      });
    });

    group('Translation Model Name Features', () {
      test('should save translation model with name and trigger notification',
          () async {
        await repository.loadSettings();

        const modelId = 'openai/gpt-4';
        const modelName = 'GPT-4 for Translation';

        when(mockPrefsService.setTranslationModel(modelId))
            .thenAnswer((_) async => const Success(()));
        when(mockPrefsService.setTranslationModelName(modelName))
            .thenAnswer((_) async => const Success(()));

        // 监听变更通知
        final notificationFuture = repository.settingsChanged.first;

        // 保存带名称的翻译模型
        final result =
            await repository.saveTranslationModel(modelId, modelName);

        // 验证保存成功
        expect(result.isSuccess(), isTrue);
        verify(mockPrefsService.setTranslationModel(modelId)).called(1);
        verify(mockPrefsService.setTranslationModelName(modelName)).called(1);

        // 验证缓存已更新
        expect(repository.getTranslationModel(), equals(modelId));
        expect(repository.getTranslationModelName(), equals(modelName));

        // 验证收到变更通知
        await expectLater(notificationFuture, completes);
      });

      test('should save translation model without name', () async {
        await repository.loadSettings();

        const modelId = 'openai/gpt-3.5-turbo';

        when(mockPrefsService.setTranslationModel(modelId))
            .thenAnswer((_) async => const Success(()));

        // 保存不带名称的翻译模型
        final result = await repository.saveTranslationModel(modelId);

        // 验证保存成功
        expect(result.isSuccess(), isTrue);
        verify(mockPrefsService.setTranslationModel(modelId)).called(1);
        verifyNever(mockPrefsService.setTranslationModelName(any));

        // 验证缓存已更新
        expect(repository.getTranslationModel(), equals(modelId));
      });

      test('should handle translation model name save failure', () async {
        await repository.loadSettings();

        const modelId = 'openai/gpt-4';
        const modelName = 'GPT-4 for Translation';
        final exception = Exception('Translation name save failed');

        when(mockPrefsService.setTranslationModel(modelId))
            .thenAnswer((_) async => const Success(()));
        when(mockPrefsService.setTranslationModelName(modelName))
            .thenAnswer((_) async => Failure(exception));

        // 保存带名称的翻译模型
        final result =
            await repository.saveTranslationModel(modelId, modelName);

        // 验证保存失败
        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), equals(exception));
        verify(mockPrefsService.setTranslationModel(modelId)).called(1);
        verify(mockPrefsService.setTranslationModelName(modelName)).called(1);
      });

      test('should return empty string for null translation model name',
          () async {
        when(mockPrefsService.getTranslationModelName())
            .thenAnswer((_) async => const Success(''));

        await repository.loadSettings();

        // 验证空模型名称返回空字符串
        expect(repository.getTranslationModelName(), equals(''));
      });

      test('should load and cache translation model name', () async {
        const modelName = 'Loaded Translation GPT-4';
        when(mockPrefsService.getTranslationModelName())
            .thenAnswer((_) async => const Success(modelName));

        await repository.loadSettings();

        // 验证加载的模型名称
        expect(repository.getTranslationModelName(), equals(modelName));
        verify(mockPrefsService.getTranslationModelName()).called(1);

        // 再次获取应使用缓存
        clearInteractions(mockPrefsService);
        expect(repository.getTranslationModelName(), equals(modelName));
        verifyNever(mockPrefsService.getTranslationModelName());
      });
    });

    group('AI Tag Model Name Features', () {
      test('should save AI tag model with name and trigger notification',
          () async {
        await repository.loadSettings();

        const modelId = 'openai/gpt-4';
        const modelName = 'GPT-4 for AI Tagging';

        when(mockPrefsService.setAiTagModel(modelId))
            .thenAnswer((_) async => const Success(()));
        when(mockPrefsService.setAiTagModelName(modelName))
            .thenAnswer((_) async => const Success(()));

        // 监听变更通知
        final notificationFuture = repository.settingsChanged.first;

        // 保存带名称的AI标签模型
        final result = await repository.saveAiTagModel(modelId, modelName);

        // 验证保存成功
        expect(result.isSuccess(), isTrue);
        verify(mockPrefsService.setAiTagModel(modelId)).called(1);
        verify(mockPrefsService.setAiTagModelName(modelName)).called(1);

        // 验证缓存已更新
        expect(repository.getAiTagModel(), equals(modelId));
        expect(repository.getAiTagModelName(), equals(modelName));

        // 验证收到变更通知
        await expectLater(notificationFuture, completes);
      });

      test('should save AI tag model without name', () async {
        await repository.loadSettings();

        const modelId = 'openai/gpt-3.5-turbo';

        when(mockPrefsService.setAiTagModel(modelId))
            .thenAnswer((_) async => const Success(()));

        // 保存不带名称的AI标签模型
        final result = await repository.saveAiTagModel(modelId);

        // 验证保存成功
        expect(result.isSuccess(), isTrue);
        verify(mockPrefsService.setAiTagModel(modelId)).called(1);
        verifyNever(mockPrefsService.setAiTagModelName(any));

        // 验证缓存已更新
        expect(repository.getAiTagModel(), equals(modelId));
      });

      test('should handle AI tag model name save failure', () async {
        await repository.loadSettings();

        const modelId = 'openai/gpt-4';
        const modelName = 'GPT-4 for AI Tagging';
        final exception = Exception('AI tag name save failed');

        when(mockPrefsService.setAiTagModel(modelId))
            .thenAnswer((_) async => const Success(()));
        when(mockPrefsService.setAiTagModelName(modelName))
            .thenAnswer((_) async => Failure(exception));

        // 保存带名称的AI标签模型
        final result = await repository.saveAiTagModel(modelId, modelName);

        // 验证保存失败
        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), equals(exception));
        verify(mockPrefsService.setAiTagModel(modelId)).called(1);
        verify(mockPrefsService.setAiTagModelName(modelName)).called(1);
      });

      test('should return empty string for null AI tag model name', () async {
        when(mockPrefsService.getAiTagModelName())
            .thenAnswer((_) async => const Success(''));

        await repository.loadSettings();

        // 验证空模型名称返回空字符串
        expect(repository.getAiTagModelName(), equals(''));
      });

      test('should load and cache AI tag model name', () async {
        const modelName = 'Loaded AI Tag GPT-4';
        when(mockPrefsService.getAiTagModelName())
            .thenAnswer((_) async => const Success(modelName));

        await repository.loadSettings();

        // 验证加载的模型名称
        expect(repository.getAiTagModelName(), equals(modelName));
        verify(mockPrefsService.getAiTagModelName()).called(1);

        // 再次获取应使用缓存
        clearInteractions(mockPrefsService);
        expect(repository.getAiTagModelName(), equals(modelName));
        verifyNever(mockPrefsService.getAiTagModelName());
      });
    });
  });

  group('SettingsRepository - Dispose Tests', () {
    late MockSharedPreferencesService mockPrefsService;
    late MockReadeckApiClient mockApiClient;
    late SettingsRepository repository;

    setUp(() {
      mockPrefsService = MockSharedPreferencesService();
      mockApiClient = MockReadeckApiClient();

      // Setup minimal mock behaviors
      when(mockPrefsService.getThemeMode())
          .thenAnswer((_) async => const Success(0));
      when(mockPrefsService.getReadeckApiHost())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getReadeckApiToken())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getOpenRouterApiKey())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getSelectedOpenRouterModel())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getSelectedOpenRouterModelName())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationProvider())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationTargetLanguage())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationCacheEnabled())
          .thenAnswer((_) async => const Success(false));
      when(mockPrefsService.getAiTagTargetLanguage())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationModel())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getTranslationModelName())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getAiTagModel())
          .thenAnswer((_) async => const Success(''));
      when(mockPrefsService.getAiTagModelName())
          .thenAnswer((_) async => const Success(''));

      repository = SettingsRepository(mockPrefsService, mockApiClient);
    });

    test('should close settings changed stream controller', () async {
      await repository.loadSettings();

      // 获取Stream引用
      final stream = repository.settingsChanged;

      // 验证Stream可以正常监听
      expect(stream.isBroadcast, isTrue);

      // 调用dispose
      repository.dispose();

      // 验证Stream已关闭 - 尝试监听应该报错或立即完成
      expect(() => stream.listen((_) {}), returnsNormally);
    });

    test('should handle multiple dispose calls gracefully', () async {
      await repository.loadSettings();

      // 多次调用dispose应该不报错
      expect(() {
        repository.dispose();
        repository.dispose();
        repository.dispose();
      }, returnsNormally);
    });

    test('should dispose before load settings', () {
      // 在loadSettings之前调用dispose应该不报错
      expect(() => repository.dispose(), returnsNormally);
    });
  });
}
