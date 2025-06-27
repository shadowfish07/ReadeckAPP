import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/ui/settings/view_models/ai_settings_viewmodel.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key, required this.viewModel});

  final AiSettingsViewModel viewModel;

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  late final TextEditingController _apiKeyController;
  final _formKey = GlobalKey<FormState>();
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
        // 保存成功，返回上一页
        Navigator.of(context).pop();
      }
    });

    // 监听保存命令的错误
    _errorSubscription = widget.viewModel.saveApiKey.errors
        .where((x) => x != null)
        .listen((error, _) {
      appLogger.e('保存 API 键错误: $error');
      if (mounted && error != null) {
        // 保存失败，显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败：${error.error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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
    if (_formKey.currentState?.validate() ?? false) {
      widget.viewModel.saveApiKey.execute(_apiKeyController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 设置'),
        actions: [
          CommandBuilder<String, void>(
              command: widget.viewModel.saveApiKey,
              whileExecuting: (context, _, __) => const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              onNullData: (context, _) => TextButton(
                    onPressed: _saveApiKey,
                    child: const Text('保存'),
                  ),
              onData: (context, _, __) => TextButton(
                    onPressed: _saveApiKey,
                    child: const Text('保存'),
                  ),
              onError: (context, error, _, __) => TextButton(
                    onPressed: _saveApiKey,
                    child: const Text('保存'),
                  )),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OpenRouter API 配置',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '请输入您的 OpenRouter API 密钥以启用 AI 功能。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API 密钥',
                  hintText: '请输入 OpenRouter API 密钥',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入 API 密钥';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _saveApiKey(),
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
                        'OpenRouter 是一个统一的 AI 模型 API 平台，支持多种大语言模型。您可以在 openrouter.ai 注册账户并获取 API 密钥。',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• 支持 GPT、Claude、Llama 等多种模型\n• 按使用量付费，价格透明\n• 提供详细的使用统计',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
