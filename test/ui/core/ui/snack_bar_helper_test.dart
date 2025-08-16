import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readeck_app/ui/core/ui/snack_bar_helper.dart';

void main() {
  group('SnackBarHelper', () {
    testWidgets('showSuccess displays success SnackBar with correct styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackBarHelper.showSuccess(context, '操作成功');
                  },
                  child: const Text('Show Success'),
                ),
              );
            },
          ),
        ),
      );

      // 点击按钮显示 SnackBar
      await tester.tap(find.text('Show Success'));
      await tester.pump(); // 触发动画开始
      await tester.pump(const Duration(milliseconds: 750)); // 等待动画完成

      // 验证 SnackBar 是否出现
      expect(find.text('操作成功'), findsOneWidget);

      // 验证 SnackBar 样式
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.margin, const EdgeInsets.all(16.0));
      expect(snackBar.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('showError displays error SnackBar with correct styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackBarHelper.showError(context, '操作失败');
                  },
                  child: const Text('Show Error'),
                ),
              );
            },
          ),
        ),
      );

      // 点击按钮显示 SnackBar
      await tester.tap(find.text('Show Error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      // 验证 SnackBar 是否出现
      expect(find.text('操作失败'), findsOneWidget);

      // 验证 SnackBar 样式
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.duration, const Duration(seconds: 5));
    });

    testWidgets('showInfo displays info SnackBar with correct styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackBarHelper.showInfo(context, '信息提示');
                  },
                  child: const Text('Show Info'),
                ),
              );
            },
          ),
        ),
      );

      // 点击按钮显示 SnackBar
      await tester.tap(find.text('Show Info'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      // 验证 SnackBar 是否出现
      expect(find.text('信息提示'), findsOneWidget);

      // 验证默认持续时间
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, const Duration(seconds: 4));
    });

    testWidgets('showWarning displays warning SnackBar with correct styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackBarHelper.showWarning(context, '警告信息');
                  },
                  child: const Text('Show Warning'),
                ),
              );
            },
          ),
        ),
      );

      // 点击按钮显示 SnackBar
      await tester.tap(find.text('Show Warning'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      // 验证 SnackBar 是否出现
      expect(find.text('警告信息'), findsOneWidget);
    });

    testWidgets('SnackBar with action button works correctly',
        (WidgetTester tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackBarHelper.showError(
                      context,
                      '操作失败',
                      action: SnackBarAction(
                        label: '重试',
                        onPressed: () {
                          actionPressed = true;
                        },
                      ),
                    );
                  },
                  child: const Text('Show Error with Action'),
                ),
              );
            },
          ),
        ),
      );

      // 点击按钮显示 SnackBar
      await tester.tap(find.text('Show Error with Action'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      // 验证 SnackBar 和 Action 是否出现
      expect(find.text('操作失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);

      // 点击 Action 按钮
      await tester.tap(find.text('重试'));
      await tester.pump();

      // 验证 Action 回调是否被调用
      expect(actionPressed, isTrue);
    });

    testWidgets('custom duration is respected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackBarHelper.showSuccess(
                      context,
                      '自定义持续时间',
                      duration: const Duration(seconds: 10),
                    );
                  },
                  child: const Text('Show Custom Duration'),
                ),
              );
            },
          ),
        ),
      );

      // 点击按钮显示 SnackBar
      await tester.tap(find.text('Show Custom Duration'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      // 验证自定义持续时间
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, const Duration(seconds: 10));
    });

    testWidgets('SnackBar colors match theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    SnackBarHelper.showSuccess(context, '主题颜色测试');
                  },
                  child: const Text('Show Themed SnackBar'),
                ),
              );
            },
          ),
        ),
      );

      // 点击按钮显示 SnackBar
      await tester.tap(find.text('Show Themed SnackBar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      // 验证 SnackBar 是否出现
      expect(find.text('主题颜色测试'), findsOneWidget);

      // 验证背景颜色是否使用了主题颜色
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final theme = Theme.of(tester.element(find.text('主题颜色测试')));
      expect(snackBar.backgroundColor, theme.colorScheme.inverseSurface);
    });
  });
}
