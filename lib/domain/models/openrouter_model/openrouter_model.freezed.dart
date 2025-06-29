// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'openrouter_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ModelArchitecture implements DiagnosticableTreeMixin {
  /// 输入模态
  @JsonKey(name: 'input_modalities')
  List<String> get inputModalities;

  /// 输出模态
  @JsonKey(name: 'output_modalities')
  List<String> get outputModalities;

  /// 分词器类型
  String get tokenizer;

  /// Create a copy of ModelArchitecture
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ModelArchitectureCopyWith<ModelArchitecture> get copyWith =>
      _$ModelArchitectureCopyWithImpl<ModelArchitecture>(
          this as ModelArchitecture, _$identity);

  /// Serializes this ModelArchitecture to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'ModelArchitecture'))
      ..add(DiagnosticsProperty('inputModalities', inputModalities))
      ..add(DiagnosticsProperty('outputModalities', outputModalities))
      ..add(DiagnosticsProperty('tokenizer', tokenizer));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ModelArchitecture &&
            const DeepCollectionEquality()
                .equals(other.inputModalities, inputModalities) &&
            const DeepCollectionEquality()
                .equals(other.outputModalities, outputModalities) &&
            (identical(other.tokenizer, tokenizer) ||
                other.tokenizer == tokenizer));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(inputModalities),
      const DeepCollectionEquality().hash(outputModalities),
      tokenizer);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ModelArchitecture(inputModalities: $inputModalities, outputModalities: $outputModalities, tokenizer: $tokenizer)';
  }
}

/// @nodoc
abstract mixin class $ModelArchitectureCopyWith<$Res> {
  factory $ModelArchitectureCopyWith(
          ModelArchitecture value, $Res Function(ModelArchitecture) _then) =
      _$ModelArchitectureCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: 'input_modalities') List<String> inputModalities,
      @JsonKey(name: 'output_modalities') List<String> outputModalities,
      String tokenizer});
}

/// @nodoc
class _$ModelArchitectureCopyWithImpl<$Res>
    implements $ModelArchitectureCopyWith<$Res> {
  _$ModelArchitectureCopyWithImpl(this._self, this._then);

  final ModelArchitecture _self;
  final $Res Function(ModelArchitecture) _then;

  /// Create a copy of ModelArchitecture
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? inputModalities = null,
    Object? outputModalities = null,
    Object? tokenizer = null,
  }) {
    return _then(_self.copyWith(
      inputModalities: null == inputModalities
          ? _self.inputModalities
          : inputModalities // ignore: cast_nullable_to_non_nullable
              as List<String>,
      outputModalities: null == outputModalities
          ? _self.outputModalities
          : outputModalities // ignore: cast_nullable_to_non_nullable
              as List<String>,
      tokenizer: null == tokenizer
          ? _self.tokenizer
          : tokenizer // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _ModelArchitecture
    with DiagnosticableTreeMixin
    implements ModelArchitecture {
  const _ModelArchitecture(
      {@JsonKey(name: 'input_modalities')
      final List<String> inputModalities = const <String>[],
      @JsonKey(name: 'output_modalities')
      final List<String> outputModalities = const <String>[],
      this.tokenizer = ''})
      : _inputModalities = inputModalities,
        _outputModalities = outputModalities;
  factory _ModelArchitecture.fromJson(Map<String, dynamic> json) =>
      _$ModelArchitectureFromJson(json);

  /// 输入模态
  final List<String> _inputModalities;

  /// 输入模态
  @override
  @JsonKey(name: 'input_modalities')
  List<String> get inputModalities {
    if (_inputModalities is EqualUnmodifiableListView) return _inputModalities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_inputModalities);
  }

  /// 输出模态
  final List<String> _outputModalities;

  /// 输出模态
  @override
  @JsonKey(name: 'output_modalities')
  List<String> get outputModalities {
    if (_outputModalities is EqualUnmodifiableListView)
      return _outputModalities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_outputModalities);
  }

  /// 分词器类型
  @override
  @JsonKey()
  final String tokenizer;

  /// Create a copy of ModelArchitecture
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ModelArchitectureCopyWith<_ModelArchitecture> get copyWith =>
      __$ModelArchitectureCopyWithImpl<_ModelArchitecture>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ModelArchitectureToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'ModelArchitecture'))
      ..add(DiagnosticsProperty('inputModalities', inputModalities))
      ..add(DiagnosticsProperty('outputModalities', outputModalities))
      ..add(DiagnosticsProperty('tokenizer', tokenizer));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ModelArchitecture &&
            const DeepCollectionEquality()
                .equals(other._inputModalities, _inputModalities) &&
            const DeepCollectionEquality()
                .equals(other._outputModalities, _outputModalities) &&
            (identical(other.tokenizer, tokenizer) ||
                other.tokenizer == tokenizer));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_inputModalities),
      const DeepCollectionEquality().hash(_outputModalities),
      tokenizer);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ModelArchitecture(inputModalities: $inputModalities, outputModalities: $outputModalities, tokenizer: $tokenizer)';
  }
}

