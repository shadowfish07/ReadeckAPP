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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.api),
            title: const Text('API 配置'),
            subtitle: const Text('配置 Readeck 服务器连接'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              context.push(Routes.apiConfigSetting);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.smart_toy),
            title: const Text('AI 设置'),
            subtitle: const Text('配置 AI 服务、翻译和标签功能'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push(Routes.aiSetting);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('主题模式'),
            subtitle: Text(_getThemeModeText(viewModel.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showThemeModeDialog(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('导出日志'),
            subtitle: const Text('导出应用日志文件'),
            trailing: CommandBuilder<void, void>(
              command: viewModel.exportLogs,
              whileExecuting: (context, _, __) => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              onNullData: (context, _) => const Icon(Icons.chevron_right),
              onData: (context, _, __) => const Icon(Icons.chevron_right),
              onError: (context, error, _, __) =>
                  const Icon(Icons.error, color: Colors.red),
            ),
            onTap: () {
              viewModel.exportLogs.execute();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            subtitle: Consumer<AboutViewModel>(
              builder: (context, aboutViewModel, child) {
                if (aboutViewModel.updateInfo != null) {
                  return Text('发现新版本 ${aboutViewModel.updateInfo!.version}');
                }
                return const Text('应用信息和版本');
              },
            ),
            trailing: Consumer<AboutViewModel>(
              builder: (context, aboutViewModel, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (aboutViewModel.updateInfo != null) ...[
                      const Badge(),
                      const SizedBox(width: 8),
                    ],
                    const Icon(Icons.chevron_right),
                  ],
                );
              },
            ),
            onTap: () {
              context.push(Routes.about);
            },
          ),
          if (kDebugMode) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.dangerous),
              title: const Text('清空Sqlite数据'),
              subtitle: const Text('Dev only'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                viewModel.clearAllDataForDebug();
              },
            ),
          ],
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('浅色模式'),
            value: ThemeMode.light,
            groupValue: currentThemeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                onThemeChanged(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('深色模式'),
            value: ThemeMode.dark,
            groupValue: currentThemeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                onThemeChanged(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('跟随系统'),
            value: ThemeMode.system,
            groupValue: currentThemeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                onThemeChanged(value);
              }
            },
          ),
        ],
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
