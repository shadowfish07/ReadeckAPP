import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/models/bookmark_display_model/bookmark_display_model.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/ui/core/ui/bookmark_card.dart';
import 'package:readeck_app/ui/core/ui/label_edit_dialog.dart';

void main() {
  setUpAll(() {
    // 初始化 logger
    appLogger = Logger();
  });
  late Command mockOpenUrlCommand;
  late BookmarkDisplayModel testBookmarkDisplayModel;
  late List<String> availableLabels;
  bool updateLabelsCalled = false;

  setUp(() {
    // Create a real Command instead of a mock
    mockOpenUrlCommand = Command.createAsyncNoResult<String>((_) async {});
    updateLabelsCalled = false;

    testBookmarkDisplayModel = BookmarkDisplayModel(
      bookmark: Bookmark(
        id: '1',
        url: 'https://example.com',
        title: 'Test Article',
        isArchived: false,
        isMarked: false,
        labels: ['existing-label'],
        created: DateTime.now(),
        readProgress: 50,
      ),
    );

    availableLabels = ['label1', 'label2', 'existing-label'];
  });

  Widget createWidgetUnderTest({
    Function(BookmarkDisplayModel, List<String>)? onUpdateLabels,
    Future<List<String>> Function()? onLoadLabels,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BookmarkCard(
          bookmarkDisplayModel: testBookmarkDisplayModel,
          onOpenUrl: mockOpenUrlCommand,
          onUpdateLabels: onUpdateLabels ??
              (bookmark, labels) {
                updateLabelsCalled = true;
              },
          availableLabels: availableLabels,
          onLoadLabels: onLoadLabels,
        ),
      ),
    );
  }

  group('BookmarkCard Label Edit Tests', () {
    testWidgets('should display label edit button',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.local_offer_outlined), findsOneWidget);
      expect(find.byTooltip('编辑标签'), findsOneWidget);
    });

    testWidgets('should open label edit dialog when label button is tapped',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap the label edit button
      await tester.tap(find.byIcon(Icons.local_offer_outlined));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(LabelEditDialog), findsOneWidget);
      expect(find.text('编辑标签'), findsOneWidget);
    });

    testWidgets(
        'should show success toast when labels are updated successfully',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Open label edit dialog
      await tester.tap(find.byIcon(Icons.local_offer_outlined));
      await tester.pumpAndSettle();

      // Simulate label update by tapping save button
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // Assert - check that success toast is shown
      expect(find.text('标签已更新'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      // Verify the callback was called
      expect(updateLabelsCalled, isTrue);
    });

    testWidgets('should show error toast when label update fails',
        (WidgetTester tester) async {
      // Arrange - create a callback that throws an error
      void failingOnUpdateLabels(
          BookmarkDisplayModel bookmark, List<String> labels) {
        throw Exception('Network error');
      }

      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        onUpdateLabels: failingOnUpdateLabels,
      ));
      await tester.pumpAndSettle();

      // Open label edit dialog
      await tester.tap(find.byIcon(Icons.local_offer_outlined));
      await tester.pumpAndSettle();

      // Simulate label update by tapping save button
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // Assert - check that error toast is shown
      expect(find.textContaining('更新标签失败'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('should display existing labels in the card',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert - check that existing labels are displayed
      expect(find.text('existing-label'), findsOneWidget);
    });

    testWidgets('should work with provided onUpdateLabels callback',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert - button should exist and be enabled
      expect(find.byIcon(Icons.local_offer_outlined), findsOneWidget);

      // Find all IconButton widgets and check the label edit button specifically
      final iconButtons =
          tester.widgetList<IconButton>(find.byType(IconButton));
      final labelButton = iconButtons.firstWhere(
        (button) =>
            button.icon is Icon &&
            (button.icon as Icon).icon == Icons.local_offer_outlined,
      );
      expect(labelButton.onPressed, isNotNull);
    });
  });

  group('BookmarkCard General Tests', () {
    testWidgets('should display bookmark title', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Article'), findsOneWidget);
    });

    testWidgets('should display reading progress', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('50%'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display favorite button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('should display archive button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
    });

    testWidgets('should show success toast when bookmark is archived',
        (WidgetTester tester) async {
      bool archiveCalled = false;

      // Create widget with archive callback
      final widget = MaterialApp(
        home: Scaffold(
          body: BookmarkCard(
            bookmarkDisplayModel: testBookmarkDisplayModel,
            onOpenUrl: mockOpenUrlCommand,
            onToggleArchive: (bookmark) {
              archiveCalled = true;
            },
            availableLabels: availableLabels,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Tap archive button
      await tester.tap(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();

      // Assert
      expect(archiveCalled, isTrue);
      expect(find.text('已标记归档'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('BookmarkCard Tap Tests', () {
    testWidgets('should call onCardTap when card is tapped', (tester) async {
      // Arrange
      bool cardTapCalled = false;
      Bookmark? cardTapBookmark;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookmarkCard(
              bookmarkDisplayModel: testBookmarkDisplayModel,
              onOpenUrl: mockOpenUrlCommand,
              onCardTap: (bookmark) {
                cardTapCalled = true;
                cardTapBookmark = bookmark.bookmark;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(BookmarkCard));
      await tester.pumpAndSettle();

      // Assert
      expect(cardTapCalled, true);
      expect(cardTapBookmark, testBookmarkDisplayModel.bookmark);
    });

    testWidgets('should handle null onCardTap gracefully', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookmarkCard(
              bookmarkDisplayModel: testBookmarkDisplayModel,
              onOpenUrl: mockOpenUrlCommand,
              // onCardTap is null
            ),
          ),
        ),
      );

      // Should not throw when tapped
      await tester.tap(find.byType(BookmarkCard));
      await tester.pumpAndSettle();

      // Test passes if no exception is thrown
    });
  });
}
