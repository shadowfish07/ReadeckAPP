import 'package:flutter/material.dart';

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
    return // 庆祝内容
        Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 庆祝文字
            const Text(
              '🎉 恭喜完成今日阅读！',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '您已经完成了今天的所有阅读任务\n坚持阅读，收获知识！',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
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
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
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
