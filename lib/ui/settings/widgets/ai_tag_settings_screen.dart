import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:go_router/go_router.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/routing/routes.dart';
import 'package:readeck_app/ui/settings/view_models/ai_tag_settings_viewmodel.dart';
import 'package:readeck_app/ui/core/ui/snack_bar_helper.dart';

class AiTagSettingsScreen extends StatefulWidget {
  const AiTagSettingsScreen({super.key, required this.viewModel});

  final AiTagSettingsViewModel viewModel;

  @override
  State<AiTagSettingsScreen> createState() => _AiTagSettingsScreenState();
}

class _AiTagSettingsScreenState extends State<AiTagSettingsScreen> {
  late ListenableSubscription _languageSuccessSubscription;
  late ListenableSubscription _languageErrorSubscription;
  late ListenableSubscription _modelSuccessSubscription;
  late ListenableSubscription _modelErrorSubscription;

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

    _modelSuccessSubscription =
        widget.viewModel.saveAiTagModel.listen((result, _) {
      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          'AI标签模型保存成功',
        );
      }
    });

    _modelErrorSubscription = widget.viewModel.saveAiTagModel.errors
        .where((x) => x != null)
        .listen((error, _) {
      appLogger.e('保存AI标签模型错误: $error');
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
    _modelSuccessSubscription.cancel();
    _modelErrorSubscription.cancel();
    super.dispose();
  }

  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择AI标签目标语言'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: AiTagSettingsViewModel.supportedLanguages.length,
              itemBuilder: (context, index) {
                final language =
                    AiTagSettingsViewModel.supportedLanguages[index];
                return ListTile(
                  title: Text(language),
                  leading: Radio<String>(
                    value: language,
                    groupValue: widget.viewModel.aiTagTargetLanguage,
                    onChanged: (String? value) {
                      if (value != null) {
                        widget.viewModel.saveAiTagTargetLanguage.execute(value);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  onTap: () {
                    widget.viewModel.saveAiTagTargetLanguage.execute(language);
                    Navigator.of(context).pop();
                  },
                );
              },
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) => ListView(
        children: [
          const SizedBox(height: 16),

          // AI标签目标语言设置卡片
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.language,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '标签目标语言',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.translate),
                      title: const Text('AI标签推荐语言'),
                      subtitle: Text(widget.viewModel.aiTagTargetLanguage),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showLanguageSelectionDialog,
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.smart_toy),
                      title: const Text('专用模型'),
                      subtitle: Text(
                          widget.viewModel.selectedAiTagModel?.name ??
                              '使用全局模型'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context
                            .push('${Routes.modelSelection}?scenario=ai_tag');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 说明信息卡片
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '关于 AI 标签功能',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'AI 标签功能会根据网页内容智能推荐合适的标签，帮助您更好地组织和管理书签。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 支持多种语言的标签推荐\n• 基于网页内容智能分析\n• 优先使用已有标签保持一致性\n• 需要配置 OpenRouter API 才能使用',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
