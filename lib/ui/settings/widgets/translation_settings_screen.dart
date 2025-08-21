import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:go_router/go_router.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/routing/routes.dart';
import 'package:readeck_app/ui/settings/view_models/translation_settings_viewmodel.dart';
import 'package:readeck_app/ui/core/ui/snack_bar_helper.dart';

class TranslationSettingsScreen extends StatefulWidget {
  const TranslationSettingsScreen({super.key, required this.viewModel});

  final TranslationSettingsViewModel viewModel;

  @override
  State<TranslationSettingsScreen> createState() =>
      _TranslationSettingsScreenState();
}

class _TranslationSettingsScreenState extends State<TranslationSettingsScreen> {
  late ListenableSubscription _providerSuccessSubscription;
  late ListenableSubscription _providerErrorSubscription;
  late ListenableSubscription _languageSuccessSubscription;
  late ListenableSubscription _languageErrorSubscription;
  late ListenableSubscription _cacheSuccessSubscription;
  late ListenableSubscription _cacheErrorSubscription;

  @override
  void initState() {
    super.initState();

    // 监听保存翻译服务提供方命令的结果
    _providerSuccessSubscription =
        widget.viewModel.saveTranslationProvider.listen((result, _) {
      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          '翻译服务提供方保存成功',
        );
      }
    });

    _providerErrorSubscription = widget.viewModel.saveTranslationProvider.errors
        .where((x) => x != null)
        .listen((error, _) {
      appLogger.e('保存翻译服务提供方错误: $error');
      if (mounted && error != null) {
        SnackBarHelper.showError(
          context,
          '保存失败：${error.error.toString()}',
        );
      }
    });

    // 监听保存翻译目标语种命令的结果
    _languageSuccessSubscription =
        widget.viewModel.saveTranslationTargetLanguage.listen((result, _) {
      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          '翻译目标语种保存成功',
        );
      }
    });

    _languageErrorSubscription = widget
        .viewModel.saveTranslationTargetLanguage.errors
        .where((x) => x != null)
        .listen((error, _) {
      appLogger.e('保存翻译目标语种错误: $error');
      if (mounted && error != null) {
        SnackBarHelper.showError(
          context,
          '保存失败：${error.error.toString()}',
        );
      }
    });

    // 监听保存翻译缓存启用状态命令的结果
    _cacheSuccessSubscription =
        widget.viewModel.saveTranslationCacheEnabled.listen((result, _) {
      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          '翻译缓存设置保存成功',
        );
      }
    });

    _cacheErrorSubscription = widget
        .viewModel.saveTranslationCacheEnabled.errors
        .where((x) => x != null)
        .listen((error, _) {
      appLogger.e('保存翻译缓存设置错误: $error');
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
    _providerSuccessSubscription.cancel();
    _providerErrorSubscription.cancel();
    _languageSuccessSubscription.cancel();
    _languageErrorSubscription.cancel();
    _cacheSuccessSubscription.cancel();
    _cacheErrorSubscription.cancel();
    super.dispose();
  }

  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择翻译目标语种'),
          content: SizedBox(
            width: double.maxFinite,
            child: RadioGroup<String>(
              groupValue: widget.viewModel.translationTargetLanguage,
              onChanged: (String? value) {
                if (value != null) {
                  widget.viewModel.saveTranslationTargetLanguage.execute(value);
                  Navigator.of(context).pop();
                }
              },
              child: ListView.builder(
                shrinkWrap: true,
                itemCount:
                    TranslationSettingsViewModel.supportedLanguages.length,
                itemBuilder: (context, index) {
                  final language =
                      TranslationSettingsViewModel.supportedLanguages[index];
                  return ListTile(
                    title: Text(language),
                    leading: Radio<String>(
                      value: language,
                    ),
                    onTap: () {
                      widget.viewModel.saveTranslationTargetLanguage
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
        title: const Text('翻译设置'),
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
                      '配置翻译功能',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '设置翻译服务提供方、目标语种和专用模型',
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
                title: const Text('翻译服务提供方'),
                subtitle: Text(widget.viewModel.translationProvider),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  SnackBarHelper.showInfo(
                    context,
                    '目前只支持 AI 翻译服务',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('翻译目标语种'),
                subtitle: Text(widget.viewModel.translationTargetLanguage),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showLanguageSelectionDialog,
              ),

              // 模型配置分组
              _buildSectionHeader(context, '模型配置'),
              ListTile(
                leading: const Icon(Icons.smart_toy),
                title: const Text('专用模型'),
                subtitle: Text(widget.viewModel.translationModelName.isNotEmpty
                    ? widget.viewModel.translationModelName
                    : '使用全局模型'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('${Routes.modelSelection}?scenario=translation');
                },
              ),

              // 性能优化分组
              _buildSectionHeader(context, '性能优化'),
              SwitchListTile(
                secondary: const Icon(Icons.cached),
                title: const Text('启用翻译缓存'),
                subtitle: const Text('缓存翻译结果以提高性能'),
                value: widget.viewModel.translationCacheEnabled,
                onChanged: (bool value) {
                  widget.viewModel.saveTranslationCacheEnabled.execute(value);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
