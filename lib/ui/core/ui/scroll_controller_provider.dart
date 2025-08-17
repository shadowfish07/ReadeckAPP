import 'package:flutter/material.dart';

/// FAB 滚动状态回调
typedef FabScrollCallback = void Function(
    double scrollPosition, double scrollDelta);

/// 提供 FAB 滚动状态回调给子页面使用
class ScrollControllerProvider extends InheritedWidget {
  const ScrollControllerProvider({
    super.key,
    required this.fabScrollCallback,
    required super.child,
  });

  final FabScrollCallback? fabScrollCallback;

  static FabScrollCallback? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ScrollControllerProvider>()
        ?.fabScrollCallback;
  }

  @override
  bool updateShouldNotify(ScrollControllerProvider oldWidget) {
    return fabScrollCallback != oldWidget.fabScrollCallback;
  }
}
