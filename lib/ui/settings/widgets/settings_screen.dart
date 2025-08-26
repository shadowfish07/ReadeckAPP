import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:readeck_app/routing/routes.dart';
import 'package:readeck_app/ui/settings/view_models/settings_viewmodel.dart';
import 'package:readeck_app/ui/settings/view_models/about_viewmodel.dart';
import 'package:readeck_app/ui/core/ui/settings_section.dart';
import 'package:readeck_app/ui/core/ui/settings_navigation_tile.dart';
import 'package:readeck_app/ui/core/ui/filter_chip_selector.dart';
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

  /// 构建主题模式设置项
  Widget _buildThemeModeTile(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        Icons.palette_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 24,
      ),
      title: Text(
        '主题模式',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择应用的显示主题',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          FilterChipSelector<ThemeMode>(
            options: ThemeMode.values,
            selectedValue: viewModel.themeMode,
            onSelectionChanged: (mode) => viewModel.setThemeMode.execute(mode),
            labelBuilder: _getThemeModeText,
          ),
        ],
      ),
    );
  }

  /// 构建导出日志项
  Widget _buildExportLogsTile(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        Icons.file_download_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 24,
      ),
      title: Text(
        '导出日志',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Text(
        '导出应用日志文件',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      trailing: CommandBuilder<void, void>(
        command: viewModel.exportLogs,
        whileExecuting: (context, _, __) => SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        onData: (context, _, __) => Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        onError: (context, error, _, __) => Icon(
          Icons.error,
          color: Theme.of(context).colorScheme.error,
          size: 20,
        ),
      ),
      onTap: () {
        viewModel.exportLogs.execute();
      },
    );
  }

  /// 构建调试项
  Widget _buildDebugTile(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        Icons.warning_amber_outlined,
        color: Theme.of(context).colorScheme.error,
        size: 24,
      ),
      title: Text(
        '清空数据库',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.error,
            ),
      ),
      subtitle: Text(
        '仅开发模式可用',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      onTap: () {
        viewModel.clearAllDataForDebug();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 连接设置分组
          SettingsSection(
            title: '连接设置',
            children: [
              SettingsNavigationTile(
                icon: Icons.api,
                title: 'API 配置',
                subtitle: '配置 Readeck 服务器连接',
                onTap: () => context.push(Routes.apiConfigSetting),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // AI 功能分组
          SettingsSection(
            title: 'AI 功能',
            children: [
              SettingsNavigationTile(
                icon: Icons.smart_toy,
                title: 'AI 设置',
                subtitle: '配置 AI 服务、翻译和标签功能',
                onTap: () => context.push(Routes.aiSetting),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 界面设置分组
          SettingsSection(
            title: '界面设置',
            children: [
              _buildThemeModeTile(context),
            ],
          ),
          const SizedBox(height: 24),

          // 数据管理分组
          SettingsSection(
            title: '数据管理',
            children: [
              _buildExportLogsTile(context),
              if (kDebugMode) _buildDebugTile(context),
            ],
          ),
          const SizedBox(height: 24),

          // 应用信息分组
          SettingsSection(
            title: '应用信息',
            children: [
              Consumer<AboutViewModel>(
                builder: (context, aboutViewModel, child) {
                  final hasUpdate = aboutViewModel.updateInfo != null;
                  return SettingsNavigationTile(
                    icon: Icons.info_outline,
                    title: '关于',
                    subtitle: hasUpdate
                        ? '发现新版本 ${aboutViewModel.updateInfo!.version}'
                        : '应用信息和版本',
                    trailing: hasUpdate
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '更新',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : null,
                    onTap: () => context.push(Routes.about),
                  );
                },
              ),
            ],
          ),
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

  IconData _getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '选择主题模式',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ThemeMode.values.map((mode) {
          final isSelected = currentThemeMode == mode;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              leading: Icon(
                _getThemeModeIcon(mode),
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
              title: Text(
                _getThemeModeText(mode),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 20,
                    )
                  : null,
              onTap: () => onThemeChanged(mode),
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: const Text('取消'),
        ),
      ],
    );
  }
}
