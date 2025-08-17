import 'package:flutter/material.dart';
import 'package:readeck_app/ui/settings/view_models/about_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key, required this.viewModel});

  final AboutViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (BuildContext context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              // 应用图标
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.book,
                          size: 60,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 应用名称
              Text(
                'Readeck APP',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              // 版本信息
              Text(
                '版本 ${viewModel.version}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              // 更新信息卡片
              if (viewModel.updateInfo != null)
                Column(
                  children: [
                    const SizedBox(height: 32),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '新版本可用: ${viewModel.updateInfo!.version}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                const Badge(),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // 下载进度条
                            if (viewModel.isDownloading)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '下载中... ${(viewModel.downloadProgress * 100).toStringAsFixed(1)}%',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: viewModel.downloadProgress,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            // 安装状态
                            if (viewModel.isInstalling)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '正在安装...',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            // 操作按钮
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _launchUrl(
                                        viewModel.updateInfo!.downloadUrl);
                                  },
                                  child: const Text('手动下载'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.tonal(
                                  onPressed: (viewModel.isDownloading ||
                                          viewModel.isInstalling)
                                      ? null
                                      : () {
                                          _showUpdateDialog(context, viewModel);
                                        },
                                  child: const Text('立即更新'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              // 应用描述
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '应用简介',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Readeck APP 是一个基于 Material Design 2 设计的移动端应用，用于连接和管理 Readeck 书签服务。通过这个应用，您可以方便地浏览、管理和阅读您保存的书签内容。',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 功能特性
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '主要功能',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                        context,
                        Icons.bookmark,
                        '书签管理',
                        '浏览和管理您的书签收藏',
                      ),
                      _buildFeatureItem(
                        context,
                        Icons.shuffle,
                        '随机推荐',
                        '发现您可能感兴趣的未读内容',
                      ),
                      _buildFeatureItem(
                        context,
                        Icons.settings,
                        'API 配置',
                        '灵活配置您的 Readeck 服务器连接',
                      ),
                      _buildFeatureItem(
                        context,
                        Icons.palette,
                        'Material Design',
                        '遵循 Material Design 2 设计规范',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 链接和联系方式
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '相关链接',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.web),
                        title: const Text('Readeck 官网'),
                        subtitle: const Text('了解更多关于 Readeck'),
                        trailing: const Icon(Icons.open_in_new),
                        contentPadding: EdgeInsets.zero,
                        onTap: () => _launchUrl('https://readeck.org/en/'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.bug_report),
                        title: const Text('反馈问题'),
                        subtitle: const Text('报告 Bug 或提出建议'),
                        trailing: const Icon(Icons.open_in_new),
                        contentPadding: EdgeInsets.zero,
                        onTap: () => _showFeedbackDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 版权信息
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '版权信息',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '© 2024 Readeck APP. All rights reserved.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '本应用基于 MIT 许可证开源',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // 如果无法启动URL，尝试使用默认模式
        await launchUrl(uri);
      }
    } catch (e) {
      // 如果启动失败，可以在这里添加错误提示
      debugPrint('无法打开链接: $url, 错误: $e');
    }
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('反馈问题'),
          content: const Text(
            '如果您在使用过程中遇到问题或有改进建议，请通过以下方式联系我们：\n\n'
            '• 发送邮件至开发者\n'
            '• 在项目仓库提交 Issue\n'
            '• 通过应用商店评价反馈',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateDialog(BuildContext context, AboutViewModel aboutViewModel) {
    if (aboutViewModel.updateInfo == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('应用更新'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('发现新版本: ${aboutViewModel.updateInfo!.version}'),
              const SizedBox(height: 16),
              const Text('更新功能：'),
              const SizedBox(height: 8),
              const Text('• 自动下载更新文件'),
              const Text('• 自动安装（需要授权）'),
              const Text('• 实时显示下载进度'),
              const SizedBox(height: 16),
              const Text(
                '注意：如果是首次自动安装，可能需要授权"安装未知应用"权限。',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 执行下载并安装
                aboutViewModel.downloadAndInstallUpdateCommand
                    .execute(aboutViewModel.updateInfo!);
              },
              child: const Text('立即更新'),
            ),
          ],
        );
      },
    );
  }
}
