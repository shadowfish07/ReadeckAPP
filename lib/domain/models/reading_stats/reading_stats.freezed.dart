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

  /// 统计数据
  @JsonKey(name: 'character_count')
  CharacterCount get characterCount;

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
            (identical(other.characterCount, characterCount) ||
                other.characterCount == characterCount) &&
            (identical(other.createdDate, createdDate) ||
                other.createdDate == createdDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, bookmarkId, characterCount, createdDate);

  @override
  String toString() {
    return 'ReadingStatsModel(id: $id, bookmarkId: $bookmarkId, characterCount: $characterCount, createdDate: $createdDate)';
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
      @JsonKey(name: 'character_count') CharacterCount characterCount,
      DateTime createdDate});

  $CharacterCountCopyWith<$Res> get characterCount;
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
    Object? characterCount = null,
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
      characterCount: null == characterCount
          ? _self.characterCount
          : characterCount // ignore: cast_nullable_to_non_nullable
              as CharacterCount,
      createdDate: null == createdDate
          ? _self.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }

  /// Create a copy of ReadingStatsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CharacterCountCopyWith<$Res> get characterCount {
    return $CharacterCountCopyWith<$Res>(_self.characterCount, (value) {
      return _then(_self.copyWith(characterCount: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _ReadingStatsModel implements ReadingStatsModel {
  const _ReadingStatsModel(
      {this.id,
      required this.bookmarkId,
      @JsonKey(name: 'character_count') required this.characterCount,
      required this.createdDate});
  factory _ReadingStatsModel.fromJson(Map<String, dynamic> json) =>
      _$ReadingStatsModelFromJson(json);

  /// 数据库主键ID
  @override
  final int? id;

  /// 书签ID
  @override
  final String bookmarkId;

  /// 统计数据
  @override
  @JsonKey(name: 'character_count')
  final CharacterCount characterCount;

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
            (identical(other.characterCount, characterCount) ||
                other.characterCount == characterCount) &&
            (identical(other.createdDate, createdDate) ||
                other.createdDate == createdDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, bookmarkId, characterCount, createdDate);

  @override
  String toString() {
    return 'ReadingStatsModel(id: $id, bookmarkId: $bookmarkId, characterCount: $characterCount, createdDate: $createdDate)';
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
      @JsonKey(name: 'character_count') CharacterCount characterCount,
      DateTime createdDate});

  @override
  $CharacterCountCopyWith<$Res> get characterCount;
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
    Object? characterCount = null,
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
      characterCount: null == characterCount
          ? _self.characterCount
          : characterCount // ignore: cast_nullable_to_non_nullable
              as CharacterCount,
      createdDate: null == createdDate
          ? _self.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }

  /// Create a copy of ReadingStatsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CharacterCountCopyWith<$Res> get characterCount {
    return $CharacterCountCopyWith<$Res>(_self.characterCount, (value) {
      return _then(_self.copyWith(characterCount: value));
    });
  }
}

CharacterCount _$CharacterCountFromJson(Map<String, dynamic> json) {
  return _ReadingStatsData.fromJson(json);
}

/// @nodoc
mixin _$CharacterCount {
  /// 中文字符数量
  int get chineseCharCount;

  /// 英文字符数量
  int get englishCharCount;

  /// Create a copy of CharacterCount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CharacterCountCopyWith<CharacterCount> get copyWith =>
      _$CharacterCountCopyWithImpl<CharacterCount>(
          this as CharacterCount, _$identity);

  /// Serializes this CharacterCount to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CharacterCount &&
            (identical(other.chineseCharCount, chineseCharCount) ||
                other.chineseCharCount == chineseCharCount) &&
            (identical(other.englishCharCount, englishCharCount) ||
                other.englishCharCount == englishCharCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, chineseCharCount, englishCharCount);

  @override
  String toString() {
    return 'CharacterCount(chineseCharCount: $chineseCharCount, englishCharCount: $englishCharCount)';
  }
}

/// @nodoc
abstract mixin class $CharacterCountCopyWith<$Res> {
  factory $CharacterCountCopyWith(
          CharacterCount value, $Res Function(CharacterCount) _then) =
      _$CharacterCountCopyWithImpl;
  @useResult
  $Res call({int chineseCharCount, int englishCharCount});
}

/// @nodoc
class _$CharacterCountCopyWithImpl<$Res>
    implements $CharacterCountCopyWith<$Res> {
  _$CharacterCountCopyWithImpl(this._self, this._then);

  final CharacterCount _self;
  final $Res Function(CharacterCount) _then;

  /// Create a copy of CharacterCount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chineseCharCount = null,
    Object? englishCharCount = null,
  }) {
    return _then(_self.copyWith(
      chineseCharCount: null == chineseCharCount
          ? _self.chineseCharCount
          : chineseCharCount // ignore: cast_nullable_to_non_nullable
              as int,
      englishCharCount: null == englishCharCount
          ? _self.englishCharCount
          : englishCharCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _ReadingStatsData extends CharacterCount {
  const _ReadingStatsData(
      {this.chineseCharCount = 0, this.englishCharCount = 0})
      : super._();
  factory _ReadingStatsData.fromJson(Map<String, dynamic> json) =>
      _$ReadingStatsDataFromJson(json);

  /// 中文字符数量
  @override
  @JsonKey()
  final int chineseCharCount;

  /// 英文字符数量
  @override
  @JsonKey()
  final int englishCharCount;

  /// Create a copy of CharacterCount
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ReadingStatsDataCopyWith<_ReadingStatsData> get copyWith =>
      __$ReadingStatsDataCopyWithImpl<_ReadingStatsData>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ReadingStatsDataToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ReadingStatsData &&
            (identical(other.chineseCharCount, chineseCharCount) ||
                other.chineseCharCount == chineseCharCount) &&
            (identical(other.englishCharCount, englishCharCount) ||
                other.englishCharCount == englishCharCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, chineseCharCount, englishCharCount);

  @override
  String toString() {
    return 'CharacterCount(chineseCharCount: $chineseCharCount, englishCharCount: $englishCharCount)';
  }
}

/// @nodoc
abstract mixin class _$ReadingStatsDataCopyWith<$Res>
    implements $CharacterCountCopyWith<$Res> {
  factory _$ReadingStatsDataCopyWith(
          _ReadingStatsData value, $Res Function(_ReadingStatsData) _then) =
      __$ReadingStatsDataCopyWithImpl;
  @override
  @useResult
  $Res call({int chineseCharCount, int englishCharCount});
}

/// @nodoc
class __$ReadingStatsDataCopyWithImpl<$Res>
    implements _$ReadingStatsDataCopyWith<$Res> {
  __$ReadingStatsDataCopyWithImpl(this._self, this._then);

  final _ReadingStatsData _self;
  final $Res Function(_ReadingStatsData) _then;

  /// Create a copy of CharacterCount
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? chineseCharCount = null,
    Object? englishCharCount = null,
  }) {
    return _then(_ReadingStatsData(
      chineseCharCount: null == chineseCharCount
          ? _self.chineseCharCount
          : chineseCharCount // ignore: cast_nullable_to_non_nullable
              as int,
      englishCharCount: null == englishCharCount
          ? _self.englishCharCount
          : englishCharCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
