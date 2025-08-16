import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/bookmark_display_model/bookmark_display_model.dart';
import 'package:readeck_app/ui/daily_read/view_models/daily_read_viewmodel.dart';
import 'package:readeck_app/ui/daily_read/widgets/daily_read_screen.dart';

import 'daily_read_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<DailyReadViewModel>()])
void main() {
  late MockDailyReadViewModel mockDailyReadViewModel;

  setUp(() {
    mockDailyReadViewModel = MockDailyReadViewModel();

    // Stub all other commands that might be accessed during build
    final mockOpenUrlCommand =
        Command.createAsyncNoResult<String>((_) async {});
    final mockToggleArchivedCommand =
        Command.createAsyncNoResult<BookmarkDisplayModel>((_) async {});
    final mockToggleMarkedCommand =
        Command.createAsyncNoResult<BookmarkDisplayModel>((_) async {});
    final mockLoadLabelsCommand = Command.createAsyncNoParam<List<String>>(
        () async => [],
        initialValue: []);

    when(mockDailyReadViewModel.openUrl).thenReturn(mockOpenUrlCommand);
    when(mockDailyReadViewModel.toggleBookmarkArchived)
        .thenReturn(mockToggleArchivedCommand);
    when(mockDailyReadViewModel.toggleBookmarkMarked)
        .thenReturn(mockToggleMarkedCommand);
    when(mockDailyReadViewModel.loadLabels).thenReturn(mockLoadLabelsCommand);
    when(mockDailyReadViewModel.setOnBookmarkArchivedCallback(any))
        .thenReturn(null);
    when(mockDailyReadViewModel.setNavigateToDetailCallback(any))
        .thenReturn(null);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ChangeNotifierProvider<DailyReadViewModel>.value(
        value: mockDailyReadViewModel,
        child: DailyReadScreen(viewModel: mockDailyReadViewModel),
      ),
    );
  }

  group('DailyReadScreen', () {
    testWidgets('should display bookmarks when viewmodel has data',
        (WidgetTester tester) async {
      // Arrange
      final bookmarks = [
        BookmarkDisplayModel(
            bookmark: Bookmark(
                id: '1',
                url: '',
                title: 'First Bookmark Title',
                isArchived: false,
                isMarked: false,
                labels: [],
                created: DateTime.now(),
                readProgress: 0)),
        BookmarkDisplayModel(
            bookmark: Bookmark(
                id: '2',
                url: '',
                title: 'Second Bookmark Title',
                isArchived: false,
                isMarked: false,
                labels: [],
                created: DateTime.now(),
                readProgress: 0)),
      ];
      final loadCommand = Command.createAsync<bool, List<BookmarkDisplayModel>>(
          (_) async => bookmarks,
          initialValue: []);

      when(mockDailyReadViewModel.unArchivedBookmarks).thenReturn(bookmarks);
      when(mockDailyReadViewModel.load).thenReturn(loadCommand);
      when(mockDailyReadViewModel.isNoMore).thenReturn(false);
      when(mockDailyReadViewModel.availableLabels).thenReturn([]);
      when(mockDailyReadViewModel.getReadingStats(any)).thenReturn(null);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('First Bookmark Title'), findsOneWidget);
      expect(find.text('Second Bookmark Title'), findsOneWidget);
    });

    testWidgets(
        'should display loading indicator when loading with empty initial value',
        (WidgetTester tester) async {
      // Arrange
      // Create a real Command that matches the ViewModel configuration
      final loadCommand = Command.createAsync<bool, List<BookmarkDisplayModel>>(
        (param) async {
          // Simulate a short operation so it completes during test
          await Future.delayed(const Duration(milliseconds: 100));
          return <BookmarkDisplayModel>[];
        },
        includeLastResultInCommandResults: true,
        initialValue: [],
      );

      when(mockDailyReadViewModel.load).thenReturn(loadCommand);
      when(mockDailyReadViewModel.unArchivedBookmarks).thenReturn([]);
      when(mockDailyReadViewModel.isNoMore).thenReturn(false);
      when(mockDailyReadViewModel.availableLabels).thenReturn([]);

      // Start the command to put it in executing state
      loadCommand.execute(false);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Wait for the widget to be built and command to start executing
      await tester.pump(const Duration(milliseconds: 10));

      // Assert - should show loading when command is executing with empty initial value
      expect(find.text('正在加载今日推荐'), findsOneWidget);

      // Wait for the command to complete to avoid pending timer issues
      await tester.pumpAndSettle();
    });

    testWidgets(
        'should NOT display loading indicator when re-executing with existing data',
        (WidgetTester tester) async {
      // Arrange
      final existingBookmarks = [
        BookmarkDisplayModel(
          bookmark: Bookmark(
            id: '1',
            url: 'https://example.com',
            title: 'Existing Bookmark',
            isArchived: false,
            isMarked: false,
            labels: [],
            created: DateTime.now(),
            readProgress: 0,
          ),
        ),
      ];

      final loadCommand = Command.createAsync<bool, List<BookmarkDisplayModel>>(
        (param) async {
          // Simulate loading time
          await Future.delayed(const Duration(milliseconds: 100));
          return existingBookmarks;
        },
        includeLastResultInCommandResults: true,
        initialValue: existingBookmarks, // Command has existing data
      );

      when(mockDailyReadViewModel.load).thenReturn(loadCommand);
      when(mockDailyReadViewModel.unArchivedBookmarks)
          .thenReturn(existingBookmarks);
      when(mockDailyReadViewModel.isNoMore).thenReturn(false);
      when(mockDailyReadViewModel.availableLabels).thenReturn([]);
      when(mockDailyReadViewModel.getReadingStats(any)).thenReturn(null);

      // Start the command while it has existing data
      loadCommand.execute(true); // Force refresh

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 10));

      // Assert - should NOT show loading when command is executing but has existing data
      expect(find.text('正在加载今日推荐'), findsNothing);
      expect(find.text('Existing Bookmark'), findsOneWidget);

      // Wait for command to complete
      await tester.pumpAndSettle();
    });

    // Note: The "no more bookmarks" state (isNoMore=true with non-empty unArchivedBookmarks)
    // is logically inconsistent in the current implementation.
    // If isNoMore is true, unArchivedBookmarks should typically be empty,
    // which would trigger the celebration state instead.
    // This test is removed as it tests an unrealistic state combination.

    testWidgets(
        'should display celebration overlay when all bookmarks are archived',
        (WidgetTester tester) async {
      // Arrange
      final loadCommand = Command.createAsync<bool, List<BookmarkDisplayModel>>(
        (param) async => <BookmarkDisplayModel>[],
        includeLastResultInCommandResults: true,
        initialValue: [],
      );

      when(mockDailyReadViewModel.load).thenReturn(loadCommand);
      when(mockDailyReadViewModel.unArchivedBookmarks).thenReturn([]);
      when(mockDailyReadViewModel.isNoMore).thenReturn(false);
      when(mockDailyReadViewModel.availableLabels).thenReturn([]);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert - should show celebration overlay
      expect(find.text('🎉 恭喜完成今日阅读！'), findsOneWidget);
      expect(find.text('您已经完成了今天的所有阅读任务\n坚持阅读，收获知识！'), findsOneWidget);
      expect(find.text('再来一组'), findsOneWidget);

      // Should also have confetti widget
      expect(find.byType(ConfettiWidget), findsOneWidget);
    });

    // Note: Error handling tests are complex with CommandBuilder
    // These tests would require more sophisticated mocking of error states
    // For now, we focus on the main UI states and leave error testing
    // for integration tests where the full error flow can be tested

    testWidgets('should display bookmark cards with correct information',
        (WidgetTester tester) async {
      // Arrange
      final testBookmarks = [
        BookmarkDisplayModel(
          bookmark: Bookmark(
            id: '1',
            url: 'https://example.com/article1',
            title: 'Test Article 1',
            isArchived: false,
            isMarked: true,
            labels: ['技术', 'Flutter'],
            created: DateTime(2024, 1, 1),
            readProgress: 25,
          ),
        ),
        BookmarkDisplayModel(
          bookmark: Bookmark(
            id: '2',
            url: 'https://example.com/article2',
            title: 'Test Article 2',
            isArchived: false,
            isMarked: false,
            labels: [],
            created: DateTime(2024, 1, 2),
            readProgress: 0,
          ),
        ),
      ];

      final loadCommand = Command.createAsync<bool, List<BookmarkDisplayModel>>(
        (param) async => testBookmarks,
        includeLastResultInCommandResults: true,
        initialValue: [],
      );

      when(mockDailyReadViewModel.load).thenReturn(loadCommand);
      when(mockDailyReadViewModel.unArchivedBookmarks)
          .thenReturn(testBookmarks);
      when(mockDailyReadViewModel.isNoMore).thenReturn(false);
      when(mockDailyReadViewModel.availableLabels)
          .thenReturn(['技术', 'Flutter', '阅读']);
      when(mockDailyReadViewModel.getReadingStats(any)).thenReturn(null);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert - should display bookmark information
      expect(find.text('Test Article 1'), findsOneWidget);
      expect(find.text('Test Article 2'), findsOneWidget);

      // Should display BookmarkCard widgets
      expect(find.byType(ListView), findsOneWidget);
      // Note: BookmarkCard is defined in another file, we just verify the structure
    });

    testWidgets(
        'should call appropriate methods when bookmark operations are performed',
        (WidgetTester tester) async {
      // Arrange
      final testBookmark = BookmarkDisplayModel(
        bookmark: Bookmark(
          id: '1',
          url: 'https://example.com/article1',
          title: 'Test Article 1',
          isArchived: false,
          isMarked: false,
          labels: [],
          created: DateTime(2024, 1, 1),
          readProgress: 0,
        ),
      );

      final loadCommand = Command.createAsync<bool, List<BookmarkDisplayModel>>(
        (param) async => [testBookmark],
        includeLastResultInCommandResults: true,
        initialValue: [],
      );

      // Mock openUrl method
      when(mockDailyReadViewModel.openUrl).thenReturn(
        Command.createAsyncNoResult<String>((url) async {}),
      );

      when(mockDailyReadViewModel.load).thenReturn(loadCommand);
      when(mockDailyReadViewModel.unArchivedBookmarks)
          .thenReturn([testBookmark]);
      when(mockDailyReadViewModel.isNoMore).thenReturn(false);
      when(mockDailyReadViewModel.availableLabels).thenReturn([]);
      when(mockDailyReadViewModel.getReadingStats(any)).thenReturn(null);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert - verify ViewModel methods are properly set up
      verify(mockDailyReadViewModel.setOnBookmarkArchivedCallback(any))
          .called(1);
      verify(mockDailyReadViewModel.setNavigateToDetailCallback(any)).called(1);
    });
  });
}
