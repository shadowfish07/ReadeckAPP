// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'openrouter_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ModelArchitecture _$ModelArchitectureFromJson(Map<String, dynamic> json) =>
    _ModelArchitecture(
      inputModalities: (json['input_modalities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      outputModalities: (json['output_modalities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      tokenizer: json['tokenizer'] as String,
    );

Map<String, dynamic> _$ModelArchitectureToJson(_ModelArchitecture instance) =>
    <String, dynamic>{
      'input_modalities': instance.inputModalities,
      'output_modalities': instance.outputModalities,
      'tokenizer': instance.tokenizer,
    };

_TopProvider _$TopProviderFromJson(Map<String, dynamic> json) => _TopProvider(
      isModerated: json['is_moderated'] as bool,
    );

Map<String, dynamic> _$TopProviderToJson(_TopProvider instance) =>
    <String, dynamic>{
      'is_moderated': instance.isModerated,
    };

_ModelPricing _$ModelPricingFromJson(Map<String, dynamic> json) =>
    _ModelPricing(
      prompt: json['prompt'] as String,
      completion: json['completion'] as String,
      image: json['image'] as String,
      request: json['request'] as String,
      webSearch: json['web_search'] as String,
      internalReasoning: json['internal_reasoning'] as String,
    );

Map<String, dynamic> _$ModelPricingToJson(_ModelPricing instance) =>
    <String, dynamic>{
      'prompt': instance.prompt,
      'completion': instance.completion,
      'image': instance.image,
      'request': instance.request,
      'web_search': instance.webSearch,
      'internal_reasoning': instance.internalReasoning,
    };

_OpenRouterModel _$OpenRouterModelFromJson(Map<String, dynamic> json) =>
    _OpenRouterModel(
      id: json['id'] as String,
      name: json['name'] as String,
      created: (json['created'] as num).toInt(),
      description: json['description'] as String,
      architecture: ModelArchitecture.fromJson(
          json['architecture'] as Map<String, dynamic>),
      topProvider:
          TopProvider.fromJson(json['top_provider'] as Map<String, dynamic>),
      pricing: ModelPricing.fromJson(json['pricing'] as Map<String, dynamic>),
      canonicalSlug: json['canonical_slug'] as String,
      contextLength: (json['context_length'] as num).toInt(),
      huggingFaceId: json['hugging_face_id'] as String,
      perRequestLimits: json['per_request_limits'] as Map<String, dynamic>,
      supportedParameters: (json['supported_parameters'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$OpenRouterModelToJson(_OpenRouterModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'created': instance.created,
      'description': instance.description,
      'architecture': instance.architecture,
      'top_provider': instance.topProvider,
      'pricing': instance.pricing,
      'canonical_slug': instance.canonicalSlug,
      'context_length': instance.contextLength,
      'hugging_face_id': instance.huggingFaceId,
      'per_request_limits': instance.perRequestLimits,
      'supported_parameters': instance.supportedParameters,
    };
