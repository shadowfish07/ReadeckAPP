import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:go_router/go_router.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/routing/routes.dart';
import 'package:readeck_app/ui/settings/view_models/ai_settings_viewmodel.dart';
import 'package:readeck_app/ui/core/ui/snack_bar_helper.dart';
import 'package:readeck_app/ui/core/ui/settings_section.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key, required this.viewModel});

  final AiSettingsViewModel viewModel;

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  late final TextEditingController _apiKeyController;
  late ListenableSubscription _successSubscription;
  late ListenableSubscription _errorSubscription;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();

    // 监听ViewModel的变化，更新输入框
    widget.viewModel.addListener(_updateController);
    _updateController();

    // 监听保存命令的结果
    _successSubscription = widget.viewModel.saveApiKey.listen((result, _) {
      if (mounted) {
        // API key 保存成功，无需额外操作
        appLogger.d('API key 保存成功');
      }
    });

    // 监听保存命令的错误
    _errorSubscription = widget.viewModel.saveApiKey.errors
        .where((x) => x != null)
        .listen((error, _) {
      appLogger.e('保存 API 键错误: $error');
      if (mounted && error != null) {
        // 保存失败，显示错误提示
        SnackBarHelper.showError(
          context,
          '保存失败：${error.error.toString()}',
        );
      }
    });
  }

  void _updateController() {
    if (_apiKeyController.text != widget.viewModel.openRouterApiKey) {
      _apiKeyController.text = widget.viewModel.openRouterApiKey;
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_updateController);
    _apiKeyController.dispose();
    _successSubscription.cancel();
    _errorSubscription.cancel();
    super.dispose();
  }

  void _saveApiKey() {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey != widget.viewModel.openRouterApiKey) {
      widget.viewModel.saveApiKey.execute(apiKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 设置'),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final hasApiKey = widget.viewModel.openRouterApiKey.isNotEmpty;
          final selectedModel = widget.viewModel.selectedModel;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // API 配置分组
              SettingsSection(
                title: 'API 配置',
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OpenRouter API 密钥',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _apiKeyController,
                          decoration: InputDecoration(
                            hintText: hasApiKey ? '已配置 API 密钥' : '请输入您的 API 密钥',
                            prefixIcon: Icon(
                              Icons.key,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            suffixIcon: hasApiKey
                                ? Icon(
                                    Icons.check_circle,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  )
                                : null,
                            border: const OutlineInputBorder(),
                          ),
                          obscureText: true,
                          onChanged: widget.viewModel.textChangedCommand.call,
                          onSubmitted: (_) => _saveApiKey(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // AI 功能分组
              SettingsSection(
                title: 'AI 功能',
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(
                      Icons.smart_toy,
                      color: hasApiKey
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.5),
                      size: 24,
                    ),
                    title: Text(
                      '模型选择',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: hasApiKey
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                          ),
                    ),
                    subtitle: Text(
                      hasApiKey
                          ? widget.viewModel.selectedModelName.isNotEmpty
                              ? widget.viewModel.selectedModelName
                              : selectedModel?.name ?? '未选择模型'
                          : '需要先配置 API 密钥',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: hasApiKey
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.5),
                          ),
                    ),
                    onTap: hasApiKey
                        ? () async {
                            await context.push(Routes.modelSelection);
                            widget.viewModel.loadSelectedModel.execute();
                          }
                        : null,
                  ),
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(
                      Icons.translate,
                      color: hasApiKey
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.5),
                      size: 24,
                    ),
                    title: Text(
                      '翻译设置',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: hasApiKey
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                          ),
                    ),
                    subtitle: Text(
                      hasApiKey ? '配置阅读翻译功能' : '需要先配置 API 密钥',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: hasApiKey
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.5),
                          ),
                    ),
                    onTap: hasApiKey
                        ? () {
                            context.push(Routes.translationSetting);
                          }
                        : null,
                  ),
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(
                      Icons.label,
                      color: hasApiKey
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.5),
                      size: 24,
                    ),
                    title: Text(
                      'AI 标签设置',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: hasApiKey
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                          ),
                    ),
                    subtitle: Text(
                      hasApiKey ? '配置 AI 标签推荐功能' : '需要先配置 API 密钥',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: hasApiKey
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.5),
                          ),
                    ),
                    onTap: hasApiKey
                        ? () {
                            context.push(Routes.aiTagSetting);
                          }
                        : null,
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
