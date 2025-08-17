import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:go_router/go_router.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/routing/routes.dart';
import 'package:readeck_app/ui/settings/view_models/ai_settings_viewmodel.dart';
import 'package:readeck_app/ui/core/ui/snack_bar_helper.dart';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '配置 OpenRouter API 密钥和选择 AI 模型以启用 AI 能力',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // API 密钥配置卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.key,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'API 密钥',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'OpenRouter API 密钥',
                      hintText: '请输入您的 API 密钥',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    onChanged: widget.viewModel.textChangedCommand.call,
                    onFieldSubmitted: (_) => _saveApiKey(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 模型选择配置卡片
          Card(
            child: ListenableBuilder(
              listenable: widget.viewModel,
              builder: (context, child) {
                final selectedModel = widget.viewModel.selectedModel;
                final hasApiKey = widget.viewModel.openRouterApiKey.isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.smart_toy,
                            color: hasApiKey
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI 模型',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: hasApiKey
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          selectedModel?.name ?? '未选择模型',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () async {
                          await context.push(Routes.modelSelection);
                          // 从模型选择页面返回后，重新加载选中的模型
                          widget.viewModel.loadSelectedModel.execute();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 翻译设置配置卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.translate,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '翻译设置',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('翻译服务配置'),
                    subtitle: const Text('配置翻译目标语言和缓存设置'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      context.push(Routes.translationSetting);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // AI标签设置配置卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.label,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI 标签设置',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('标签推荐配置'),
                    subtitle: const Text('配置AI标签推荐的目标语言'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      context.push(Routes.aiTagSetting);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Card(
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
                        '关于 OpenRouter',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'OpenRouter 是一个统一的 AI 模型 API 平台，支持多种大语言模型。您可以在 openrouter.ai 注册账户并获取 API 密钥。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 支持 GPT、Claude、Llama 等多种模型\n• 按使用量付费，价格透明\n• 提供详细的使用统计',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
