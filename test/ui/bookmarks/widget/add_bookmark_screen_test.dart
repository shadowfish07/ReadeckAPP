import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/data/service/web_content_service.dart';
import 'package:readeck_app/ui/bookmarks/view_models/add_bookmark_viewmodel.dart';
import 'package:readeck_app/ui/bookmarks/widget/add_bookmark_screen.dart';

import 'add_bookmark_screen_test.mocks.dart';

@GenerateMocks([
  AddBookmarkViewModel
], customMocks: [
  MockSpec<Command<String, void>>(as: #MockStringCommand),
  MockSpec<Command<CreateBookmarkParams, void>>(as: #MockCreateCommand),
  MockSpec<Command<WebContent, void>>(as: #MockWebContentCommand),
])
void main() {
  group('AddBookmarkScreen URL Field State Management', () {
    late MockAddBookmarkViewModel mockViewModel;
    late MockCreateCommand mockCreateBookmarkCommand;
    late MockStringCommand mockAutoFetchCommand;
    late MockWebContentCommand mockAutoGenerateTagsCommand;

    late ValueNotifier<List<String>> loadLabelsValueNotifier;
    late ValueNotifier<bool> isExecutingNotifier;
    late ValueNotifier<CommandError<String>?> errorsNotifier;

    setUp(() {
      mockViewModel = MockAddBookmarkViewModel();
      mockCreateBookmarkCommand = MockCreateCommand();
      mockAutoFetchCommand = MockStringCommand();
      mockAutoGenerateTagsCommand = MockWebContentCommand();

      loadLabelsValueNotifier = ValueNotifier<List<String>>([]);
      isExecutingNotifier = ValueNotifier<bool>(false);
      errorsNotifier = ValueNotifier<CommandError<String>?>(null);

      // 设置基本属性
      when(mockViewModel.url).thenReturn('');
      when(mockViewModel.title).thenReturn('');
      when(mockViewModel.selectedLabels).thenReturn([]);
      when(mockViewModel.availableLabels).thenReturn(['标签1', '标签2']);
      when(mockViewModel.recommendedTags).thenReturn([]);
      when(mockViewModel.isContentFetched).thenReturn(false);
      when(mockViewModel.isValidUrl).thenReturn(false);
      when(mockViewModel.canSubmit).thenReturn(false);
      when(mockViewModel.hasAiModelConfigured).thenReturn(false);
      when(mockViewModel.shouldShowRecommendations).thenReturn(false);

      // 模拟Commands - 为loadLabels使用真实Command
      final realLoadLabelsCommand = Command.createAsyncNoParam<List<String>>(
        () async => loadLabelsValueNotifier.value,
        initialValue: [],
      );
      when(mockViewModel.loadLabels).thenReturn(realLoadLabelsCommand);

      when(mockViewModel.createBookmark).thenReturn(mockCreateBookmarkCommand);
      final createExecutingNotifier = ValueNotifier<bool>(false);
      final createErrorsNotifier =
          ValueNotifier<CommandError<CreateBookmarkParams>?>(null);
      when(mockCreateBookmarkCommand.isExecuting)
          .thenReturn(createExecutingNotifier);
      when(mockCreateBookmarkCommand.errors).thenReturn(createErrorsNotifier);
      when(mockCreateBookmarkCommand.results).thenAnswer(
          (_) => ValueNotifier(const CommandResult(null, null, null, false)));

      // 模拟autoFetchContentCommand
      when(mockViewModel.autoFetchContentCommand)
          .thenReturn(mockAutoFetchCommand);
      when(mockAutoFetchCommand.isExecuting).thenReturn(isExecutingNotifier);
      when(mockAutoFetchCommand.errors).thenReturn(errorsNotifier);

      // 模擬autoGenerateTagsCommand
      when(mockViewModel.autoGenerateTagsCommand)
          .thenReturn(mockAutoGenerateTagsCommand);
      final tagsExecutingNotifier = ValueNotifier<bool>(false);
      final tagsErrorsNotifier = ValueNotifier<CommandError<WebContent>?>(null);
      when(mockAutoGenerateTagsCommand.isExecuting)
          .thenReturn(tagsExecutingNotifier);
      when(mockAutoGenerateTagsCommand.errors).thenReturn(tagsErrorsNotifier);
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<AddBookmarkViewModel>(
          create: (_) => mockViewModel,
          child: AddBookmarkScreen(viewModel: mockViewModel),
        ),
      );
    }

    testWidgets('初始状态应该显示正常的URL输入框', (WidgetTester tester) async {
      // 安排
      loadLabelsValueNotifier.value = ['标签1', '标签2'];

      // 执行
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 验证
      expect(find.text('URL *'), findsOneWidget);
      expect(find.text('必填项'), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('加载状态应该显示进度指示器', (WidgetTester tester) async {
      // 安排
      loadLabelsValueNotifier.value = ['标签1', '标签2'];
      isExecutingNotifier.value = true;

      // 执行
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // 使用pump代替pumpAndSettle

      // 验证
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('正在获取网页内容...'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('错误状态应该显示重试按钮和错误信息', (WidgetTester tester) async {
      // 安排
      loadLabelsValueNotifier.value = ['标签1', '标签2'];
      errorsNotifier.value =
          CommandError(error: Exception('网络错误'), stackTrace: null);

      // 执行
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 验证
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('获取失败，请检查网址或重试'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('点击重试按钮后应该隐藏重试按钮并显示加载状态', (WidgetTester tester) async {
      // 安排
      loadLabelsValueNotifier.value = ['标签1', '标签2'];
      errorsNotifier.value =
          CommandError(error: Exception('网络错误'), stackTrace: null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 验证初始错误状态
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('获取失败，请检查网址或重试'), findsOneWidget);

      // 执行 - 点击重试按钮后模拟状态变化
      await tester.tap(find.byIcon(Icons.refresh));

      // 模拟点击重试后的状态变化：开始执行，错误仍存在但被忽略
      isExecutingNotifier.value = true;
      await tester.pump(); // 使用pump代替pumpAndSettle

      // 验证 - 重试按钮应该隐藏，显示加载状态
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('正在获取网页内容...'), findsOneWidget);
    });

    testWidgets('重试成功后应该显示成功状态', (WidgetTester tester) async {
      // 安排
      loadLabelsValueNotifier.value = ['标签1', '标签2'];

      // 先设置错误状态
      errorsNotifier.value =
          CommandError(error: Exception('网络错误'), stackTrace: null);
      when(mockViewModel.isContentFetched).thenReturn(false);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 验证初始错误状态
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // 执行 - 模拟重试成功的完整流程
      // 1. 开始执行
      isExecutingNotifier.value = true;
      await tester.pump(); // 使用pump代替pumpAndSettle

      // 2. 执行完成，清除错误，设置成功状态
      isExecutingNotifier.value = false;
      errorsNotifier.value = null;
      when(mockViewModel.isContentFetched).thenReturn(true);
      await tester.pumpAndSettle();

      // 验证 - 应该显示成功状态
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.text('已成功获取网页内容'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('重试失败后应该再次显示重试按钮', (WidgetTester tester) async {
      // 安排
      loadLabelsValueNotifier.value = ['标签1', '标签2'];

      // 先设置错误状态
      errorsNotifier.value =
          CommandError(error: Exception('第一次错误'), stackTrace: null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 模拟重试过程
      isExecutingNotifier.value = true;
      await tester.pump(); // 使用pump代替pumpAndSettle

      // 模拟重试失败
      isExecutingNotifier.value = false;
      errorsNotifier.value =
          CommandError(error: Exception('第二次错误'), stackTrace: null);
      await tester.pumpAndSettle();

      // 验证 - 重试按钮应该再次出现
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('获取失败，请检查网址或重试'), findsOneWidget);
    });
    testWidgets('从失败URL切换到新URL时应清除错误状态并重新获取', (WidgetTester tester) async {
      // 安排 - 初始为错误状态
      loadLabelsValueNotifier.value = ['标签1', '标签2'];
      errorsNotifier.value =
          CommandError(error: Exception('初始错误'), stackTrace: null);
      when(mockViewModel.isContentFetched).thenReturn(false);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 验证初始错误状态
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('获取失败，请检查网址或重试'), findsOneWidget);

      // 执行 - 用户输入新URL
      // 当输入有效URL时，我们需要模拟ViewModel的isValidUrl状态也变为true
      when(mockViewModel.isValidUrl).thenReturn(true);
      await tester.enterText(
          find.byType(TextFormField).first, 'https://new-valid-url.com');
      await tester.pump(); // 确保onChanged回调被处理

      // 模拟 updateUrl 方法被调用后产生的状态变化
      isExecutingNotifier.value = true;
      errorsNotifier.value = null; // 关键：错误状态被清除
      await tester.pump();

      // 验证 - 错误消失，显示加载状态
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.text('获取失败，请检查网址或重试'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('正在获取网页内容...'), findsOneWidget);
    });
  });
}
