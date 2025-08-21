import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:readeck_app/ui/settings/view_models/about_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key, required this.viewModel});

  final AboutViewModel viewModel;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heroAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _heroAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (BuildContext context, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Hero Section with gradient background
                _buildHeroSection(context),

                // Content with animations
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _heroAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 32),

                          // Update Card (only shown when update is available)
                          if (widget.viewModel.updateInfo != null)
                            _buildUpdateCard(context),

                          const SizedBox(height: 24),

                          // Quick Actions
                          _buildQuickActions(context),

                          const SizedBox(height: 32),

                          // Features List
                          _buildFeaturesList(context),

                          const SizedBox(height: 24),

                          // Footer
                          _buildFooter(context),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.3),
            colorScheme.surface,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: ScaleTransition(
          scale: _heroAnimation,
          child: Column(
            children: [
              // App Icon with shadow and animation
              Hero(
                tag: 'app_icon',
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.bookmark_rounded,
                            size: 50,
                            color: colorScheme.onPrimary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // App Name
              Text(
                'Readeck',
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              // Version with modern styling
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'v${widget.viewModel.version}',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tagline
              Text(
                '收藏当下，稍后尽兴',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateCard(BuildContext context) {
    final updateInfo = widget.viewModel.updateInfo!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.system_update_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '新版本可用',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'v${updateInfo.version}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Badge(
                  backgroundColor: colorScheme.error,
                  textColor: colorScheme.onError,
                ),
              ],
            ),

            if (updateInfo.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '更新内容',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: MarkdownBody(
                  data: updateInfo.releaseNotes,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                  onTapLink: (text, href, title) {
                    if (href != null) {
                      _launchUrl(href);
                    }
                  },
                ),
              ),
            ],

            // Download/Install Progress
            if (widget.viewModel.isDownloading ||
                widget.viewModel.isInstalling) ...[
              const SizedBox(height: 16),
              if (widget.viewModel.isDownloading)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '下载中 ${(widget.viewModel.downloadProgress * 100).toStringAsFixed(1)}%',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: widget.viewModel.downloadProgress,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ],
                ),
              if (widget.viewModel.isInstalling)
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '正在安装...',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _launchUrl(updateInfo.htmlUrl),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('查看详情'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: (widget.viewModel.isDownloading ||
                          widget.viewModel.isInstalling)
                      ? null
                      : () {
                          widget.viewModel.downloadAndInstallUpdateCommand
                              .execute(updateInfo);
                        },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('立即更新'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildActionChip(
            context,
            icon: Icons.code_rounded,
            label: 'GitHub',
            onPressed: () =>
                _launchUrl('https://github.com/shadowfish07/ReadeckApp'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionChip(
            context,
            icon: Icons.web_rounded,
            label: 'Readeck',
            onPressed: () => _launchUrl('https://readeck.org/en/'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionChip(
            context,
            icon: Icons.feedback_rounded,
            label: '反馈',
            onPressed: () => _showFeedbackDialog(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActionChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      onPressed: onPressed,
      avatar: Icon(
        icon,
        size: 18,
        color: colorScheme.onSurfaceVariant,
      ),
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      backgroundColor: colorScheme.surfaceContainerLow,
      side: BorderSide(color: colorScheme.outlineVariant),
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    final features = [
      const _FeatureItem(
        icon: Icons.bookmark_rounded,
        title: '书签管理',
        description: '轻松管理和浏览您的收藏',
      ),
      const _FeatureItem(
        icon: Icons.shuffle_rounded,
        title: '随机发现',
        description: '探索意想不到的精彩内容',
      ),
      const _FeatureItem(
        icon: Icons.palette_rounded,
        title: 'Material You',
        description: '遵循 Material Design 3 设计',
      ),
      const _FeatureItem(
        icon: Icons.settings_rounded,
        title: '灵活配置',
        description: '个性化的使用体验',
      ),
    ];

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '主要特性',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            ...features.asMap().entries.map((entry) {
              final isLast = entry.key == features.length - 1;
              return _buildFeatureItem(entry.value, isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(_FeatureItem feature, bool isLast) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              feature.icon,
              size: 22,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.copyright_rounded,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            '© 2024 Readeck APP',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '基于 MIT 许可证开源',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
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
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('无法打开链接: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(
            Icons.feedback_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('问题反馈'),
          content: const Text(
            '感谢您使用 Readeck APP！如果您遇到问题或有改进建议，欢迎通过 GitHub 提交 Issue 或联系开发者。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchUrl('https://github.com/shadowfish07/ReadeckApp/issues');
              },
              child: const Text('去反馈'),
            ),
          ],
        );
      },
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
