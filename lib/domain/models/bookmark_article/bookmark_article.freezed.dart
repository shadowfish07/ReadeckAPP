// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookmark_article.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookmarkArticle implements DiagnosticableTreeMixin {
  /// 文章缓存唯一标识符
  int? get id;

  /// 关联的书签ID
  @JsonKey(name: 'bookmark_id')
  String get bookmarkId;

  /// 文章内容
  String get article;

  /// 翻译内容
  String? get translate;

  /// 创建时间
  @JsonKey(name: 'created_date')
  DateTime get createdDate;

  /// Create a copy of BookmarkArticle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookmarkArticleCopyWith<BookmarkArticle> get copyWith =>
      _$BookmarkArticleCopyWithImpl<BookmarkArticle>(
          this as BookmarkArticle, _$identity);

  /// Serializes this BookmarkArticle to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'BookmarkArticle'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('bookmarkId', bookmarkId))
      ..add(DiagnosticsProperty('article', article))
      ..add(DiagnosticsProperty('translate', translate))
      ..add(DiagnosticsProperty('createdDate', createdDate));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookmarkArticle &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookmarkId, bookmarkId) ||
                other.bookmarkId == bookmarkId) &&
            (identical(other.article, article) || other.article == article) &&
            (identical(other.translate, translate) ||
                other.translate == translate) &&
            (identical(other.createdDate, createdDate) ||
                other.createdDate == createdDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, bookmarkId, article, translate, createdDate);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'BookmarkArticle(id: $id, bookmarkId: $bookmarkId, article: $article, translate: $translate, createdDate: $createdDate)';
  }
}

/// @nodoc
abstract mixin class $BookmarkArticleCopyWith<$Res> {
  factory $BookmarkArticleCopyWith(
          BookmarkArticle value, $Res Function(BookmarkArticle) _then) =
      _$BookmarkArticleCopyWithImpl;
  @useResult
  $Res call(
      {int? id,
      @JsonKey(name: 'bookmark_id') String bookmarkId,
      String article,
      String? translate,
      @JsonKey(name: 'created_date') DateTime createdDate});
}

/// @nodoc
class _$BookmarkArticleCopyWithImpl<$Res>
    implements $BookmarkArticleCopyWith<$Res> {
  _$BookmarkArticleCopyWithImpl(this._self, this._then);

  final BookmarkArticle _self;
  final $Res Function(BookmarkArticle) _then;

  /// Create a copy of BookmarkArticle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? bookmarkId = null,
    Object? article = null,
    Object? translate = freezed,
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
      article: null == article
          ? _self.article
          : article // ignore: cast_nullable_to_non_nullable
              as String,
      translate: freezed == translate
          ? _self.translate
          : translate // ignore: cast_nullable_to_non_nullable
              as String?,
      createdDate: null == createdDate
          ? _self.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _BookmarkArticle with DiagnosticableTreeMixin implements BookmarkArticle {
  const _BookmarkArticle(
      {this.id,
      @JsonKey(name: 'bookmark_id') required this.bookmarkId,
      required this.article,
      this.translate,
      @JsonKey(name: 'created_date') required this.createdDate});
  factory _BookmarkArticle.fromJson(Map<String, dynamic> json) =>
      _$BookmarkArticleFromJson(json);

  /// 文章缓存唯一标识符
  @override
  final int? id;

  /// 关联的书签ID
  @override
  @JsonKey(name: 'bookmark_id')
  final String bookmarkId;

  /// 文章内容
  @override
  final String article;

  /// 翻译内容
  @override
  final String? translate;

  /// 创建时间
  @override
  @JsonKey(name: 'created_date')
  final DateTime createdDate;

  /// Create a copy of BookmarkArticle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BookmarkArticleCopyWith<_BookmarkArticle> get copyWith =>
      __$BookmarkArticleCopyWithImpl<_BookmarkArticle>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BookmarkArticleToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'BookmarkArticle'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('bookmarkId', bookmarkId))
      ..add(DiagnosticsProperty('article', article))
      ..add(DiagnosticsProperty('translate', translate))
      ..add(DiagnosticsProperty('createdDate', createdDate));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BookmarkArticle &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookmarkId, bookmarkId) ||
                other.bookmarkId == bookmarkId) &&
            (identical(other.article, article) || other.article == article) &&
            (identical(other.translate, translate) ||
                other.translate == translate) &&
            (identical(other.createdDate, createdDate) ||
                other.createdDate == createdDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, bookmarkId, article, translate, createdDate);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'BookmarkArticle(id: $id, bookmarkId: $bookmarkId, article: $article, translate: $translate, createdDate: $createdDate)';
  }
}

/// @nodoc
abstract mixin class _$BookmarkArticleCopyWith<$Res>
    implements $BookmarkArticleCopyWith<$Res> {
  factory _$BookmarkArticleCopyWith(
          _BookmarkArticle value, $Res Function(_BookmarkArticle) _then) =
      __$BookmarkArticleCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int? id,
      @JsonKey(name: 'bookmark_id') String bookmarkId,
      String article,
      String? translate,
      @JsonKey(name: 'created_date') DateTime createdDate});
}

/// @nodoc
class __$BookmarkArticleCopyWithImpl<$Res>
    implements _$BookmarkArticleCopyWith<$Res> {
  __$BookmarkArticleCopyWithImpl(this._self, this._then);

  final _BookmarkArticle _self;
  final $Res Function(_BookmarkArticle) _then;

  /// Create a copy of BookmarkArticle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = freezed,
    Object? bookmarkId = null,
    Object? article = null,
    Object? translate = freezed,
    Object? createdDate = null,
  }) {
    return _then(_BookmarkArticle(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      bookmarkId: null == bookmarkId
          ? _self.bookmarkId
          : bookmarkId // ignore: cast_nullable_to_non_nullable
              as String,
      article: null == article
          ? _self.article
          : article // ignore: cast_nullable_to_non_nullable
              as String,
      translate: freezed == translate
          ? _self.translate
          : translate // ignore: cast_nullable_to_non_nullable
              as String?,
      createdDate: null == createdDate
          ? _self.createdDate
          : createdDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
