// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_read_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DailyReadHistory implements DiagnosticableTreeMixin {
  int get id;
  @JsonKey(
      name: "created_date",
      fromJson: _dateTimeFromJson,
      toJson: _dateTimeToJson)
  DateTime get createdDate;
  @JsonKey(
      name: "bookmark_ids",
      fromJson: _bookmarkIdsFromJson,
      toJson: _bookmarkIdsToJson)
  List<String> get bookmarkIds;

  /// Create a copy of DailyReadHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DailyReadHistoryCopyWith<DailyReadHistory> get copyWith =>
      _$DailyReadHistoryCopyWithImpl<DailyReadHistory>(
          this as DailyReadHistory, _$identity);

  /// Serializes this DailyReadHistory to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'DailyReadHistory'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('createdDate', createdDate))
      ..add(DiagnosticsProperty('bookmarkIds', bookmarkIds));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DailyReadHistory &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.createdDate, createdDate) ||
                other.createdDate == createdDate) &&
            const DeepCollectionEquality()
                .equals(other.bookmarkIds, bookmarkIds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, createdDate,
      const DeepCollectionEquality().hash(bookmarkIds));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DailyReadHistory(id: $id, createdDate: $createdDate, bookmarkIds: $bookmarkIds)';
  }
}

/// @nodoc
abstract mixin class $DailyReadHistoryCopyWith<$Res> {
  factory $DailyReadHistoryCopyWith(
          DailyReadHistory value, $Res Function(DailyReadHistory) _then) =
      _$DailyReadHistoryCopyWithImpl;
  @useResult
  $Res call(
      {int id,
      @JsonKey(
          name: "created_date",
          fromJson: _dateTimeFromJson,
          toJson: _dateTimeToJson)
      DateTime createdDate,
      @JsonKey(
          name: "bookmark_ids",
          fromJson: _bookmarkIdsFromJson,
          toJson: _bookmarkIdsToJson)
      List<String> bookmarkIds});
}

/// @nodoc
class _$DailyReadHistoryCopyWithImpl<$Res>
    implements $DailyReadHistoryCopyWith<$Res> {
  _$DailyReadHistoryCopyWithImpl(this._self, this._then);

  final DailyReadHistory _self;
  final $Res Function(DailyReadHistory) _then;

  /// Create a copy of DailyReadHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? createdDate = null,
    Object? bookmarkIds = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      createdDate: null == createdDate
          ? _self.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      bookmarkIds: null == bookmarkIds
          ? _self.bookmarkIds
          : bookmarkIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _DailyReadHistory
    with DiagnosticableTreeMixin
    implements DailyReadHistory {
  const _DailyReadHistory(
      {required this.id,
      @JsonKey(
          name: "created_date",
          fromJson: _dateTimeFromJson,
          toJson: _dateTimeToJson)
      required this.createdDate,
      @JsonKey(
          name: "bookmark_ids",
          fromJson: _bookmarkIdsFromJson,
          toJson: _bookmarkIdsToJson)
      required final List<String> bookmarkIds})
      : _bookmarkIds = bookmarkIds;
  factory _DailyReadHistory.fromJson(Map<String, dynamic> json) =>
      _$DailyReadHistoryFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(
      name: "created_date",
      fromJson: _dateTimeFromJson,
      toJson: _dateTimeToJson)
  final DateTime createdDate;
  final List<String> _bookmarkIds;
  @override
  @JsonKey(
      name: "bookmark_ids",
      fromJson: _bookmarkIdsFromJson,
      toJson: _bookmarkIdsToJson)
  List<String> get bookmarkIds {
    if (_bookmarkIds is EqualUnmodifiableListView) return _bookmarkIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bookmarkIds);
  }

  /// Create a copy of DailyReadHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DailyReadHistoryCopyWith<_DailyReadHistory> get copyWith =>
      __$DailyReadHistoryCopyWithImpl<_DailyReadHistory>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$DailyReadHistoryToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'DailyReadHistory'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('createdDate', createdDate))
      ..add(DiagnosticsProperty('bookmarkIds', bookmarkIds));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DailyReadHistory &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.createdDate, createdDate) ||
                other.createdDate == createdDate) &&
            const DeepCollectionEquality()
                .equals(other._bookmarkIds, _bookmarkIds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, createdDate,
      const DeepCollectionEquality().hash(_bookmarkIds));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DailyReadHistory(id: $id, createdDate: $createdDate, bookmarkIds: $bookmarkIds)';
  }
}

/// @nodoc
abstract mixin class _$DailyReadHistoryCopyWith<$Res>
    implements $DailyReadHistoryCopyWith<$Res> {
  factory _$DailyReadHistoryCopyWith(
          _DailyReadHistory value, $Res Function(_DailyReadHistory) _then) =
      __$DailyReadHistoryCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(
          name: "created_date",
          fromJson: _dateTimeFromJson,
          toJson: _dateTimeToJson)
      DateTime createdDate,
      @JsonKey(
          name: "bookmark_ids",
          fromJson: _bookmarkIdsFromJson,
          toJson: _bookmarkIdsToJson)
      List<String> bookmarkIds});
}

/// @nodoc
class __$DailyReadHistoryCopyWithImpl<$Res>
    implements _$DailyReadHistoryCopyWith<$Res> {
  __$DailyReadHistoryCopyWithImpl(this._self, this._then);

  final _DailyReadHistory _self;
  final $Res Function(_DailyReadHistory) _then;

  /// Create a copy of DailyReadHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? createdDate = null,
    Object? bookmarkIds = null,
  }) {
    return _then(_DailyReadHistory(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      createdDate: null == createdDate
          ? _self.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      bookmarkIds: null == bookmarkIds
          ? _self._bookmarkIds
          : bookmarkIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

// dart format on