/// @nodoc
abstract mixin class _$ModelArchitectureCopyWith<$Res>
    implements $ModelArchitectureCopyWith<$Res> {
  factory _$ModelArchitectureCopyWith(
          _ModelArchitecture value, $Res Function(_ModelArchitecture) _then) =
      __$ModelArchitectureCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'input_modalities') List<String> inputModalities,
      @JsonKey(name: 'output_modalities') List<String> outputModalities,
      String tokenizer});
}

/// @nodoc
class __$ModelArchitectureCopyWithImpl<$Res>
    implements _$ModelArchitectureCopyWith<$Res> {
  __$ModelArchitectureCopyWithImpl(this._self, this._then);

  final _ModelArchitecture _self;
  final $Res Function(_ModelArchitecture) _then;

  /// Create a copy of ModelArchitecture
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? inputModalities = null,
    Object? outputModalities = null,
    Object? tokenizer = null,
  }) {
    return _then(_ModelArchitecture(
      inputModalities: null == inputModalities
          ? _self._inputModalities
          : inputModalities // ignore: cast_nullable_to_non_nullable
              as List<String>,
      outputModalities: null == outputModalities
          ? _self._outputModalities
          : outputModalities // ignore: cast_nullable_to_non_nullable
              as List<String>,
      tokenizer: null == tokenizer
          ? _self.tokenizer
          : tokenizer // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$TopProvider implements DiagnosticableTreeMixin {
  /// 是否受到审核
  @JsonKey(name: 'is_moderated')
  bool get isModerated;

  /// Create a copy of TopProvider
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TopProviderCopyWith<TopProvider> get copyWith =>
      _$TopProviderCopyWithImpl<TopProvider>(this as TopProvider, _$identity);

  /// Serializes this TopProvider to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'TopProvider'))
      ..add(DiagnosticsProperty('isModerated', isModerated));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TopProvider &&
            (identical(other.isModerated, isModerated) ||
                other.isModerated == isModerated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, isModerated);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'TopProvider(isModerated: $isModerated)';
  }
}

/// @nodoc
abstract mixin class $TopProviderCopyWith<$Res> {
  factory $TopProviderCopyWith(
          TopProvider value, $Res Function(TopProvider) _then) =
      _$TopProviderCopyWithImpl;
  @useResult
  $Res call({@JsonKey(name: 'is_moderated') bool isModerated});
}

/// @nodoc
class _$TopProviderCopyWithImpl<$Res> implements $TopProviderCopyWith<$Res> {
  _$TopProviderCopyWithImpl(this._self, this._then);

  final TopProvider _self;
  final $Res Function(TopProvider) _then;

  /// Create a copy of TopProvider
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isModerated = null,
  }) {
    return _then(_self.copyWith(
      isModerated: null == isModerated
          ? _self.isModerated
          : isModerated // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _TopProvider with DiagnosticableTreeMixin implements TopProvider {
  const _TopProvider({@JsonKey(name: 'is_moderated') this.isModerated = false});
  factory _TopProvider.fromJson(Map<String, dynamic> json) =>
      _$TopProviderFromJson(json);

  /// 是否受到审核
  @override
  @JsonKey(name: 'is_moderated')
  final bool isModerated;

  /// Create a copy of TopProvider
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TopProviderCopyWith<_TopProvider> get copyWith =>
      __$TopProviderCopyWithImpl<_TopProvider>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TopProviderToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'TopProvider'))
      ..add(DiagnosticsProperty('isModerated', isModerated));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TopProvider &&
            (identical(other.isModerated, isModerated) ||
                other.isModerated == isModerated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, isModerated);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'TopProvider(isModerated: $isModerated)';
  }
}

