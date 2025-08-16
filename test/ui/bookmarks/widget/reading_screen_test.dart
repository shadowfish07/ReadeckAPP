import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/bookmark_display_model/bookmark_display_model.dart';
import 'package:readeck_app/ui/bookmarks/view_models/bookmarks_viewmodel.dart';
import 'package:readeck_app/ui/bookmarks/widget/reading_screen.dart';

import 'reading_screen_test.mocks.dart';

@GenerateMocks([ReadingViewmodel])
void main() {
  late MockReadingViewmodel mockReadingViewmodel;

  setUp(() {
    mockReadingViewmodel = MockReadingViewmodel();

    // Stub all commands that might be accessed during build
    final mockLoadCommand =
        Command.createAsync<int, List<BookmarkDisplayModel>>((_) async => [],
            initialValue: [], includeLastResultInCommandResults: true);
    final mockLoadMoreCommand =
        Command.createAsync<int, List<BookmarkDisplayModel>>((_) async => [],
            initialValue: [], includeLastResultInCommandResults: true);
    final mockOpenUrlCommand =
        Command.createAsyncNoResult<String>((_) async {});
    final mockToggleArchivedCommand =
        Command.createAsyncNoResult<BookmarkDisplayModel>((_) async {});
    final mockToggleMarkedCommand =
        Command.createAsyncNoResult<BookmarkDisplayModel>((_) async {});
    final mockLoadLabelsCommand = Command.createAsyncNoParam<List<String>>(
        () async => [],
        initialValue: []);

    when(mockReadingViewmodel.load).thenReturn(mockLoadCommand);
    when(mockReadingViewmodel.loadMore).thenReturn(mockLoadMoreCommand);
    when(mockReadingViewmodel.openUrl).thenReturn(mockOpenUrlCommand);
    when(mockReadingViewmodel.toggleBookmarkArchived)
        .thenReturn(mockToggleArchivedCommand);
    when(mockReadingViewmodel.toggleBookmarkMarked)
        .thenReturn(mockToggleMarkedCommand);
    when(mockReadingViewmodel.loadLabels).thenReturn(mockLoadLabelsCommand);
    when(mockReadingViewmodel.bookmarks).thenReturn([]);
    when(mockReadingViewmodel.hasMoreData).thenReturn(false);
    when(mockReadingViewmodel.isLoadingMore).thenReturn(false);
    when(mockReadingViewmodel.availableLabels).thenReturn([]);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ChangeNotifierProvider<ReadingViewmodel>.value(
        value: mockReadingViewmodel,
        child: ReadingScreen(viewModel: mockReadingViewmodel),
      ),
    );
  }

  group('ReadingScreen Widget Tests', () {
    testWidgets('should display empty state when no reading bookmarks',
        (WidgetTester tester) async {
      // Arrange
      final completedCommand =
          Command.createAsync<int, List<BookmarkDisplayModel>>((_) async => [],
              initialValue: [], includeLastResultInCommandResults: true);
      when(mockReadingViewmodel.load).thenReturn(completedCommand);
      when(mockReadingViewmodel.bookmarks).thenReturn([]);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Allow commands to complete

      // Assert
      expect(find.byIcon(Icons.auto_stories_outlined), findsOneWidget);
      expect(find.text('暂无阅读中书签'), findsOneWidget);
      expect(find.text('下拉刷新或去Readeck开始阅读书签'), findsOneWidget);
    });

    testWidgets('should display reading bookmarks when available',
        (WidgetTester tester) async {
      // Arrange
      final readingBookmarks = [
        BookmarkDisplayModel(
          bookmark: Bookmark(
            id: '1',
            url: 'https://example.com/1',
            title: 'Reading Book 1',
            isArchived: false,
            isMarked: false,
            labels: [],
            created: DateTime.now(),
            readProgress: 25,
          ),
        ),
        BookmarkDisplayModel(
          bookmark: Bookmark(
            id: '2',
            url: 'https://example.com/2',
            title: 'Reading Book 2',
            isArchived: false,
            isMarked: false,
            labels: [],
            created: DateTime.now(),
            readProgress: 75,
          ),
        ),
      ];

      final completedCommand =
          Command.createAsync<int, List<BookmarkDisplayModel>>(
              (_) async => readingBookmarks,
              initialValue: readingBookmarks,
              includeLastResultInCommandResults: true);
      when(mockReadingViewmodel.load).thenReturn(completedCommand);
      when(mockReadingViewmodel.bookmarks).thenReturn(readingBookmarks);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Allow commands to complete

      // Assert
      expect(find.text('Reading Book 1'), findsOneWidget);
      expect(find.text('Reading Book 2'), findsOneWidget);
    });

    testWidgets('should use correct texts for reading context',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Verify the screen uses the correct BookmarkListTexts
      // This is verified by checking the empty state which uses these texts
      when(mockReadingViewmodel.bookmarks).thenReturn([]);
      await tester.pump();

      // Assert that the appropriate reading-related texts are shown
      expect(find.byIcon(Icons.auto_stories_outlined), findsOneWidget);
      expect(find.text('暂无阅读中书签'), findsOneWidget);
      expect(find.text('下拉刷新或去Readeck开始阅读书签'), findsOneWidget);
    });
  });
}
