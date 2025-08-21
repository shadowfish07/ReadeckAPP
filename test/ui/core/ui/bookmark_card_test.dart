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
    Function(BookmarkDisplayModel)? onDeleteBookmark,
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
          onDeleteBookmark: onDeleteBookmark,
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

  group('BookmarkCard Long Press Context Menu Tests', () {
    testWidgets('should show context menu on long press',
        (WidgetTester tester) async {
      // Arrange

      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        onDeleteBookmark: (bookmark) {
          // Callback for delete
        },
      ));
      await tester.pumpAndSettle();

      // Long press on the card
      await tester.longPress(find.byType(BookmarkCard));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PopupMenuButton).hitTestable(), findsOneWidget);
      expect(find.text('删除书签'), findsOneWidget);
    });

    testWidgets('should not show context menu when onDeleteBookmark is null',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        onDeleteBookmark: null,
      ));
      await tester.pumpAndSettle();

      // Long press on the card
      await tester.longPress(find.byType(BookmarkCard));
      await tester.pumpAndSettle();

      // Assert - context menu should not appear
      expect(find.text('删除书签'), findsNothing);
    });

    testWidgets(
        'should show delete confirmation dialog when delete menu item is tapped',
        (WidgetTester tester) async {
      // Arrange
      bool deleteCallbackCalled = false;

      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        onDeleteBookmark: (bookmark) {
          deleteCallbackCalled = true;
        },
      ));
      await tester.pumpAndSettle();

      // Long press to show context menu
      await tester.longPress(find.byType(BookmarkCard));
      await tester.pumpAndSettle();

      // Tap delete menu item
      await tester.tap(find.text('删除书签'));
      await tester.pumpAndSettle();

      // Assert - confirmation dialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('确认删除'), findsOneWidget);
      expect(find.text('确定要删除这个书签吗？此操作无法撤销。'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);

      // Delete callback should not be called yet
      expect(deleteCallbackCalled, isFalse);
    });

    testWidgets('should call onDeleteBookmark when delete is confirmed',
        (WidgetTester tester) async {
      // Arrange
      bool deleteCallbackCalled = false;
      BookmarkDisplayModel? deletedBookmark;

      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        onDeleteBookmark: (bookmark) {
          deleteCallbackCalled = true;
          deletedBookmark = bookmark;
        },
      ));
      await tester.pumpAndSettle();

      // Long press to show context menu
      await tester.longPress(find.byType(BookmarkCard));
      await tester.pumpAndSettle();

      // Tap delete menu item
      await tester.tap(find.text('删除书签'));
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.text('删除').last);
      await tester.pumpAndSettle();

      // Assert
      expect(deleteCallbackCalled, isTrue);
      expect(deletedBookmark, equals(testBookmarkDisplayModel));
    });

    testWidgets('should not call onDeleteBookmark when deletion is cancelled',
        (WidgetTester tester) async {
      // Arrange
      bool deleteCallbackCalled = false;

      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        onDeleteBookmark: (bookmark) {
          deleteCallbackCalled = true;
        },
      ));
      await tester.pumpAndSettle();

      // Long press to show context menu
      await tester.longPress(find.byType(BookmarkCard));
      await tester.pumpAndSettle();

      // Tap delete menu item
      await tester.tap(find.text('删除书签'));
      await tester.pumpAndSettle();

      // Cancel deletion
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // Assert
      expect(deleteCallbackCalled, isFalse);
    });

    testWidgets('should show success message when delete operation succeeds',
        (WidgetTester tester) async {
      // Arrange - this will test the UI feedback after successful deletion
      await tester.pumpWidget(createWidgetUnderTest(
        onDeleteBookmark: (bookmark) {
          // Simulate successful deletion
        },
      ));
      await tester.pumpAndSettle();

      // Long press to show context menu
      await tester.longPress(find.byType(BookmarkCard));
      await tester.pumpAndSettle();

      // Tap delete menu item
      await tester.tap(find.text('删除书签'));
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.text('删除').last);
      await tester.pumpAndSettle();

      // Assert - success message should appear
      expect(find.text('书签已删除'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets(
        'should maintain existing tap behavior when long press is not triggered',
        (WidgetTester tester) async {
      // Arrange
      bool cardTapCalled = false;
      bool deleteCallbackCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookmarkCard(
              bookmarkDisplayModel: testBookmarkDisplayModel,
              onOpenUrl: mockOpenUrlCommand,
              onCardTap: (bookmark) {
                cardTapCalled = true;
              },
              onDeleteBookmark: (bookmark) {
                deleteCallbackCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Normal tap (not long press)
      await tester.tap(find.byType(BookmarkCard));
      await tester.pumpAndSettle();

      // Assert
      expect(cardTapCalled, isTrue);
      expect(deleteCallbackCalled, isFalse);
      expect(find.text('删除书签'), findsNothing);
    });
  });
}