/// @nodoc
abstract mixin class _$TopProviderCopyWith<$Res>
    implements $TopProviderCopyWith<$Res> {
  factory _$TopProviderCopyWith(
          _TopProvider value, $Res Function(_TopProvider) _then) =
      __$TopProviderCopyWithImpl;
  @override
  @useResult
  $Res call({@JsonKey(name: 'is_moderated') bool isModerated});
}

/// @nodoc
class __$TopProviderCopyWithImpl<$Res> implements _$TopProviderCopyWith<$Res> {
  __$TopProviderCopyWithImpl(this._self, this._then);

  final _TopProvider _self;
  final $Res Function(_TopProvider) _then;

  /// Create a copy of TopProvider
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? isModerated = null,
  }) {
    return _then(_TopProvider(
      isModerated: null == isModerated
          ? _self.isModerated
          : isModerated // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
mixin _$ModelPricing implements DiagnosticableTreeMixin {
  /// 提示价格
  String get prompt;

  /// 完成价格
  String get completion;

  /// 图片价格
  String get image;

  /// 请求价格
  String get request;

  /// 网络搜索价格
  @JsonKey(name: 'web_search')
  String get webSearch;

  /// 内部推理价格
  @JsonKey(name: 'internal_reasoning')
  String get internalReasoning;

  /// Create a copy of ModelPricing
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ModelPricingCopyWith<ModelPricing> get copyWith =>
      _$ModelPricingCopyWithImpl<ModelPricing>(
          this as ModelPricing, _$identity);

  /// Serializes this ModelPricing to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'ModelPricing'))
      ..add(DiagnosticsProperty('prompt', prompt))
      ..add(DiagnosticsProperty('completion', completion))
      ..add(DiagnosticsProperty('image', image))
      ..add(DiagnosticsProperty('request', request))
      ..add(DiagnosticsProperty('webSearch', webSearch))
      ..add(DiagnosticsProperty('internalReasoning', internalReasoning));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ModelPricing &&
            (identical(other.prompt, prompt) || other.prompt == prompt) &&
            (identical(other.completion, completion) ||
                other.completion == completion) &&
            (identical(other.image, image) || other.image == image) &&
            (identical(other.request, request) || other.request == request) &&
            (identical(other.webSearch, webSearch) ||
                other.webSearch == webSearch) &&
            (identical(other.internalReasoning, internalReasoning) ||
                other.internalReasoning == internalReasoning));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, prompt, completion, image,
      request, webSearch, internalReasoning);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ModelPricing(prompt: $prompt, completion: $completion, image: $image, request: $request, webSearch: $webSearch, internalReasoning: $internalReasoning)';
  }
}

/// @nodoc
abstract mixin class $ModelPricingCopyWith<$Res> {
  factory $ModelPricingCopyWith(
          ModelPricing value, $Res Function(ModelPricing) _then) =
      _$ModelPricingCopyWithImpl;
  @useResult
  $Res call(
      {String prompt,
      String completion,
      String image,
      String request,
      @JsonKey(name: 'web_search') String webSearch,
      @JsonKey(name: 'internal_reasoning') String internalReasoning});
}

/// @nodoc
class _$ModelPricingCopyWithImpl<$Res> implements $ModelPricingCopyWith<$Res> {
  _$ModelPricingCopyWithImpl(this._self, this._then);

  final ModelPricing _self;
  final $Res Function(ModelPricing) _then;

