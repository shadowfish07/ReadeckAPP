// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'openrouter_model.freezed.dart';
part 'openrouter_model.g.dart';

/// OpenRouter 模型架构信息
@freezed
abstract class ModelArchitecture with _$ModelArchitecture {
  const factory ModelArchitecture({
    /// 输入模态
    @JsonKey(name: 'input_modalities')
    @Default(<String>[])
    List<String> inputModalities,

    /// 输出模态
    @JsonKey(name: 'output_modalities')
    @Default(<String>[])
    List<String> outputModalities,

    /// 分词器类型
    @Default('') String tokenizer,
  }) = _ModelArchitecture;

  factory ModelArchitecture.fromJson(Map<String, Object?> json) =>
      _$ModelArchitectureFromJson(json);
}

/// OpenRouter 模型顶级提供商信息
@freezed
abstract class TopProvider with _$TopProvider {
  const factory TopProvider({
    /// 是否受到审核
    @JsonKey(name: 'is_moderated') @Default(false) bool isModerated,
  }) = _TopProvider;

  factory TopProvider.fromJson(Map<String, Object?> json) =>
      _$TopProviderFromJson(json);
}

/// OpenRouter 模型定价信息
@freezed
abstract class ModelPricing with _$ModelPricing {
  const factory ModelPricing({
    /// 提示价格
    @Default('0') String prompt,

    /// 完成价格
    @Default('0') String completion,

    /// 图片价格
    @Default('0') String image,

    /// 请求价格
    @Default('0') String request,

    /// 网络搜索价格
    @JsonKey(name: 'web_search') @Default('0') String webSearch,

    /// 内部推理价格
    @JsonKey(name: 'internal_reasoning') @Default('0') String internalReasoning,
  }) = _ModelPricing;

  factory ModelPricing.fromJson(Map<String, Object?> json) =>
      _$ModelPricingFromJson(json);
}

/// OpenRouter 模型信息
@freezed
abstract class OpenRouterModel with _$OpenRouterModel {
  const factory OpenRouterModel({
    /// 模型ID
    required String id,

    /// 模型名称
    required String name,

    /// 创建时间戳
    @Default(0) int created,

    /// 模型描述
    @Default('') String description,

    /// 模型架构
    ModelArchitecture? architecture,

    /// 顶级提供商
    @JsonKey(name: 'top_provider') TopProvider? topProvider,

    /// 定价信息
    ModelPricing? pricing,

    /// 规范化标识符
    @JsonKey(name: 'canonical_slug') @Default('') String canonicalSlug,

    /// 上下文长度
    @JsonKey(name: 'context_length') @Default(0) int contextLength,

    /// Hugging Face ID
    @JsonKey(name: 'hugging_face_id') @Default('') String huggingFaceId,

    /// 每请求限制
    @JsonKey(name: 'per_request_limits')
    @Default(<String, dynamic>{})
    Map<String, dynamic> perRequestLimits,

    /// 支持的参数
    @JsonKey(name: 'supported_parameters')
    @Default(<String>[])
    List<String> supportedParameters,
  }) = _OpenRouterModel;

  factory OpenRouterModel.fromJson(Map<String, Object?> json) =>
      _$OpenRouterModelFromJson(json);
}
