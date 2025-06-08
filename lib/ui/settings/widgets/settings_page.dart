import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:readeck_app/routing/routes.dart';
import 'package:readeck_app/ui/settings/view_models/settings_viewmodel.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.viewModel});

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
              context.go(Routes.apiConfigSetting);
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
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            subtitle: const Text('应用信息和版本'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.go(Routes.about);
            },
          ),
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