  /// Create a copy of ModelPricing
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? prompt = null,
    Object? completion = null,
    Object? image = null,
    Object? request = null,
    Object? webSearch = null,
    Object? internalReasoning = null,
  }) {
    return _then(_self.copyWith(
      prompt: null == prompt
          ? _self.prompt
          : prompt // ignore: cast_nullable_to_non_nullable
              as String,
      completion: null == completion
          ? _self.completion
          : completion // ignore: cast_nullable_to_non_nullable
              as String,
      image: null == image
          ? _self.image
          : image // ignore: cast_nullable_to_non_nullable
              as String,
      request: null == request
          ? _self.request
          : request // ignore: cast_nullable_to_non_nullable
              as String,
      webSearch: null == webSearch
          ? _self.webSearch
          : webSearch // ignore: cast_nullable_to_non_nullable
              as String,
      internalReasoning: null == internalReasoning
          ? _self.internalReasoning
          : internalReasoning // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _ModelPricing with DiagnosticableTreeMixin implements ModelPricing {
  const _ModelPricing(
      {this.prompt = '0',
      this.completion = '0',
      this.image = '0',
      this.request = '0',
      @JsonKey(name: 'web_search') this.webSearch = '0',
      @JsonKey(name: 'internal_reasoning') this.internalReasoning = '0'});
  factory _ModelPricing.fromJson(Map<String, dynamic> json) =>
      _$ModelPricingFromJson(json);

  /// 提示价格
  @override
  @JsonKey()
  final String prompt;

  /// 完成价格
  @override
  @JsonKey()
  final String completion;

  /// 图片价格
  @override
  @JsonKey()
  final String image;

  /// 请求价格
  @override
  @JsonKey()
  final String request;

  /// 网络搜索价格
  @override
  @JsonKey(name: 'web_search')
  final String webSearch;

  /// 内部推理价格
  @override
  @JsonKey(name: 'internal_reasoning')
  final String internalReasoning;

  /// Create a copy of ModelPricing
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ModelPricingCopyWith<_ModelPricing> get copyWith =>
      __$ModelPricingCopyWithImpl<_ModelPricing>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ModelPricingToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'ModelPricing'))
      ..add(DiagnosticsProperty('prompt', prompt))
      ..add(DiagnosticsProperty('completion', completion))
      ..add(DiagnosticsProperty('image', image))
      ..add(DiagnosticsProperty('request', request))
      ..add(DiagnosticsProperty('webSearch', webSearch))
      ..add(DiagnosticsProperty('internalReasoning', internalReasoning));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ModelPricing &&
            (identical(other.prompt, prompt) || other.prompt == prompt) &&
            (identical(other.completion, completion) ||
                other.completion == completion) &&
            (identical(other.image, image) || other.image == image) &&
            (identical(other.request, request) || other.request == request) &&
            (identical(other.webSearch, webSearch) ||
                other.webSearch == webSearch) &&
            (identical(other.internalReasoning, internalReasoning) ||
                other.internalReasoning == internalReasoning));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, prompt, completion, image,
      request, webSearch, internalReasoning);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ModelPricing(prompt: $prompt, completion: $completion, image: $image, request: $request, webSearch: $webSearch, internalReasoning: $internalReasoning)';
  }
}

/// @nodoc
abstract mixin class _$ModelPricingCopyWith<$Res>
    implements $ModelPricingCopyWith<$Res> {
  factory _$ModelPricingCopyWith(
          _ModelPricing value, $Res Function(_ModelPricing) _then) =
      __$ModelPricingCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String prompt,
      String completion,
      String image,
      String request,
      @JsonKey(name: 'web_search') String webSearch,
      @JsonKey(name: 'internal_reasoning') String internalReasoning});
}

