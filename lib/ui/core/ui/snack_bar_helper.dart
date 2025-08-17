import 'package:flutter/material.dart';
import '../../../main.dart';

/// SnackBar 辅助类，提供符合 Material Design 3 规范的统一样式
class SnackBarHelper {
  /// 显示成功消息的 SnackBar
  static void showSuccess(
    BuildContext? context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: context != null
          ? Theme.of(context).colorScheme.inverseSurface
          : Colors.grey[900]!,
      textColor: context != null
          ? Theme.of(context).colorScheme.onInverseSurface
          : Colors.white,
      duration: duration,
      action: action,
    );
  }

  /// 使用全局context显示成功消息的 SnackBar
  static void showSuccessGlobal(
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    showSuccess(null, message, duration: duration, action: action);
  }

  /// 显示错误消息的 SnackBar
  static void showError(
    BuildContext? context,
    String message, {
    Duration duration = const Duration(seconds: 5),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: context != null
          ? Theme.of(context).colorScheme.errorContainer
          : Colors.red[100]!,
      textColor: context != null
          ? Theme.of(context).colorScheme.onErrorContainer
          : Colors.red[900]!,
      duration: duration,
      action: action,
    );
  }

  /// 使用全局context显示错误消息的 SnackBar
  static void showErrorGlobal(
    String message, {
    Duration duration = const Duration(seconds: 5),
    SnackBarAction? action,
  }) {
    showError(null, message, duration: duration, action: action);
  }

  /// 显示信息消息的 SnackBar
  static void showInfo(
    BuildContext? context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: context != null
          ? Theme.of(context).colorScheme.inverseSurface
          : Colors.grey[900]!,
      textColor: context != null
          ? Theme.of(context).colorScheme.onInverseSurface
          : Colors.white,
      duration: duration,
      action: action,
    );
  }

  /// 显示警告消息的 SnackBar
  static void showWarning(
    BuildContext? context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: context != null
          ? Theme.of(context).colorScheme.tertiaryContainer
          : Colors.orange[100]!,
      textColor: context != null
          ? Theme.of(context).colorScheme.onTertiaryContainer
          : Colors.orange[900]!,
      duration: duration,
      action: action,
    );
  }

  /// 内部方法：显示 SnackBar
  static void _showSnackBar(
    BuildContext? context,
    String message, {
    required Color backgroundColor,
    required Color textColor,
    required Duration duration,
    SnackBarAction? action,
  }) {
    final scaffoldMessenger = context != null
        ? ScaffoldMessenger.of(context)
        : globalScaffoldMessengerKey.currentState;

    if (scaffoldMessenger == null) {
      // 如果无法获取ScaffoldMessenger，记录日志并退出
      appLogger.w('无法显示SnackBar：ScaffoldMessenger不可用');
      return;
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.all(16.0),
        content: Text(
          message,
          style: TextStyle(color: textColor),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
      ),
    );
  }
}
