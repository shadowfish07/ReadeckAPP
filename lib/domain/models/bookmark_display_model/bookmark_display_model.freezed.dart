// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookmark_display_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookmarkDisplayModel {
  Bookmark get bookmark;
  ReadingStatsForView? get stats;

  /// Create a copy of BookmarkDisplayModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookmarkDisplayModelCopyWith<BookmarkDisplayModel> get copyWith =>
      _$BookmarkDisplayModelCopyWithImpl<BookmarkDisplayModel>(
          this as BookmarkDisplayModel, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookmarkDisplayModel &&
            (identical(other.bookmark, bookmark) ||
                other.bookmark == bookmark) &&
            (identical(other.stats, stats) || other.stats == stats));
  }

  @override
  int get hashCode => Object.hash(runtimeType, bookmark, stats);

  @override
  String toString() {
    return 'BookmarkDisplayModel(bookmark: $bookmark, stats: $stats)';
  }
}

/// @nodoc
abstract mixin class $BookmarkDisplayModelCopyWith<$Res> {
  factory $BookmarkDisplayModelCopyWith(BookmarkDisplayModel value,
          $Res Function(BookmarkDisplayModel) _then) =
      _$BookmarkDisplayModelCopyWithImpl;
  @useResult
  $Res call({Bookmark bookmark, ReadingStatsForView? stats});

  $BookmarkCopyWith<$Res> get bookmark;
}

/// @nodoc
class _$BookmarkDisplayModelCopyWithImpl<$Res>
    implements $BookmarkDisplayModelCopyWith<$Res> {
  _$BookmarkDisplayModelCopyWithImpl(this._self, this._then);

  final BookmarkDisplayModel _self;
  final $Res Function(BookmarkDisplayModel) _then;

  /// Create a copy of BookmarkDisplayModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bookmark = null,
    Object? stats = freezed,
  }) {
    return _then(_self.copyWith(
      bookmark: null == bookmark
          ? _self.bookmark
          : bookmark // ignore: cast_nullable_to_non_nullable
              as Bookmark,
      stats: freezed == stats
          ? _self.stats
          : stats // ignore: cast_nullable_to_non_nullable
              as ReadingStatsForView?,
    ));
  }

  /// Create a copy of BookmarkDisplayModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BookmarkCopyWith<$Res> get bookmark {
    return $BookmarkCopyWith<$Res>(_self.bookmark, (value) {
      return _then(_self.copyWith(bookmark: value));
    });
  }
}

/// @nodoc

class _BookmarkDisplayModel implements BookmarkDisplayModel {
  _BookmarkDisplayModel({required this.bookmark, this.stats});

  @override
  final Bookmark bookmark;
  @override
  final ReadingStatsForView? stats;

  /// Create a copy of BookmarkDisplayModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BookmarkDisplayModelCopyWith<_BookmarkDisplayModel> get copyWith =>
      __$BookmarkDisplayModelCopyWithImpl<_BookmarkDisplayModel>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BookmarkDisplayModel &&
            (identical(other.bookmark, bookmark) ||
                other.bookmark == bookmark) &&
            (identical(other.stats, stats) || other.stats == stats));
  }

  @override
  int get hashCode => Object.hash(runtimeType, bookmark, stats);

  @override
  String toString() {
    return 'BookmarkDisplayModel(bookmark: $bookmark, stats: $stats)';
  }
}

/// @nodoc
abstract mixin class _$BookmarkDisplayModelCopyWith<$Res>
    implements $BookmarkDisplayModelCopyWith<$Res> {
  factory _$BookmarkDisplayModelCopyWith(_BookmarkDisplayModel value,
          $Res Function(_BookmarkDisplayModel) _then) =
      __$BookmarkDisplayModelCopyWithImpl;
  @override
  @useResult
  $Res call({Bookmark bookmark, ReadingStatsForView? stats});

  @override
  $BookmarkCopyWith<$Res> get bookmark;
}

/// @nodoc
class __$BookmarkDisplayModelCopyWithImpl<$Res>
    implements _$BookmarkDisplayModelCopyWith<$Res> {
  __$BookmarkDisplayModelCopyWithImpl(this._self, this._then);

  final _BookmarkDisplayModel _self;
  final $Res Function(_BookmarkDisplayModel) _then;

  /// Create a copy of BookmarkDisplayModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? bookmark = null,
    Object? stats = freezed,
  }) {
    return _then(_BookmarkDisplayModel(
      bookmark: null == bookmark
          ? _self.bookmark
          : bookmark // ignore: cast_nullable_to_non_nullable
              as Bookmark,
      stats: freezed == stats
          ? _self.stats
          : stats // ignore: cast_nullable_to_non_nullable
              as ReadingStatsForView?,
    ));
  }

  /// Create a copy of BookmarkDisplayModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BookmarkCopyWith<$Res> get bookmark {
    return $BookmarkCopyWith<$Res>(_self.bookmark, (value) {
      return _then(_self.copyWith(bookmark: value));
    });
  }
}

// dart format on
