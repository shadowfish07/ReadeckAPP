import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

/// 通用错误页面组件
/// 用于显示资源不存在、已删除等错误状态
class ErrorPage extends StatelessWidget {
  /// 错误图标
  final IconData icon;

  /// 主要错误信息
  final String message;

  /// 详细错误描述
  final String? description;

  /// 返回按钮文本
  final String? buttonText;

  /// 自定义返回操作
  final VoidCallback? onBack;

  const ErrorPage({
    super.key,
    required this.icon,
    required this.message,
    this.description,
    this.buttonText,
    this.onBack,
  });

  /// 创建书签不存在错误页面
  factory ErrorPage.bookmarkNotFound({
    Key? key,
    VoidCallback? onBack,
  }) {
    return ErrorPage(
      key: key,
      icon: Icons.bookmark_remove_outlined,
      message: '书签不存在',
      description: '该书签可能已被删除或不存在',
      buttonText: '返回',
      onBack: onBack,
    );
  }

  /// 创建通用资源不存在错误页面
  factory ErrorPage.resourceNotFound({
    Key? key,
    required String title,
    required String resourceName,
    VoidCallback? onBack,
  }) {
    return ErrorPage(
      key: key,
      icon: Icons.error_outline,
      message: '$resourceName不存在',
      description: '该$resourceName可能已被删除或不存在',
      buttonText: '返回',
      onBack: onBack,
    );
  }

  factory ErrorPage.networkError({
    Key? key,
    String message = '网络开小差啦',
    String description = '请检查你的API凭据是否正确，确保Readeck服务正常运行',
    required VoidCallback onBack,
    required Exception? error,
  }) {
    Logger().w("网络错误: $error");

    return ErrorPage(
      key: key,
      icon: Icons.error_outline,
      message: message,
      description: description,
      buttonText: '重试',
      onBack: onBack,
    );
  }

  factory ErrorPage.unknownError({
    Key? key,
    String message = '未知错误',
    String description = '程序似乎出了问题，请联系开发者获取帮助: readeck@zqydev.me',
    String? buttonText,
    VoidCallback? onBack,
    required Exception? error,
  }) {
    Logger().e("未知错误: $error");

    return ErrorPage(
      key: key,
      icon: Icons.error_outline,
      message: message,
      description: description,
      buttonText: buttonText,
      onBack: onBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          if (buttonText != null) ...[
            FilledButton(
              onPressed: onBack ?? () => context.pop(),
              child: Text(buttonText!),
            ),
          ]
        ],
      ),
    );
  }
}
