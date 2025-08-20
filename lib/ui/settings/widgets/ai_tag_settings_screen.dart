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
          title: const Text('选择AI标签目标语言'),
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
                    ),
                    onTap: () {
                      widget.viewModel.saveAiTagTargetLanguage
                          .execute(language);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
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

  /// 构建分组标题
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
      ),
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
            children: [
              // 页面描述
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '配置 AI 标签功能',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '设置 AI 标签推荐的目标语言和专用模型',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),

              // 基础设置分组
              _buildSectionHeader(context, '基础设置'),
              ListTile(
                leading: const Icon(Icons.translate),
                title: const Text('标签推荐语言'),
                subtitle: Text(widget.viewModel.aiTagTargetLanguage),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showLanguageSelectionDialog,
              ),

              // 模型配置分组
              _buildSectionHeader(context, '模型配置'),
              ListTile(
                leading: const Icon(Icons.smart_toy),
                title: const Text('专用模型'),
                subtitle: Text(widget.viewModel.aiTagModelName.isNotEmpty
                    ? widget.viewModel.aiTagModelName
                    : '使用全局模型'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('${Routes.modelSelection}?scenario=ai_tag');
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
