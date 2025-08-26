import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:go_router/go_router.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/routing/routes.dart';
import 'package:readeck_app/ui/settings/view_models/translation_settings_viewmodel.dart';
import 'package:readeck_app/ui/core/ui/snack_bar_helper.dart';
import 'package:readeck_app/ui/core/ui/settings_section.dart';
import 'package:readeck_app/ui/core/ui/settings_navigation_tile.dart';

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

  void _showLanguageSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Column(
              children: [
                // 拖拽指示器
                Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 标题
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '选择翻译目标语种',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // 语种列表
                Expanded(
                  child: RadioGroup<String>(
                    groupValue: widget.viewModel.translationTargetLanguage,
                    onChanged: (String? value) {
                      if (value != null) {
                        widget.viewModel.saveTranslationTargetLanguage
                            .execute(value);
                        Navigator.of(context).pop();
                      }
                    },
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: TranslationSettingsViewModel
                          .supportedLanguages.length,
                      itemBuilder: (context, index) {
                        final language = TranslationSettingsViewModel
                            .supportedLanguages[index];
                        final isSelected =
                            widget.viewModel.translationTargetLanguage ==
                                language;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
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
                              widget.viewModel.saveTranslationTargetLanguage
                                  .execute(language);
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
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
            padding: const EdgeInsets.all(16),
            children: [
              // 基础设置分组
              SettingsSection(
                title: '基础设置',
                children: [
                  SettingsNavigationTile(
                    icon: Icons.translate,
                    title: '翻译服务提供方',
                    subtitle: widget.viewModel.translationProvider,
                    onTap: () {
                      SnackBarHelper.showInfo(
                        context,
                        '目前只支持 AI 翻译服务',
                      );
                    },
                  ),
                  SettingsNavigationTile(
                    icon: Icons.language,
                    title: '翻译目标语种',
                    subtitle: widget.viewModel.translationTargetLanguage,
                    onTap: _showLanguageSelectionBottomSheet,
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
                    subtitle: widget.viewModel.translationModelName.isNotEmpty
                        ? widget.viewModel.translationModelName
                        : '使用全局模型',
                    onTap: () {
                      context.push(
                          '${Routes.modelSelection}?scenario=translation');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 性能优化分组
              SettingsSection(
                title: '性能优化',
                children: [
                  SwitchListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    secondary: Icon(
                      Icons.cached,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    title: Text(
                      '启用翻译缓存',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    subtitle: Text(
                      '缓存翻译结果以提高性能',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    value: widget.viewModel.translationCacheEnabled,
                    onChanged: (bool value) {
                      widget.viewModel.saveTranslationCacheEnabled
                          .execute(value);
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
