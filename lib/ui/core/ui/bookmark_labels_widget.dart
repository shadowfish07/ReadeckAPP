import 'package:flutter/material.dart';

/// 书签标签展示组件
class BookmarkLabelsWidget extends StatelessWidget {
  const BookmarkLabelsWidget({
    super.key,
    required this.labels,
    this.spacing = 8,
    this.runSpacing = 4,
    this.isOnDarkBackground = false,
  });

  final List<String> labels;
  final double spacing;
  final double runSpacing;

  /// 是否在深色背景上显示（如已归档的卡片）
  final bool isOnDarkBackground;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: labels.map((label) {
        final colorScheme = Theme.of(context).colorScheme;

        // 根据背景选择合适的颜色方案
        final backgroundColor = isOnDarkBackground
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerHighest;

        final textColor = isOnDarkBackground
            ? colorScheme.onSurface
            : colorScheme.onSurfaceVariant;

        return Chip(
          label: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textColor,
                ),
          ),
          backgroundColor: backgroundColor,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}
