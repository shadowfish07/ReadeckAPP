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

@GenerateMocks([DailyReadViewModel])
void main() {
  late MockDailyReadViewModel mockDailyReadViewModel;

  setUp(() {
    mockDailyReadViewModel = MockDailyReadViewModel();

    // Stub all other commands that might be accessed during build
    final mockOpenUrlCommand =
        Command.createAsyncNoResult<String>((_) async {});
    final mockToggleArchivedCommand =
        Command.createAsyncNoResult<Bookmark>((_) async {});
    final mockToggleMarkedCommand =
        Command.createAsyncNoResult<Bookmark>((_) async {});
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

    testWidgets('should display loading indicator when loading',
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
  });
}
