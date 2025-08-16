import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readeck_app/ui/core/ui/scroll_controller_provider.dart';

void main() {
  group('FAB Animation Tests', () {
    testWidgets('FAB should animate when scroll callback is triggered',
        (WidgetTester tester) async {
      bool callbackTriggered = false;
      double receivedScrollPosition = 0;
      double receivedScrollDelta = 0;

      void testCallback(double scrollPosition, double scrollDelta) {
        callbackTriggered = true;
        receivedScrollPosition = scrollPosition;
        receivedScrollDelta = scrollDelta;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollControllerProvider(
              fabScrollCallback: testCallback,
              child: Builder(
                builder: (context) {
                  final callback = ScrollControllerProvider.of(context);
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => callback?.call(100.0, 10.0),
                        child: const Text('Trigger Scroll'),
                      ),
                      const Expanded(child: Text('Content')),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // 点击按钮触发滚动回调
      await tester.tap(find.text('Trigger Scroll'));
      await tester.pump();

      expect(callbackTriggered, isTrue);
      expect(receivedScrollPosition, equals(100.0));
      expect(receivedScrollDelta, equals(10.0));
    });

    testWidgets(
        'FAB scale animation should respond correctly to scroll direction',
        (WidgetTester tester) async {
      // 测试模拟FAB动画逻辑
      late AnimationController animationController;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              animationController = AnimationController(
                duration: const Duration(milliseconds: 200),
                vsync: tester,
              );

              return Scaffold(
                body: const Center(child: Text('Test Content')),
                floatingActionButton: ScaleTransition(
                  scale: animationController,
                  child: FloatingActionButton(
                    onPressed: () {},
                    child: const Icon(Icons.add),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // 初始化动画到完全显示状态
      animationController.reset();
      animationController.forward();
      await tester.pumpAndSettle();

      // 验证初始状态FAB可见
      expect(animationController.value, equals(1.0));

      // 模拟向下滚动（隐藏FAB）
      animationController.reverse();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(animationController.value, lessThan(1.0));

      // 模拟向上滚动（显示FAB）
      animationController.forward();
      await tester.pumpAndSettle();
      expect(animationController.value, equals(1.0));

      animationController.dispose();
    });

    group('Scroll Animation Logic', () {
      testWidgets('should show FAB when at top of list',
          (WidgetTester tester) async {
        // 这里测试滚动位置 <= 50 时FAB应该显示的逻辑
        bool isVisible = true;

        // 模拟滚动回调逻辑
        void onScroll(double scrollPosition, double scrollDelta) {
          const scrollThreshold = 3.0;

          if (scrollDelta.abs() < scrollThreshold) {
            return;
          }

          if (scrollPosition <= 50) {
            isVisible = true;
          } else {
            if (scrollDelta > 0) {
              // 向下滚动，隐藏FAB
              isVisible = false;
            } else if (scrollDelta < 0) {
              // 向上滚动，显示FAB
              isVisible = true;
            }
          }
        }

        // 测试在顶部时
        onScroll(0, 5);
        expect(isVisible, isTrue);

        onScroll(30, 5);
        expect(isVisible, isTrue);

        // 测试向下滚动
        onScroll(100, 10);
        expect(isVisible, isFalse);

        // 测试向上滚动
        onScroll(90, -10);
        expect(isVisible, isTrue);

        // 测试小幅滚动被忽略
        isVisible = false;
        onScroll(100, 2); // 小于阈值
        expect(isVisible, isFalse); // 应该保持原状态
      });

      testWidgets('should handle scroll threshold correctly',
          (WidgetTester tester) async {
        bool animationTriggered = false;

        void onScrollWithAnimation(double scrollPosition, double scrollDelta) {
          const scrollThreshold = 3.0;

          // 如果滚动距离太小，忽略
          if (scrollDelta.abs() < scrollThreshold) {
            return;
          }

          animationTriggered = true;
        }

        // 测试小于阈值的滚动
        animationTriggered = false;
        onScrollWithAnimation(50, 2);
        expect(animationTriggered, isFalse);

        onScrollWithAnimation(50, -2);
        expect(animationTriggered, isFalse);

        // 测试大于阈值的滚动
        onScrollWithAnimation(50, 5);
        expect(animationTriggered, isTrue);

        animationTriggered = false;
        onScrollWithAnimation(50, -5);
        expect(animationTriggered, isTrue);
      });

      testWidgets('should always show FAB when near top',
          (WidgetTester tester) async {
        bool shouldShow = false;

        void onScrollNearTop(double scrollPosition, double scrollDelta) {
          const scrollThreshold = 3.0;

          if (scrollDelta.abs() < scrollThreshold) {
            return;
          }

          // 在顶部附近时总是显示FAB
          if (scrollPosition <= 50) {
            shouldShow = true;
          } else {
            shouldShow = scrollDelta < 0; // 只有向上滚动时才显示
          }
        }

        // 测试在顶部附近，无论滚动方向都应该显示
        onScrollNearTop(0, 10); // 向下滚动，但在顶部
        expect(shouldShow, isTrue);

        onScrollNearTop(30, 10); // 向下滚动，但在顶部
        expect(shouldShow, isTrue);

        onScrollNearTop(50, 10); // 向下滚动，但在边界
        expect(shouldShow, isTrue);

        // 测试离开顶部区域
        onScrollNearTop(100, 10); // 向下滚动，离开顶部
        expect(shouldShow, isFalse);

        onScrollNearTop(100, -10); // 向上滚动，离开顶部
        expect(shouldShow, isTrue);
      });
    });
  });
}
