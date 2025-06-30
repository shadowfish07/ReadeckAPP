// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReadingStatsModel {
  /// 数据库主键ID
  int? get id;

  /// 书签ID
  String get bookmarkId;

  /// 可阅读字符数量
  int get readableCharCount;

  /// 创建时间
  DateTime get createdDate;

  /// Create a copy of ReadingStatsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ReadingStatsModelCopyWith<ReadingStatsModel> get copyWith =>
      _$ReadingStatsModelCopyWithImpl<ReadingStatsModel>(
          this as ReadingStatsModel, _$identity);

  /// Serializes this ReadingStatsModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ReadingStatsModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookmarkId, bookmarkId) ||
                other.bookmarkId == bookmarkId) &&
            (identical(other.readableCharCount, readableCharCount) ||
                other.readableCharCount == readableCharCount) &&
            (identical(other.createdDate, createdDate) ||
                other.createdDate == createdDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, bookmarkId, readableCharCount, createdDate);

  @override
  String toString() {
    return 'ReadingStatsModel(id: $id, bookmarkId: $bookmarkId, readableCharCount: $readableCharCount, createdDate: $createdDate)';
  }
}

/// @nodoc
abstract mixin class $ReadingStatsModelCopyWith<$Res> {
  factory $ReadingStatsModelCopyWith(
          ReadingStatsModel value, $Res Function(ReadingStatsModel) _then) =
      _$ReadingStatsModelCopyWithImpl;
  @useResult
  $Res call(
      {int? id,
      String bookmarkId,
      int readableCharCount,
      DateTime createdDate});
}

/// @nodoc
class _$ReadingStatsModelCopyWithImpl<$Res>
    implements $ReadingStatsModelCopyWith<$Res> {
  _$ReadingStatsModelCopyWithImpl(this._self, this._then);

  final ReadingStatsModel _self;
  final $Res Function(ReadingStatsModel) _then;

  /// Create a copy of ReadingStatsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? bookmarkId = null,
    Object? readableCharCount = null,
    Object? createdDate = null,
  }) {
    return _then(_self.copyWith(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      bookmarkId: null == bookmarkId
          ? _self.bookmarkId
          : bookmarkId // ignore: cast_nullable_to_non_nullable
              as String,
      readableCharCount: null == readableCharCount
          ? _self.readableCharCount
          : readableCharCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdDate: null == createdDate
          ? _self.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _ReadingStatsModel implements ReadingStatsModel {
  const _ReadingStatsModel(
      {this.id,
      required this.bookmarkId,
      required this.readableCharCount,
      required this.createdDate});
  factory _ReadingStatsModel.fromJson(Map<String, dynamic> json) =>
      _$ReadingStatsModelFromJson(json);

  /// 数据库主键ID
  @override
  final int? id;

  /// 书签ID
  @override
  final String bookmarkId;

  /// 可阅读字符数量
  @override
  final int readableCharCount;

  /// 创建时间
  @override
  final DateTime createdDate;

  /// Create a copy of ReadingStatsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ReadingStatsModelCopyWith<_ReadingStatsModel> get copyWith =>
      __$ReadingStatsModelCopyWithImpl<_ReadingStatsModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ReadingStatsModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ReadingStatsModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookmarkId, bookmarkId) ||
                other.bookmarkId == bookmarkId) &&
            (identical(other.readableCharCount, readableCharCount) ||
                other.readableCharCount == readableCharCount) &&
            (identical(other.createdDate, createdDate) ||
                other.createdDate == createdDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, bookmarkId, readableCharCount, createdDate);

  @override
  String toString() {
    return 'ReadingStatsModel(id: $id, bookmarkId: $bookmarkId, readableCharCount: $readableCharCount, createdDate: $createdDate)';
  }
}

/// @nodoc
abstract mixin class _$ReadingStatsModelCopyWith<$Res>
    implements $ReadingStatsModelCopyWith<$Res> {
  factory _$ReadingStatsModelCopyWith(
          _ReadingStatsModel value, $Res Function(_ReadingStatsModel) _then) =
      __$ReadingStatsModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int? id,
      String bookmarkId,
      int readableCharCount,
      DateTime createdDate});
}

/// @nodoc
class __$ReadingStatsModelCopyWithImpl<$Res>
    implements _$ReadingStatsModelCopyWith<$Res> {
  __$ReadingStatsModelCopyWithImpl(this._self, this._then);

  final _ReadingStatsModel _self;
  final $Res Function(_ReadingStatsModel) _then;

  /// Create a copy of ReadingStatsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = freezed,
    Object? bookmarkId = null,
    Object? readableCharCount = null,
    Object? createdDate = null,
  }) {
    return _then(_ReadingStatsModel(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      bookmarkId: null == bookmarkId
          ? _self.bookmarkId
          : bookmarkId // ignore: cast_nullable_to_non_nullable
              as String,
      readableCharCount: null == readableCharCount
          ? _self.readableCharCount
          : readableCharCount // ignore: cast_nullable_to_non_nullable
              as int,
      createdDate: null == createdDate
          ? _self.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