/// @nodoc
class __$ModelPricingCopyWithImpl<$Res>
    implements _$ModelPricingCopyWith<$Res> {
  __$ModelPricingCopyWithImpl(this._self, this._then);

  final _ModelPricing _self;
  final $Res Function(_ModelPricing) _then;

  /// Create a copy of ModelPricing
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? prompt = null,
    Object? completion = null,
    Object? image = null,
    Object? request = null,
    Object? webSearch = null,
    Object? internalReasoning = null,
  }) {
    return _then(_ModelPricing(
      prompt: null == prompt
          ? _self.prompt
          : prompt // ignore: cast_nullable_to_non_nullable
              as String,
      completion: null == completion
          ? _self.completion
          : completion // ignore: cast_nullable_to_non_nullable
              as String,
      image: null == image
          ? _self.image
          : image // ignore: cast_nullable_to_non_nullable
              as String,
      request: null == request
          ? _self.request
          : request // ignore: cast_nullable_to_non_nullable
              as String,
      webSearch: null == webSearch
          ? _self.webSearch
          : webSearch // ignore: cast_nullable_to_non_nullable
              as String,
      internalReasoning: null == internalReasoning
          ? _self.internalReasoning
          : internalReasoning // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$OpenRouterModel implements DiagnosticableTreeMixin {
  /// 模型ID
  String get id;

  /// 模型名称
  String get name;

  /// 创建时间戳
  int get created;

  /// 模型描述
  String get description;

  /// 模型架构
  ModelArchitecture? get architecture;

  /// 顶级提供商
  @JsonKey(name: 'top_provider')
  TopProvider? get topProvider;

  /// 定价信息
  ModelPricing? get pricing;

  /// 规范化标识符
  @JsonKey(name: 'canonical_slug')
  String get canonicalSlug;

  /// 上下文长度
  @JsonKey(name: 'context_length')
  int get contextLength;

  /// Hugging Face ID
  @JsonKey(name: 'hugging_face_id')
  String get huggingFaceId;

  /// 每请求限制
  @JsonKey(name: 'per_request_limits')
  Map<String, dynamic> get perRequestLimits;

  /// 支持的参数
  @JsonKey(name: 'supported_parameters')
  List<String> get supportedParameters;

  /// Create a copy of OpenRouterModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $OpenRouterModelCopyWith<OpenRouterModel> get copyWith =>
      _$OpenRouterModelCopyWithImpl<OpenRouterModel>(
          this as OpenRouterModel, _$identity);

  /// Serializes this OpenRouterModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'OpenRouterModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('created', created))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('architecture', architecture))
      ..add(DiagnosticsProperty('topProvider', topProvider))
      ..add(DiagnosticsProperty('pricing', pricing))
      ..add(DiagnosticsProperty('canonicalSlug', canonicalSlug))
      ..add(DiagnosticsProperty('contextLength', contextLength))
      ..add(DiagnosticsProperty('huggingFaceId', huggingFaceId))
      ..add(DiagnosticsProperty('perRequestLimits', perRequestLimits))
      ..add(DiagnosticsProperty('supportedParameters', supportedParameters));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is OpenRouterModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.created, created) || other.created == created) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.architecture, architecture) ||
                other.architecture == architecture) &&
            (identical(other.topProvider, topProvider) ||
                other.topProvider == topProvider) &&
            (identical(other.pricing, pricing) || other.pricing == pricing) &&
            (identical(other.canonicalSlug, canonicalSlug) ||
                other.canonicalSlug == canonicalSlug) &&
            (identical(other.contextLength, contextLength) ||
                other.contextLength == contextLength) &&
            (identical(other.huggingFaceId, huggingFaceId) ||
                other.huggingFaceId == huggingFaceId) &&
            const DeepCollectionEquality()
                .equals(other.perRequestLimits, perRequestLimits) &&
            const DeepCollectionEquality()
                .equals(other.supportedParameters, supportedParameters));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      created,
      description,
      architecture,
      topProvider,
      pricing,
      canonicalSlug,
      contextLength,
      huggingFaceId,
      const DeepCollectionEquality().hash(perRequestLimits),
      const DeepCollectionEquality().hash(supportedParameters));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'OpenRouterModel(id: $id, name: $name, created: $created, description: $description, architecture: $architecture, topProvider: $topProvider, pricing: $pricing, canonicalSlug: $canonicalSlug, contextLength: $contextLength, huggingFaceId: $huggingFaceId, perRequestLimits: $perRequestLimits, supportedParameters: $supportedParameters)';
  }
}

