import 'package:flutter_command/flutter_command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/label/label_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/data/service/web_content_service.dart';
import 'package:readeck_app/data/repository/ai_tag_recommendation/ai_tag_recommendation_repository.dart';
import 'package:readeck_app/domain/models/bookmark/label_info.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/ui/bookmarks/view_models/add_bookmark_viewmodel.dart';
import 'package:result_dart/result_dart.dart';

// 简化的Mock类，用于基本测试
class MockBookmarkRepository extends Mock implements BookmarkRepository {}

class MockLabelRepository extends Mock implements LabelRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockWebContentService extends Mock implements WebContentService {}

class MockAiTagRecommendationRepository extends Mock
    implements AiTagRecommendationRepository {}

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
    late MockWebContentService mockWebContentService;
    late MockAiTagRecommendationRepository mockAiTagRecommendationRepository;
    late AddBookmarkViewModel viewModel;

    setUp(() {
      mockBookmarkRepository = MockBookmarkRepository();
      mockLabelRepository = MockLabelRepository();
      mockSettingsRepository = MockSettingsRepository();
      mockWebContentService = MockWebContentService();
      mockAiTagRecommendationRepository = MockAiTagRecommendationRepository();

      // 模拟初始状态
      when(mockLabelRepository.labelNames).thenReturn([]);
      when(mockLabelRepository.loadLabels())
          .thenAnswer((_) async => const Success([]));
      when(mockAiTagRecommendationRepository.isAvailable).thenReturn(false);

      viewModel = AddBookmarkViewModel(
        mockBookmarkRepository,
        mockLabelRepository,
        mockSettingsRepository,
        mockWebContentService,
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

        // 测试AI可用时的状态
        when(mockAiTagRecommendationRepository.isAvailable).thenReturn(true);
        // 需要创建新的viewModel实例来获取更新后的状态
        final aiEnabledViewModel = AddBookmarkViewModel(
          mockBookmarkRepository,
          mockLabelRepository,
          mockSettingsRepository,
          mockWebContentService,
          mockAiTagRecommendationRepository,
        );
        expect(aiEnabledViewModel.hasAiModelConfigured, isTrue);
        aiEnabledViewModel.dispose();
      });
    });

    group('URL 验证', () {
      test('should validate HTTP URLs as valid', () {
        viewModel.updateUrl('http://example.com');
        expect(viewModel.isValidUrl, isTrue);
        expect(viewModel.canSubmit, isTrue);
      });

      test('should validate HTTPS URLs as valid', () {
        viewModel.updateUrl('https://example.com');
        expect(viewModel.isValidUrl, isTrue);
        expect(viewModel.canSubmit, isTrue);
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
      test('should clear all form fields and states', () {
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
      });
    });

    group('分享文本处理', () {
      test('should extract URL from shared text', () {
        const sharedText =
            'Check out this article https://example.com/article Amazing content';

        viewModel.processSharedText(sharedText);

        expect(viewModel.url, equals('https://example.com/article'));
        expect(viewModel.title, isEmpty); // 标题应该保持为空
      });

      test('should handle URL-only text', () {
        const sharedText = 'https://example.com/path';

        viewModel.processSharedText(sharedText);

        expect(viewModel.url, equals('https://example.com/path'));
        expect(viewModel.title, isEmpty);
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
