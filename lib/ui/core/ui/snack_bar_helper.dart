import 'package:flutter/material.dart';

/// SnackBar 辅助类，提供符合 Material Design 3 规范的统一样式
class SnackBarHelper {
  /// 显示成功消息的 SnackBar
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.inverseSurface,
      textColor: Theme.of(context).colorScheme.onInverseSurface,
      duration: duration,
      action: action,
    );
  }

  /// 显示错误消息的 SnackBar
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 5),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      textColor: Theme.of(context).colorScheme.onErrorContainer,
      duration: duration,
      action: action,
    );
  }

  /// 显示信息消息的 SnackBar
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.inverseSurface,
      textColor: Theme.of(context).colorScheme.onInverseSurface,
      duration: duration,
      action: action,
    );
  }

  /// 显示警告消息的 SnackBar
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      textColor: Theme.of(context).colorScheme.onTertiaryContainer,
      duration: duration,
      action: action,
    );
  }

  /// 内部方法：显示 SnackBar
  static void _showSnackBar(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required Color textColor,
    required Duration duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        duration: duration,
        action: action?.copyWith(
          textColor: textColor,
        ),
      ),
    );
  }
}

/// SnackBarAction 扩展，用于复制样式
extension SnackBarActionCopyWith on SnackBarAction {
  SnackBarAction copyWith({
    Color? textColor,
  }) {
    return SnackBarAction(
      label: label,
      onPressed: onPressed,
      textColor: textColor ?? this.textColor,
      disabledTextColor: disabledTextColor,
    );
  }
}