/// @nodoc
abstract mixin class $OpenRouterModelCopyWith<$Res> {
  factory $OpenRouterModelCopyWith(
          OpenRouterModel value, $Res Function(OpenRouterModel) _then) =
      _$OpenRouterModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      int created,
      String description,
      ModelArchitecture? architecture,
      @JsonKey(name: 'top_provider') TopProvider? topProvider,
      ModelPricing? pricing,
      @JsonKey(name: 'canonical_slug') String canonicalSlug,
      @JsonKey(name: 'context_length') int contextLength,
      @JsonKey(name: 'hugging_face_id') String huggingFaceId,
      @JsonKey(name: 'per_request_limits')
      Map<String, dynamic> perRequestLimits,
      @JsonKey(name: 'supported_parameters') List<String> supportedParameters});

  $ModelArchitectureCopyWith<$Res>? get architecture;
  $TopProviderCopyWith<$Res>? get topProvider;
  $ModelPricingCopyWith<$Res>? get pricing;
}

/// @nodoc
class _$OpenRouterModelCopyWithImpl<$Res>
    implements $OpenRouterModelCopyWith<$Res> {
  _$OpenRouterModelCopyWithImpl(this._self, this._then);

  final OpenRouterModel _self;
  final $Res Function(OpenRouterModel) _then;

  /// Create a copy of OpenRouterModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? created = null,
    Object? description = null,
    Object? architecture = freezed,
    Object? topProvider = freezed,
    Object? pricing = freezed,
    Object? canonicalSlug = null,
    Object? contextLength = null,
    Object? huggingFaceId = null,
    Object? perRequestLimits = null,
    Object? supportedParameters = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      created: null == created
          ? _self.created
          : created // ignore: cast_nullable_to_non_nullable
              as int,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      architecture: freezed == architecture
          ? _self.architecture
          : architecture // ignore: cast_nullable_to_non_nullable
              as ModelArchitecture?,
      topProvider: freezed == topProvider
          ? _self.topProvider
          : topProvider // ignore: cast_nullable_to_non_nullable
              as TopProvider?,
      pricing: freezed == pricing
          ? _self.pricing
          : pricing // ignore: cast_nullable_to_non_nullable
              as ModelPricing?,
      canonicalSlug: null == canonicalSlug
          ? _self.canonicalSlug
          : canonicalSlug // ignore: cast_nullable_to_non_nullable
              as String,
      contextLength: null == contextLength
          ? _self.contextLength
          : contextLength // ignore: cast_nullable_to_non_nullable
              as int,
      huggingFaceId: null == huggingFaceId
          ? _self.huggingFaceId
          : huggingFaceId // ignore: cast_nullable_to_non_nullable
              as String,
      perRequestLimits: null == perRequestLimits
          ? _self.perRequestLimits
          : perRequestLimits // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      supportedParameters: null == supportedParameters
          ? _self.supportedParameters
          : supportedParameters // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }

  /// Create a copy of OpenRouterModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ModelArchitectureCopyWith<$Res>? get architecture {
    if (_self.architecture == null) {
      return null;
    }

    return $ModelArchitectureCopyWith<$Res>(_self.architecture!, (value) {
      return _then(_self.copyWith(architecture: value));
    });
  }

  /// Create a copy of OpenRouterModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TopProviderCopyWith<$Res>? get topProvider {
    if (_self.topProvider == null) {
      return null;
    }

    return $TopProviderCopyWith<$Res>(_self.topProvider!, (value) {
      return _then(_self.copyWith(topProvider: value));
    });
  }

  /// Create a copy of OpenRouterModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ModelPricingCopyWith<$Res>? get pricing {
    if (_self.pricing == null) {
      return null;
    }

    return $ModelPricingCopyWith<$Res>(_self.pricing!, (value) {
      return _then(_self.copyWith(pricing: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _OpenRouterModel with DiagnosticableTreeMixin implements OpenRouterModel {
  const _OpenRouterModel(
      {required this.id,
      required this.name,
      this.created = 0,
      this.description = '',
      this.architecture,
      @JsonKey(name: 'top_provider') this.topProvider,
      this.pricing,
      @JsonKey(name: 'canonical_slug') this.canonicalSlug = '',
      @JsonKey(name: 'context_length') this.contextLength = 0,
      @JsonKey(name: 'hugging_face_id') this.huggingFaceId = '',
      @JsonKey(name: 'per_request_limits')
      final Map<String, dynamic> perRequestLimits = const <String, dynamic>{},
      @JsonKey(name: 'supported_parameters')
      final List<String> supportedParameters = const <String>[]})
      : _perRequestLimits = perRequestLimits,
        _supportedParameters = supportedParameters;
  factory _OpenRouterModel.fromJson(Map<String, dynamic> json) =>
      _$OpenRouterModelFromJson(json);

  /// 模型ID
  @override
  final String id;

  /// 模型名称
  @override
  final String name;

  /// 创建时间戳
  @override
  @JsonKey()
  final int created;

  /// 模型描述
  @override
  @JsonKey()
  final String description;

  /// 模型架构
  @override
  final ModelArchitecture? architecture;

  /// 顶级提供商
  @override
  @JsonKey(name: 'top_provider')
  final TopProvider? topProvider;

  /// 定价信息
  @override
  final ModelPricing? pricing;

  /// 规范化标识符
  @override
  @JsonKey(name: 'canonical_slug')
  final String canonicalSlug;

  /// 上下文长度
  @override
  @JsonKey(name: 'context_length')
  final int contextLength;

  /// Hugging Face ID
  @override
  @JsonKey(name: 'hugging_face_id')
  final String huggingFaceId;

  /// 每请求限制
  final Map<String, dynamic> _perRequestLimits;

  /// 每请求限制
  @override
  @JsonKey(name: 'per_request_limits')
  Map<String, dynamic> get perRequestLimits {
    if (_perRequestLimits is EqualUnmodifiableMapView) return _perRequestLimits;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_perRequestLimits);
  }

  /// 支持的参数
  final List<String> _supportedParameters;

  /// 支持的参数
  @override
  @JsonKey(name: 'supported_parameters')
  List<String> get supportedParameters {
    if (_supportedParameters is EqualUnmodifiableListView)
      return _supportedParameters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_supportedParameters);
  }

  /// Create a copy of OpenRouterModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$OpenRouterModelCopyWith<_OpenRouterModel> get copyWith =>
      __$OpenRouterModelCopyWithImpl<_OpenRouterModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$OpenRouterModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'OpenRouterModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('created', created))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('architecture', architecture))
      ..add(DiagnosticsProperty('topProvider', topProvider))
      ..add(DiagnosticsProperty('pricing', pricing))
      ..add(DiagnosticsProperty('canonicalSlug', canonicalSlug))
      ..add(DiagnosticsProperty('contextLength', contextLength))
      ..add(DiagnosticsProperty('huggingFaceId', huggingFaceId))
      ..add(DiagnosticsProperty('perRequestLimits', perRequestLimits))
      ..add(DiagnosticsProperty('supportedParameters', supportedParameters));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _OpenRouterModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.created, created) || other.created == created) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.architecture, architecture) ||
                other.architecture == architecture) &&
            (identical(other.topProvider, topProvider) ||
                other.topProvider == topProvider) &&
            (identical(other.pricing, pricing) || other.pricing == pricing) &&
            (identical(other.canonicalSlug, canonicalSlug) ||
                other.canonicalSlug == canonicalSlug) &&
            (identical(other.contextLength, contextLength) ||
                other.contextLength == contextLength) &&
            (identical(other.huggingFaceId, huggingFaceId) ||
                other.huggingFaceId == huggingFaceId) &&
            const DeepCollectionEquality()
                .equals(other._perRequestLimits, _perRequestLimits) &&
            const DeepCollectionEquality()
                .equals(other._supportedParameters, _supportedParameters));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      created,
      description,
      architecture,
      topProvider,
      pricing,
      canonicalSlug,
      contextLength,
      huggingFaceId,
      const DeepCollectionEquality().hash(_perRequestLimits),
      const DeepCollectionEquality().hash(_supportedParameters));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'OpenRouterModel(id: $id, name: $name, created: $created, description: $description, architecture: $architecture, topProvider: $topProvider, pricing: $pricing, canonicalSlug: $canonicalSlug, contextLength: $contextLength, huggingFaceId: $huggingFaceId, perRequestLimits: $perRequestLimits, supportedParameters: $supportedParameters)';
  }
}

