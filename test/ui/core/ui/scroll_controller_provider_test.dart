import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readeck_app/ui/core/ui/scroll_controller_provider.dart';

void main() {
  group('ScrollControllerProvider', () {
    testWidgets('should provide FAB scroll callback to child widgets',
        (WidgetTester tester) async {
      FabScrollCallback? receivedCallback;
      bool callbackInvoked = false;
      double receivedScrollPosition = 0;
      double receivedScrollDelta = 0;

      void testCallback(double scrollPosition, double scrollDelta) {
        callbackInvoked = true;
        receivedScrollPosition = scrollPosition;
        receivedScrollDelta = scrollDelta;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: ScrollControllerProvider(
            fabScrollCallback: testCallback,
            child: Builder(
              builder: (context) {
                receivedCallback = ScrollControllerProvider.of(context);
                return const Scaffold(
                  body: Text('Test Child'),
                );
              },
            ),
          ),
        ),
      );

      // 验证回调被正确传递
      expect(receivedCallback, isNotNull);
      expect(receivedCallback, equals(testCallback));

      // 验证回调功能正常
      receivedCallback!(100.0, 10.0);
      expect(callbackInvoked, isTrue);
      expect(receivedScrollPosition, equals(100.0));
      expect(receivedScrollDelta, equals(10.0));
    });

    testWidgets('should return null when no provider is found',
        (WidgetTester tester) async {
      FabScrollCallback? receivedCallback;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              receivedCallback = ScrollControllerProvider.of(context);
              return const Scaffold(
                body: Text('Test Child'),
              );
            },
          ),
        ),
      );

      expect(receivedCallback, isNull);
    });

    testWidgets('should trigger updateShouldNotify when callback changes',
        (WidgetTester tester) async {
      void callback1(double scrollPosition, double scrollDelta) {}
      void callback2(double scrollPosition, double scrollDelta) {}

      Widget buildProvider(FabScrollCallback? callback) {
        return ScrollControllerProvider(
          fabScrollCallback: callback,
          child: const Text('Test'),
        );
      }

      final provider1 = buildProvider(callback1);
      final provider2 = buildProvider(callback2);
      final provider3 = buildProvider(callback1);

      // 不同的回调应该触发更新
      expect(
        (provider2 as ScrollControllerProvider)
            .updateShouldNotify(provider1 as ScrollControllerProvider),
        isTrue,
      );

      // 相同的回调不应该触发更新
      expect(
        (provider3 as ScrollControllerProvider).updateShouldNotify(provider1),
        isFalse,
      );
    });

    testWidgets('should handle null callback correctly',
        (WidgetTester tester) async {
      FabScrollCallback? receivedCallback;

      await tester.pumpWidget(
        MaterialApp(
          home: ScrollControllerProvider(
            fabScrollCallback: null,
            child: Builder(
              builder: (context) {
                receivedCallback = ScrollControllerProvider.of(context);
                return const Scaffold(
                  body: Text('Test Child'),
                );
              },
            ),
          ),
        ),
      );

      expect(receivedCallback, isNull);
    });
  });
}
