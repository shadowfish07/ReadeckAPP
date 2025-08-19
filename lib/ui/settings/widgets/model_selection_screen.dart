import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/domain/models/openrouter_model/openrouter_model.dart';
import 'package:readeck_app/ui/core/ui/loading.dart';
import 'package:readeck_app/ui/settings/view_models/model_selection_viewmodel.dart';

class ModelSelectionScreen extends StatelessWidget {
  const ModelSelectionScreen({
    super.key,
    required this.viewModel,
  });

  final ModelSelectionViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () {
        return viewModel.loadModels.executeWithFuture(null);
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CommandBuilder<void, void>(
          command: viewModel.loadModels,
          whileExecuting: (context, _, __) {
            // 如果已有数据，显示数据内容而不是全屏Loading
            if (viewModel.availableModels.isNotEmpty) {
              return _buildModelsList();
            }
            // 无数据时显示Loading
            return const Center(child: Loading(text: '正在加载模型列表...'));
          },
          onError: (context, error, _, __) => Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '加载模型失败',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => viewModel.loadModels.execute(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          onData: (context, _, __) => _buildModelsList(),
        ),
      ),
    );
  }

  Widget _buildModelsList() {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        if (viewModel.availableModels.isEmpty) {
          return Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无可用模型',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '请先配置 API 密钥并点击刷新按钮加载模型列表',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => viewModel.loadModels.execute(),
                      icon: const Icon(Icons.download),
                      label: const Text('加载模型列表'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: viewModel.availableModels.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final model = viewModel.availableModels[index];
            final isSelected = viewModel.selectedModel?.id == model.id;

            return ModelCard(
              model: model,
              isSelected: isSelected,
              onTap: () {
                viewModel.selectModel(model);
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }
}

class ModelCard extends StatefulWidget {
  const ModelCard({
    super.key,
    required this.model,
    required this.isSelected,
    required this.onTap,
  });

  final OpenRouterModel model;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<ModelCard> createState() => _ModelCardState();
}

class _ModelCardState extends State<ModelCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: widget.isSelected ? 4 : 1,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.model.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: widget.isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: widget.isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                    ),
                  ),
                  if (widget.isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.model.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: _isExpanded ? null : 3,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                  ),
                  if (widget.model.description.length > 100)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _isExpanded ? '收起' : '展开',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    context,
                    Icons.input,
                    '输入',
                    _formatPrice(widget.model.pricing?.prompt),
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    context,
                    Icons.output,
                    '输出',
                    _formatPrice(widget.model.pricing?.completion),
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    context,
                    Icons.text_fields,
                    '上下文',
                    _formatContextLength(widget.model.contextLength),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  String _formatPrice(String? price) {
    if (price == null || price == '0') {
      return '免费';
    }

    // 将价格从字符串转换为数字（假设原始价格是每token的价格）
    final priceValue = double.tryParse(price) ?? 0.0;

    if (priceValue == 0.0) {
      return '免费';
    }

    // 转换为每百万token的价格
    final pricePerMillion = priceValue * 1000000;

    // 格式化显示
    if (pricePerMillion >= 1000) {
      return '\$${pricePerMillion.toStringAsFixed(0)}/ 1M tokens';
    } else if (pricePerMillion >= 100) {
      return '\$${pricePerMillion.toStringAsFixed(1)}/ 1M tokens';
    } else {
      return '\$${pricePerMillion.toStringAsFixed(2)}/ 1M tokens';
    }
  }

  String _formatContextLength(int length) {
    if (length >= 1000000) {
      return '${(length / 1000000).toStringAsFixed(1)}M';
    } else if (length >= 1000) {
      return '${(length / 1000).toStringAsFixed(0)}K';
    } else {
      return length.toString();
    }
  }
}