/// @nodoc
abstract mixin class _$OpenRouterModelCopyWith<$Res>
    implements $OpenRouterModelCopyWith<$Res> {
  factory _$OpenRouterModelCopyWith(
          _OpenRouterModel value, $Res Function(_OpenRouterModel) _then) =
      __$OpenRouterModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      int created,
      String description,
      ModelArchitecture? architecture,
      @JsonKey(name: 'top_provider') TopProvider? topProvider,
      ModelPricing? pricing,
      @JsonKey(name: 'canonical_slug') String canonicalSlug,
      @JsonKey(name: 'context_length') int contextLength,
      @JsonKey(name: 'hugging_face_id') String huggingFaceId,
      @JsonKey(name: 'per_request_limits')
      Map<String, dynamic> perRequestLimits,
      @JsonKey(name: 'supported_parameters') List<String> supportedParameters});

  @override
  $ModelArchitectureCopyWith<$Res>? get architecture;
  @override
  $TopProviderCopyWith<$Res>? get topProvider;
  @override
  $ModelPricingCopyWith<$Res>? get pricing;
}

/// @nodoc
class __$OpenRouterModelCopyWithImpl<$Res>
    implements _$OpenRouterModelCopyWith<$Res> {
  __$OpenRouterModelCopyWithImpl(this._self, this._then);

  final _OpenRouterModel _self;
  final $Res Function(_OpenRouterModel) _then;

  /// Create a copy of OpenRouterModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? created = null,
    Object? description = null,
    Object? architecture = freezed,
    Object? topProvider = freezed,
    Object? pricing = freezed,
    Object? canonicalSlug = null,
    Object? contextLength = null,
    Object? huggingFaceId = null,
    Object? perRequestLimits = null,
    Object? supportedParameters = null,
  }) {
    return _then(_OpenRouterModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      created: null == created
          ? _self.created
          : created // ignore: cast_nullable_to_non_nullable
              as int,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      architecture: freezed == architecture
          ? _self.architecture
          : architecture // ignore: cast_nullable_to_non_nullable
              as ModelArchitecture?,
      topProvider: freezed == topProvider
          ? _self.topProvider
          : topProvider // ignore: cast_nullable_to_non_nullable
              as TopProvider?,
      pricing: freezed == pricing
          ? _self.pricing
          : pricing // ignore: cast_nullable_to_non_nullable
              as ModelPricing?,
      canonicalSlug: null == canonicalSlug
          ? _self.canonicalSlug
          : canonicalSlug // ignore: cast_nullable_to_non_nullable
              as String,
      contextLength: null == contextLength
          ? _self.contextLength
          : contextLength // ignore: cast_nullable_to_non_nullable
              as int,
      huggingFaceId: null == huggingFaceId
          ? _self.huggingFaceId
          : huggingFaceId // ignore: cast_nullable_to_non_nullable
              as String,
      perRequestLimits: null == perRequestLimits
          ? _self._perRequestLimits
          : perRequestLimits // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      supportedParameters: null == supportedParameters
          ? _self._supportedParameters
          : supportedParameters // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }

  /// Create a copy of OpenRouterModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ModelArchitectureCopyWith<$Res>? get architecture {
    if (_self.architecture == null) {
      return null;
    }

    return $ModelArchitectureCopyWith<$Res>(_self.architecture!, (value) {
      return _then(_self.copyWith(architecture: value));
    });
  }

  /// Create a copy of OpenRouterModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TopProviderCopyWith<$Res>? get topProvider {
    if (_self.topProvider == null) {
      return null;
    }

    return $TopProviderCopyWith<$Res>(_self.topProvider!, (value) {
      return _then(_self.copyWith(topProvider: value));
    });
  }

  /// Create a copy of OpenRouterModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ModelPricingCopyWith<$Res>? get pricing {
    if (_self.pricing == null) {
      return null;
    }

    return $ModelPricingCopyWith<$Res>(_self.pricing!, (value) {
      return _then(_self.copyWith(pricing: value));
    });
  }
}

// dart format on
