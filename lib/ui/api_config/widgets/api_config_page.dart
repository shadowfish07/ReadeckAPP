import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:readeck_app/routing/routes.dart';
import 'package:readeck_app/ui/api_config/view_models/api_config_viewmodel.dart';
import 'package:readeck_app/ui/core/ui/snack_bar_helper.dart';

class ApiConfigPage extends StatefulWidget {
  const ApiConfigPage({super.key, required this.viewModel});

  final ApiConfigViewModel viewModel;

  @override
  State<ApiConfigPage> createState() => _ApiConfigPageState();
}

class _ApiConfigPageState extends State<ApiConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _baseHostController = TextEditingController();
  final _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() async {
    final result = await widget.viewModel.load();
    if (result.isSuccess()) {
      final (host, token) = result.getOrNull()!;
      _baseHostController.text = host;
      _tokenController.text = token;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _baseHostController,
              decoration: const InputDecoration(
                labelText: '服务器地址',
                hintText: 'https://your-readeck-server.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入服务器地址';
                }
                if (!value.startsWith('http://') &&
                    !value.startsWith('https://')) {
                  return '请输入有效的URL（以http://或https://开头）';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'API 令牌',
                hintText: '在Readeck设置中生成的API令牌',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入API令牌';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                try {
                  await widget.viewModel.save.executeWithFuture(
                      (_baseHostController.text, _tokenController.text));
                  if (context.mounted) {
                    context.go(Routes.dailyRead);
                  }
                } catch (e) {
                  // 弹出错误提示
                  if (context.mounted) {
                    SnackBarHelper.showError(
                      context,
                      "保存配置失败：$e",
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '保存配置',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                        const Text(
                          '使用说明',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. 在Readeck网页版中，进入个人资料 > 令牌页面\n'
                      '2. 创建一个新的API令牌\n'
                      '3. 将服务器地址和令牌填入上方表单\n'
                      '4. 点击保存配置',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
