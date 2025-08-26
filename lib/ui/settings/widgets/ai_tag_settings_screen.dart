import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:go_router/go_router.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/routing/routes.dart';
import 'package:readeck_app/ui/settings/view_models/ai_tag_settings_viewmodel.dart';
import 'package:readeck_app/ui/core/ui/snack_bar_helper.dart';
import 'package:readeck_app/ui/core/ui/settings_section.dart';
import 'package:readeck_app/ui/core/ui/settings_navigation_tile.dart';

class AiTagSettingsScreen extends StatefulWidget {
  const AiTagSettingsScreen({super.key, required this.viewModel});

  final AiTagSettingsViewModel viewModel;

  @override
  State<AiTagSettingsScreen> createState() => _AiTagSettingsScreenState();
}

class _AiTagSettingsScreenState extends State<AiTagSettingsScreen> {
  late ListenableSubscription _languageSuccessSubscription;
  late ListenableSubscription _languageErrorSubscription;

  @override
  void initState() {
    super.initState();

    _languageSuccessSubscription =
        widget.viewModel.saveAiTagTargetLanguage.listen((result, _) {
      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          'AI标签目标语言保存成功',
        );
      }
    });

    _languageErrorSubscription = widget.viewModel.saveAiTagTargetLanguage.errors
        .where((x) => x != null)
        .listen((error, _) {
      appLogger.e('保存AI标签目标语言错误: $error');
      if (mounted && error != null) {
        SnackBarHelper.showError(
          context,
          '保存失败：${error.error.toString()}',
        );
      }
    });
  }

  @override
  void dispose() {
    _languageSuccessSubscription.cancel();
    _languageErrorSubscription.cancel();
    super.dispose();
  }

  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '选择AI标签目标语言',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: RadioGroup<String>(
              groupValue: widget.viewModel.aiTagTargetLanguage,
              onChanged: (String? value) {
                if (value != null) {
                  widget.viewModel.saveAiTagTargetLanguage.execute(value);
                  Navigator.of(context).pop();
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    AiTagSettingsViewModel.supportedLanguages.map((language) {
                  final isSelected =
                      widget.viewModel.aiTagTargetLanguage == language;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      leading: Radio<String>(
                        value: language,
                      ),
                      title: Text(
                        language,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        widget.viewModel.saveAiTagTargetLanguage
                            .execute(language);
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 标签设置'),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 基础设置分组
              SettingsSection(
                title: '基础设置',
                children: [
                  SettingsNavigationTile(
                    icon: Icons.translate,
                    title: '标签推荐语言',
                    subtitle: widget.viewModel.aiTagTargetLanguage,
                    onTap: _showLanguageSelectionDialog,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 模型配置分组
              SettingsSection(
                title: '模型配置',
                children: [
                  SettingsNavigationTile(
                    icon: Icons.smart_toy,
                    title: '专用模型',
                    subtitle: widget.viewModel.aiTagModelName.isNotEmpty
                        ? widget.viewModel.aiTagModelName
                        : '使用全局模型',
                    onTap: () {
                      context.push('${Routes.modelSelection}?scenario=ai_tag');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
