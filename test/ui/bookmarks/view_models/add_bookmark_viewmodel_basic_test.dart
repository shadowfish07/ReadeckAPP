import 'package:flutter_command/flutter_command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/label/label_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/data/service/web_content_service.dart';
import 'package:readeck_app/data/repository/web_content/web_content_repository.dart';
import 'package:readeck_app/data/repository/ai_tag_recommendation/ai_tag_recommendation_repository.dart';
import 'package:readeck_app/domain/models/bookmark/label_info.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/ui/bookmarks/view_models/add_bookmark_viewmodel.dart';
import 'package:result_dart/result_dart.dart';

import 'add_bookmark_viewmodel_basic_test.mocks.dart';

@GenerateMocks([
  BookmarkRepository,
  LabelRepository,
  SettingsRepository,
  WebContentRepository,
  AiTagRecommendationRepository,
])
void main() {
  // Set up global command error handler and logger
  setUpAll(() {
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

  // Provide dummy values for Result types that Mockito can't generate
  provideDummy<Result<List<LabelInfo>>>(const Success(<LabelInfo>[]));
  provideDummy<Result<void>>(const Success(()));
  provideDummy<Result<WebContent>>(
      const Success(WebContent(url: '', title: '', content: '')));
  provideDummy<Result<List<String>>>(const Success(<String>[]));

  group('AddBookmarkViewModel - Basic Tests', () {
    late MockBookmarkRepository mockBookmarkRepository;
    late MockLabelRepository mockLabelRepository;
    late MockSettingsRepository mockSettingsRepository;
    late MockWebContentRepository mockWebContentRepository;
    late MockAiTagRecommendationRepository mockAiTagRecommendationRepository;
    late AddBookmarkViewModel viewModel;

    setUp(() {
      mockBookmarkRepository = MockBookmarkRepository();
      mockLabelRepository = MockLabelRepository();
      mockSettingsRepository = MockSettingsRepository();
      mockWebContentRepository = MockWebContentRepository();
      mockAiTagRecommendationRepository = MockAiTagRecommendationRepository();

      // 模拟初始状态
      when(mockLabelRepository.labelNames).thenReturn(<String>[]);
      when(mockLabelRepository.loadLabels())
          .thenAnswer((_) async => const Success(<LabelInfo>[]));
      when(mockAiTagRecommendationRepository.isAvailable).thenReturn(false);

      // 模拟网页内容获取服务
      when(mockWebContentRepository.fetchWebContent(any,
              timeout: anyNamed('timeout')))
          .thenAnswer((_) async => const Success(WebContent(
                url: 'https://example.com',
                title: 'Test Title',
                content: 'Test Content',
              )));

      // 模拟AI标签推荐服务
      when(mockAiTagRecommendationRepository.generateTagRecommendations(
              any, any))
          .thenAnswer((_) async => const Success(<String>['tech', 'web']));

      viewModel = AddBookmarkViewModel(
        mockBookmarkRepository,
        mockLabelRepository,
        mockSettingsRepository,
        mockWebContentRepository,
        mockAiTagRecommendationRepository,
      );
    });

    tearDown(() {
      viewModel.dispose();
    });

    group('初始状态', () {
      test('should have empty form fields initially', () {
        expect(viewModel.url, isEmpty);
        expect(viewModel.title, isEmpty);
        expect(viewModel.selectedLabels, isEmpty);
        expect(viewModel.canSubmit, isFalse);
        expect(viewModel.isValidUrl, isFalse);
        expect(viewModel.isContentFetched, isFalse);
        expect(viewModel.isTagsGenerated, isFalse);
        expect(viewModel.recommendedTags, isEmpty);
      });

      test('should have correct AI availability status', () {
        expect(viewModel.hasAiModelConfigured, isFalse);
      });

      test('should have correct AI availability status when AI is available',
          () {
        // 创建新的mock实例用于AI可用状态测试
        final mockAiRepo = MockAiTagRecommendationRepository();
        when(mockAiRepo.isAvailable).thenReturn(true);
        when(mockAiRepo.generateTagRecommendations(any, any))
            .thenAnswer((_) async => const Success(<String>['tech', 'web']));

        // 为新的label repository设置必要的mock
        final mockLabelRepo = MockLabelRepository();
        when(mockLabelRepo.labelNames).thenReturn(<String>[]);
        when(mockLabelRepo.loadLabels())
            .thenAnswer((_) async => const Success(<LabelInfo>[]));

        // 为新的web content service设置必要的mock
        final mockWebService = MockWebContentRepository();
        when(mockWebService.fetchWebContent(any, timeout: anyNamed('timeout')))
            .thenAnswer((_) async => const Success(WebContent(
                  url: 'https://example.com',
                  title: 'Test Title',
                  content: 'Test Content',
                )));

        final aiEnabledViewModel = AddBookmarkViewModel(
          mockBookmarkRepository,
          mockLabelRepo,
          mockSettingsRepository,
          mockWebService,
          mockAiRepo,
        );
        expect(aiEnabledViewModel.hasAiModelConfigured, isTrue);
        aiEnabledViewModel.dispose();
      });
    });

    group('URL 验证', () {
      test('should validate HTTP URLs as valid', () async {
        viewModel.updateUrl('http://example.com');
        expect(viewModel.isValidUrl, isTrue);
        expect(viewModel.canSubmit, isTrue);

        // 等待异步操作完成
        await Future.delayed(const Duration(milliseconds: 10));
      });

      test('should validate HTTPS URLs as valid', () async {
        viewModel.updateUrl('https://example.com');
        expect(viewModel.isValidUrl, isTrue);
        expect(viewModel.canSubmit, isTrue);

        // 等待异步操作完成
        await Future.delayed(const Duration(milliseconds: 10));
      });

      test('should reject invalid URLs', () {
        viewModel.updateUrl('not-a-url');
        expect(viewModel.isValidUrl, isFalse);
        expect(viewModel.canSubmit, isFalse);
      });

      test('should reject empty URLs', () {
        viewModel.updateUrl('');
        expect(viewModel.isValidUrl, isFalse);
        expect(viewModel.canSubmit, isFalse);
      });
    });

    group('标签管理', () {
      test('should add recommended tag to selected labels', () {
        viewModel.addRecommendedTag('technology');
        expect(viewModel.selectedLabels, contains('technology'));
      });

      test('should not add duplicate recommended tags', () {
        viewModel.addRecommendedTag('technology');
        viewModel.addRecommendedTag('technology');
        expect(viewModel.selectedLabels.where((l) => l == 'technology').length,
            equals(1));
      });

      test('should add all recommended tags', () {
        // 模拟推荐标签
        viewModel.updateSelectedLabels([]);
        // 手动设置推荐标签（在实际实现中这会通过AI生成）
        // 这里我们需要通过其他方式测试这个功能

        viewModel.addRecommendedTag('tech');
        viewModel.addRecommendedTag('web');
        expect(viewModel.selectedLabels.length, equals(2));
        expect(viewModel.selectedLabels, containsAll(['tech', 'web']));
      });
    });

    group('表单清理', () {
      test('should clear all form fields and states', () async {
        viewModel.updateUrl('https://example.com');
        viewModel.updateTitle('Test Title');
        viewModel.updateSelectedLabels(['label1', 'label2']);

        viewModel.clearForm();

        expect(viewModel.url, isEmpty);
        expect(viewModel.title, isEmpty);
        expect(viewModel.selectedLabels, isEmpty);
        expect(viewModel.recommendedTags, isEmpty);
        expect(viewModel.isContentFetched, isFalse);
        expect(viewModel.isTagsGenerated, isFalse);

        // 等待异步操作完成
        await Future.delayed(const Duration(milliseconds: 10));
      });
    });

    group('分享文本处理', () {
      test('should extract URL from shared text', () async {
        const sharedText =
            'Check out this article https://example.com/article Amazing content';

        viewModel.processSharedText(sharedText);

        expect(viewModel.url, equals('https://example.com/article'));
        expect(viewModel.title, isEmpty); // 标题应该保持为空

        // 等待异步操作完成
        await Future.delayed(const Duration(milliseconds: 10));
      });

      test('should handle URL-only text', () async {
        const sharedText = 'https://example.com/path';

        viewModel.processSharedText(sharedText);

        expect(viewModel.url, equals('https://example.com/path'));
        expect(viewModel.title, isEmpty);

        // 等待异步操作完成
        await Future.delayed(const Duration(milliseconds: 10));
      });

      test('should keep URL empty when no URL found', () {
        const sharedText = 'Just some text without any links';

        viewModel.processSharedText(sharedText);

        expect(viewModel.url, isEmpty);
        expect(viewModel.title, isEmpty);
      });
    });
  });
}
