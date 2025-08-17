import 'package:flutter_command/flutter_command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
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

import 'add_bookmark_viewmodel_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<BookmarkRepository>(),
  MockSpec<LabelRepository>(),
  MockSpec<SettingsRepository>(),
  MockSpec<WebContentService>(),
  MockSpec<AiTagRecommendationRepository>(),
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

  group('AddBookmarkViewModel', () {
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

      viewModel = AddBookmarkViewModel(
        mockBookmarkRepository,
        mockLabelRepository,
        mockSettingsRepository,
        mockWebContentService,
        mockAiTagRecommendationRepository,
      );
    });

    tearDown(() {
      // Let dispose test handle its own dispose call
    });

    group('初始状态', () {
      test('should have empty form fields initially', () {
        expect(viewModel.url, isEmpty);
        expect(viewModel.title, isEmpty);
        expect(viewModel.selectedLabels, isEmpty);
        expect(viewModel.canSubmit, isFalse);
        expect(viewModel.isValidUrl, isFalse);
      });

      test('should load labels on initialization', () async {
        // 验证监听器已注册
        verify(mockLabelRepository.addListener(any)).called(1);

        // 等待异步初始化完成
        await Future.delayed(Duration.zero);

        // 验证加载标签方法被调用
        verify(mockLabelRepository.loadLabels()).called(1);
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

    group('表单字段更新', () {
      test('should update URL and notify listeners', () {
        const newUrl = 'https://example.com';
        var listenerCalled = false;
        viewModel.addListener(() => listenerCalled = true);

        viewModel.updateUrl(newUrl);

        expect(viewModel.url, equals(newUrl));
        expect(listenerCalled, isTrue);
      });

      test('should update title and notify listeners', () {
        const newTitle = 'Test Title';
        var listenerCalled = false;
        viewModel.addListener(() => listenerCalled = true);

        viewModel.updateTitle(newTitle);

        expect(viewModel.title, equals(newTitle));
        expect(listenerCalled, isTrue);
      });

      test('should update selected labels and notify listeners', () {
        final newLabels = ['label1', 'label2'];
        var listenerCalled = false;
        viewModel.addListener(() => listenerCalled = true);

        viewModel.updateSelectedLabels(newLabels);

        expect(viewModel.selectedLabels, equals(newLabels));
        expect(listenerCalled, isTrue);
      });

      test('should not notify listeners if URL is the same', () {
        const url = 'https://example.com';
        viewModel.updateUrl(url);

        var listenerCalled = false;
        viewModel.addListener(() => listenerCalled = true);

        viewModel.updateUrl(url); // Same URL

        expect(listenerCalled, isFalse);
      });
    });

    group('标签管理', () {
      test('should add label if not already selected', () {
        viewModel.addLabel('new-label');
        expect(viewModel.selectedLabels, contains('new-label'));
      });

      test('should not add duplicate labels', () {
        viewModel.addLabel('label1');
        viewModel.addLabel('label1'); // Duplicate
        expect(viewModel.selectedLabels.where((l) => l == 'label1').length,
            equals(1));
      });

      test('should remove label if it exists', () {
        viewModel.addLabel('label1');
        viewModel.addLabel('label2');
        viewModel.removeLabel('label1');
        expect(viewModel.selectedLabels, isNot(contains('label1')));
        expect(viewModel.selectedLabels, contains('label2'));
      });
    });

    group('创建书签', () {
      test('should create bookmark successfully', () async {
        const url = 'https://example.com';
        const title = 'Test Title';
        final labels = ['label1', 'label2'];

        when(mockBookmarkRepository.createBookmark(
          url: url,
          title: title,
          labels: labels,
        )).thenAnswer((_) async => const Success(()));

        viewModel.updateUrl(url);
        viewModel.updateTitle(title);
        viewModel.updateSelectedLabels(labels);

        final params = CreateBookmarkParams(
          url: url,
          title: title,
          labels: labels,
        );

        await viewModel.createBookmark.executeWithFuture(params);

        // 验证表单已清空
        expect(viewModel.url, isEmpty);
        expect(viewModel.title, isEmpty);
        expect(viewModel.selectedLabels, isEmpty);

        verify(mockBookmarkRepository.createBookmark(
          url: url,
          title: title,
          labels: labels,
        )).called(1);
      });

      test('should handle creation failure', () async {
        const url = 'https://example.com';
        final exception = Exception('Creation failed');

        when(mockBookmarkRepository.createBookmark(
          url: url,
          title: null,
          labels: null,
        )).thenAnswer((_) async => Failure(exception));

        viewModel.updateUrl(url);

        const params = CreateBookmarkParams(url: url);

        // Wait for the execution to complete and expect exception
        await expectLater(
          () => viewModel.createBookmark.executeWithFuture(params),
          throwsA(equals(exception)),
        );

        // Verify the repository method was called
        verify(mockBookmarkRepository.createBookmark(
          url: url,
          title: null,
          labels: null,
        )).called(1);
      });
    });

    group('表单清理', () {
      test('should clear all form fields', () {
        viewModel.updateUrl('https://example.com');
        viewModel.updateTitle('Test Title');
        viewModel.updateSelectedLabels(['label1', 'label2']);

        viewModel.clearForm();

        expect(viewModel.url, isEmpty);
        expect(viewModel.title, isEmpty);
        expect(viewModel.selectedLabels, isEmpty);
      });
    });

    group('分享文本处理', () {
      test('should extract URL from shared text with URL', () {
        const sharedText =
            'Check out this article https://example.com/article Amazing content';

        viewModel.processSharedText(sharedText);

        expect(viewModel.url, equals('https://example.com/article'));
        expect(viewModel.title, isEmpty); // 标题应该保持为空
      });

      test('should extract multiple URLs and use the first one', () {
        const sharedText =
            'Two links: https://first.com and https://second.com';

        viewModel.processSharedText(sharedText);

        expect(viewModel.url, equals('https://first.com'));
        expect(viewModel.title, isEmpty);
      });

      test('should handle HTTP URLs', () {
        const sharedText = 'Old site http://example.com still works';

        viewModel.processSharedText(sharedText);

        expect(viewModel.url, equals('http://example.com'));
        expect(viewModel.title, isEmpty);
      });

      test('should keep URL empty when no URL found', () {
        const sharedText = 'Just some text without any links';

        viewModel.processSharedText(sharedText);

        expect(viewModel.url, isEmpty);
        expect(viewModel.title, isEmpty);
      });

      test('should handle URL-only text', () {
        const sharedText = 'https://example.com/path';

        viewModel.processSharedText(sharedText);

        expect(viewModel.url, equals('https://example.com/path'));
        expect(viewModel.title, isEmpty);
      });

      test('should handle empty shared text', () {
        const sharedText = '';

        viewModel.processSharedText(sharedText);

        expect(viewModel.url, isEmpty);
        expect(viewModel.title, isEmpty);
      });

      test('should notify listeners when processing shared text with URL', () {
        const sharedText = 'Check out https://example.com great site';
        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        viewModel.processSharedText(sharedText);

        // Should be called once: only for URL update
        expect(listenerCallCount, equals(1));
      });

      test('should not notify listeners when no URL found', () {
        const sharedText = 'Just some text without links';
        var listenerCallCount = 0;
        viewModel.addListener(() => listenerCallCount++);

        viewModel.processSharedText(sharedText);

        // Should not be called since no URL was found
        expect(listenerCallCount, equals(0));
      });
    });

    group('资源释放', () {
      test('should remove label repository listener on dispose', () {
        viewModel.dispose();
        verify(mockLabelRepository.removeListener(any)).called(1);
      });
    });
  });
}
