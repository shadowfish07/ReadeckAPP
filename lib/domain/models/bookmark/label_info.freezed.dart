// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'label_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LabelInfo implements DiagnosticableTreeMixin {
  /// 标签名称
  String get name;

  /// 具有此标签的书签数量
  int get count;

  /// 标签信息链接
  String get href;

  /// 具有此标签的书签链接
  @JsonKey(name: 'href_bookmarks')
  String get hrefBookmarks;

  /// Create a copy of LabelInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LabelInfoCopyWith<LabelInfo> get copyWith =>
      _$LabelInfoCopyWithImpl<LabelInfo>(this as LabelInfo, _$identity);

  /// Serializes this LabelInfo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'LabelInfo'))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('count', count))
      ..add(DiagnosticsProperty('href', href))
      ..add(DiagnosticsProperty('hrefBookmarks', hrefBookmarks));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LabelInfo &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.href, href) || other.href == href) &&
            (identical(other.hrefBookmarks, hrefBookmarks) ||
                other.hrefBookmarks == hrefBookmarks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, count, href, hrefBookmarks);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'LabelInfo(name: $name, count: $count, href: $href, hrefBookmarks: $hrefBookmarks)';
  }
}

/// @nodoc
abstract mixin class $LabelInfoCopyWith<$Res> {
  factory $LabelInfoCopyWith(LabelInfo value, $Res Function(LabelInfo) _then) =
      _$LabelInfoCopyWithImpl;
  @useResult
  $Res call(
      {String name,
      int count,
      String href,
      @JsonKey(name: 'href_bookmarks') String hrefBookmarks});
}

/// @nodoc
class _$LabelInfoCopyWithImpl<$Res> implements $LabelInfoCopyWith<$Res> {
  _$LabelInfoCopyWithImpl(this._self, this._then);

  final LabelInfo _self;
  final $Res Function(LabelInfo) _then;

  /// Create a copy of LabelInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? count = null,
    Object? href = null,
    Object? hrefBookmarks = null,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _self.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      href: null == href
          ? _self.href
          : href // ignore: cast_nullable_to_non_nullable
              as String,
      hrefBookmarks: null == hrefBookmarks
          ? _self.hrefBookmarks
          : hrefBookmarks // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _LabelInfo with DiagnosticableTreeMixin implements LabelInfo {
  const _LabelInfo(
      {required this.name,
      required this.count,
      required this.href,
      @JsonKey(name: 'href_bookmarks') required this.hrefBookmarks});
  factory _LabelInfo.fromJson(Map<String, dynamic> json) =>
      _$LabelInfoFromJson(json);

  /// 标签名称
  @override
  final String name;

  /// 具有此标签的书签数量
  @override
  final int count;

  /// 标签信息链接
  @override
  final String href;

  /// 具有此标签的书签链接
  @override
  @JsonKey(name: 'href_bookmarks')
  final String hrefBookmarks;

  /// Create a copy of LabelInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LabelInfoCopyWith<_LabelInfo> get copyWith =>
      __$LabelInfoCopyWithImpl<_LabelInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LabelInfoToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'LabelInfo'))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('count', count))
      ..add(DiagnosticsProperty('href', href))
      ..add(DiagnosticsProperty('hrefBookmarks', hrefBookmarks));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LabelInfo &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.href, href) || other.href == href) &&
            (identical(other.hrefBookmarks, hrefBookmarks) ||
                other.hrefBookmarks == hrefBookmarks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, count, href, hrefBookmarks);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'LabelInfo(name: $name, count: $count, href: $href, hrefBookmarks: $hrefBookmarks)';
  }
}

/// @nodoc
abstract mixin class _$LabelInfoCopyWith<$Res>
    implements $LabelInfoCopyWith<$Res> {
  factory _$LabelInfoCopyWith(
          _LabelInfo value, $Res Function(_LabelInfo) _then) =
      __$LabelInfoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String name,
      int count,
      String href,
      @JsonKey(name: 'href_bookmarks') String hrefBookmarks});
}

/// @nodoc
class __$LabelInfoCopyWithImpl<$Res> implements _$LabelInfoCopyWith<$Res> {
  __$LabelInfoCopyWithImpl(this._self, this._then);

  final _LabelInfo _self;
  final $Res Function(_LabelInfo) _then;

  /// Create a copy of LabelInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? count = null,
    Object? href = null,
    Object? hrefBookmarks = null,
  }) {
    return _then(_LabelInfo(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      count: null == count
          ? _self.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      href: null == href
          ? _self.href
          : href // ignore: cast_nullable_to_non_nullable
              as String,
      hrefBookmarks: null == hrefBookmarks
          ? _self.hrefBookmarks
          : hrefBookmarks // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
