import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:readeck_app/routing/routes.dart';
import 'package:readeck_app/ui/settings/view_models/settings_viewmodel.dart';
import 'package:readeck_app/ui/settings/view_models/about_viewmodel.dart';
import 'package:flutter_command/flutter_command.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.viewModel});

  final SettingsViewModel viewModel;

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  void _showThemeModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) {
              return ChooseThemeDialog(
                  currentThemeMode: viewModel.themeMode,
                  onThemeChanged: (ThemeMode mode) {
                    viewModel.setThemeMode.execute(mode);
                    context.pop();
                  });
            });
      },
    );
  }

  /// 构建分组标题
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => ListView(
        children: [
          // 连接设置分组
          _buildSectionHeader(context, '连接设置'),
          ListTile(
            leading: Icon(
              Icons.api,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            title: const Text('API 配置'),
            subtitle: const Text('配置 Readeck 服务器连接'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              context.push(Routes.apiConfigSetting);
            },
          ),

          // AI 功能分组
          _buildSectionHeader(context, 'AI 功能'),
          ListTile(
            leading: Icon(
              Icons.smart_toy,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            title: const Text('AI 设置'),
            subtitle: const Text('配置 AI 服务、翻译和标签功能'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push(Routes.aiSetting);
            },
          ),

          // 界面设置分组
          _buildSectionHeader(context, '界面设置'),
          ListTile(
            leading: Icon(
              Icons.palette,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            title: const Text('主题模式'),
            subtitle: const Text('选择应用的显示主题'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getThemeModeText(viewModel.themeMode),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              _showThemeModeDialog(context);
            },
          ),

          // 数据管理分组
          _buildSectionHeader(context, '数据管理'),
          ListTile(
            leading: Icon(
              Icons.file_download,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            title: const Text('导出日志'),
            subtitle: const Text('导出应用日志文件'),
            trailing: CommandBuilder<void, void>(
              command: viewModel.exportLogs,
              whileExecuting: (context, _, __) => const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right),
                ],
              ),
              onNullData: (context, _) => const Icon(Icons.chevron_right),
              onData: (context, _, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onError: (context, error, _, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error,
                    color: Theme.of(context).colorScheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            onTap: () {
              viewModel.exportLogs.execute();
            },
          ),
          if (kDebugMode)
            ListTile(
              leading: Icon(
                Icons.dangerous,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('清空数据库'),
              subtitle: const Text('仅开发模式可用'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                viewModel.clearAllDataForDebug();
              },
            ),

          // 应用信息分组
          _buildSectionHeader(context, '应用信息'),
          Consumer<AboutViewModel>(
            builder: (context, aboutViewModel, child) {
              final hasUpdate = aboutViewModel.updateInfo != null;
              return ListTile(
                leading: Icon(
                  Icons.info,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: const Text('关于'),
                subtitle: hasUpdate
                    ? Text('发现新版本 ${aboutViewModel.updateInfo!.version}')
                    : const Text('应用信息和版本'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasUpdate) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '更新',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onError,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () {
                  context.push(Routes.about);
                },
              );
            },
          ),

          // 底部间距
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class ChooseThemeDialog extends StatelessWidget {
  const ChooseThemeDialog({
    super.key,
    required this.currentThemeMode,
    required this.onThemeChanged,
  });

  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择主题模式'),
      content: RadioGroup<ThemeMode>(
        groupValue: currentThemeMode,
        onChanged: (ThemeMode? value) {
          if (value != null) {
            onThemeChanged(value);
          }
        },
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text('浅色模式'),
              value: ThemeMode.light,
            ),
            RadioListTile<ThemeMode>(
              title: Text('深色模式'),
              value: ThemeMode.dark,
            ),
            RadioListTile<ThemeMode>(
              title: Text('跟随系统'),
              value: ThemeMode.system,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
      ],
    );
  }
}
