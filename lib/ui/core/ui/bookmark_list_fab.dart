import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:readeck_app/routing/routes.dart';

/// 书签列表页面的浮动操作按钮
///
/// 特性：
/// - Material Design 3 规范的FAB
/// - 支持滚动时自动隐藏/显示动画
/// - 点击跳转到添加书签页面
/// - 通过Provider获取ScrollController
class BookmarkListFab extends StatefulWidget {
  const BookmarkListFab({
    super.key,
    this.scrollController,
  });

  final ScrollController? scrollController;

  @override
  State<BookmarkListFab> createState() => _BookmarkListFabState();
}

class _BookmarkListFabState extends State<BookmarkListFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isVisible = true;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // 初始状态显示FAB
    _animationController.forward();

    // 监听滚动事件
    _attachScrollListener();
  }

  @override
  void didUpdateWidget(BookmarkListFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      _detachScrollListener(oldWidget.scrollController);
      _attachScrollListener();
    }
  }

  @override
  void dispose() {
    _detachScrollListener(widget.scrollController);
    _animationController.dispose();
    super.dispose();
  }

  void _attachScrollListener() {
    widget.scrollController?.addListener(_onScroll);
  }

  void _detachScrollListener(ScrollController? controller) {
    controller?.removeListener(_onScroll);
  }

  void _onScroll() {
    if (widget.scrollController == null ||
        !widget.scrollController!.hasClients) {
      return;
    }

    final currentScrollPosition = widget.scrollController!.position.pixels;
    final scrollDelta = currentScrollPosition - _lastScrollPosition;

    // 滚动阈值，避免微小滚动导致频繁切换
    const scrollThreshold = 3.0;

    // 如果滚动距离太小，忽略
    if (scrollDelta.abs() < scrollThreshold) {
      return;
    }

    // 在顶部附近时总是显示FAB
    if (currentScrollPosition <= 50) {
      if (!_isVisible) {
        setState(() {
          _isVisible = true;
        });
        _animationController.forward();
      }
    } else {
      if (scrollDelta > 0) {
        // 向下滚动，隐藏FAB
        if (_isVisible) {
          setState(() {
            _isVisible = false;
          });
          _animationController.reverse();
        }
      } else if (scrollDelta < 0) {
        // 向上滚动，显示FAB
        if (!_isVisible) {
          setState(() {
            _isVisible = true;
          });
          _animationController.forward();
        }
      }
    }

    _lastScrollPosition = currentScrollPosition;
  }

  void _onFabPressed() {
    context.push(Routes.addBookmark);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: FloatingActionButton(
        onPressed: _onFabPressed,
        tooltip: '添加书签',
        child: const Icon(Icons.add),
      ),
    );
  }
}
