import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 庆祝界面覆盖层组件
/// 用于显示完成今日阅读任务后的庆祝动画和界面
class CelebrationOverlay extends StatelessWidget {
  final VoidCallback onRefreshNewContent;

  const CelebrationOverlay({
    super.key,
    required this.onRefreshNewContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return // 庆祝内容
        Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('yyyy年MM月dd日').format(DateTime.now()),
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '🎉 恭喜完成今日阅读！',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '您已经完成了今天的所有阅读任务\n坚持阅读，收获知识！',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            // 刷新按钮
            ElevatedButton.icon(
              onPressed: onRefreshNewContent,
              icon: const Icon(Icons.refresh),
              label: const Text('再来一组'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
