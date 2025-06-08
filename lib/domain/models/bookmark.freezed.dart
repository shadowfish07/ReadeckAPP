// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookmark.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Bookmark implements DiagnosticableTreeMixin {
  /// 书签唯一标识符
  String get id;

  /// 书签标题
  String get title;

  /// 书签URL地址
  String get url;

  /// 网站名称
  @JsonKey(name: 'site_name')
  String? get siteName;

  /// 书签描述
  String? get description;

  /// 创建时间
  DateTime get created;

  /// 是否已标记为喜爱
  @JsonKey(name: 'is_marked')
  bool get isMarked;

  /// 是否已归档
  @JsonKey(name: 'is_archived')
  bool get isArchived;

  /// 阅读进度（0-100）
  @JsonKey(name: 'read_progress')
  int get readProgress;

  /// 标签列表
  List<String> get labels;

  /// 图片URL
  @JsonKey(name: 'image_url')
  String? get imageUrl;

  /// Create a copy of Bookmark
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookmarkCopyWith<Bookmark> get copyWith =>
      _$BookmarkCopyWithImpl<Bookmark>(this as Bookmark, _$identity);

  /// Serializes this Bookmark to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'Bookmark'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('url', url))
      ..add(DiagnosticsProperty('siteName', siteName))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('created', created))
      ..add(DiagnosticsProperty('isMarked', isMarked))
      ..add(DiagnosticsProperty('isArchived', isArchived))
      ..add(DiagnosticsProperty('readProgress', readProgress))
      ..add(DiagnosticsProperty('labels', labels))
      ..add(DiagnosticsProperty('imageUrl', imageUrl));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Bookmark &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.siteName, siteName) ||
                other.siteName == siteName) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.created, created) || other.created == created) &&
            (identical(other.isMarked, isMarked) ||
                other.isMarked == isMarked) &&
            (identical(other.isArchived, isArchived) ||
                other.isArchived == isArchived) &&
            (identical(other.readProgress, readProgress) ||
                other.readProgress == readProgress) &&
            const DeepCollectionEquality().equals(other.labels, labels) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      url,
      siteName,
      description,
      created,
      isMarked,
      isArchived,
      readProgress,
      const DeepCollectionEquality().hash(labels),
      imageUrl);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Bookmark(id: $id, title: $title, url: $url, siteName: $siteName, description: $description, created: $created, isMarked: $isMarked, isArchived: $isArchived, readProgress: $readProgress, labels: $labels, imageUrl: $imageUrl)';
  }
}

/// @nodoc
abstract mixin class $BookmarkCopyWith<$Res> {
  factory $BookmarkCopyWith(Bookmark value, $Res Function(Bookmark) _then) =
      _$BookmarkCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String title,
      String url,
      @JsonKey(name: 'site_name') String? siteName,
      String? description,
      DateTime created,
      @JsonKey(name: 'is_marked') bool isMarked,
      @JsonKey(name: 'is_archived') bool isArchived,
      @JsonKey(name: 'read_progress') int readProgress,
      List<String> labels,
      @JsonKey(name: 'image_url') String? imageUrl});
}

/// @nodoc
class _$BookmarkCopyWithImpl<$Res> implements $BookmarkCopyWith<$Res> {
  _$BookmarkCopyWithImpl(this._self, this._then);

  final Bookmark _self;
  final $Res Function(Bookmark) _then;

  /// Create a copy of Bookmark
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? url = null,
    Object? siteName = freezed,
    Object? description = freezed,
    Object? created = null,
    Object? isMarked = null,
    Object? isArchived = null,
    Object? readProgress = null,
    Object? labels = null,
    Object? imageUrl = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      siteName: freezed == siteName
          ? _self.siteName
          : siteName // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      created: null == created
          ? _self.created
          : created // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isMarked: null == isMarked
          ? _self.isMarked
          : isMarked // ignore: cast_nullable_to_non_nullable
              as bool,
      isArchived: null == isArchived
          ? _self.isArchived
          : isArchived // ignore: cast_nullable_to_non_nullable
              as bool,
      readProgress: null == readProgress
          ? _self.readProgress
          : readProgress // ignore: cast_nullable_to_non_nullable
              as int,
      labels: null == labels
          ? _self.labels
          : labels // ignore: cast_nullable_to_non_nullable
              as List<String>,
      imageUrl: freezed == imageUrl
          ? _self.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _Bookmark with DiagnosticableTreeMixin implements Bookmark {
  const _Bookmark(
      {required this.id,
      required this.title,
      required this.url,
      @JsonKey(name: 'site_name') this.siteName,
      this.description,
      required this.created,
      @JsonKey(name: 'is_marked') required this.isMarked,
      @JsonKey(name: 'is_archived') required this.isArchived,
      @JsonKey(name: 'read_progress') required this.readProgress,
      required final List<String> labels,
      @JsonKey(name: 'image_url') this.imageUrl})
      : _labels = labels;
  factory _Bookmark.fromJson(Map<String, dynamic> json) =>
      _$BookmarkFromJson(json);

  /// 书签唯一标识符
  @override
  final String id;

  /// 书签标题
  @override
  final String title;

  /// 书签URL地址
  @override
  final String url;

  /// 网站名称
  @override
  @JsonKey(name: 'site_name')
  final String? siteName;

  /// 书签描述
  @override
  final String? description;

  /// 创建时间
  @override
  final DateTime created;

  /// 是否已标记为喜爱
  @override
  @JsonKey(name: 'is_marked')
  final bool isMarked;

  /// 是否已归档
  @override
  @JsonKey(name: 'is_archived')
  final bool isArchived;

  /// 阅读进度（0-100）
  @override
  @JsonKey(name: 'read_progress')
  final int readProgress;

  /// 标签列表
  final List<String> _labels;

  /// 标签列表
  @override
  List<String> get labels {
    if (_labels is EqualUnmodifiableListView) return _labels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_labels);
  }

  /// 图片URL
  @override
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  /// Create a copy of Bookmark
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BookmarkCopyWith<_Bookmark> get copyWith =>
      __$BookmarkCopyWithImpl<_Bookmark>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BookmarkToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'Bookmark'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('url', url))
      ..add(DiagnosticsProperty('siteName', siteName))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('created', created))
      ..add(DiagnosticsProperty('isMarked', isMarked))
      ..add(DiagnosticsProperty('isArchived', isArchived))
      ..add(DiagnosticsProperty('readProgress', readProgress))
      ..add(DiagnosticsProperty('labels', labels))
      ..add(DiagnosticsProperty('imageUrl', imageUrl));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Bookmark &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.siteName, siteName) ||
                other.siteName == siteName) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.created, created) || other.created == created) &&
            (identical(other.isMarked, isMarked) ||
                other.isMarked == isMarked) &&
            (identical(other.isArchived, isArchived) ||
                other.isArchived == isArchived) &&
            (identical(other.readProgress, readProgress) ||
                other.readProgress == readProgress) &&
            const DeepCollectionEquality().equals(other._labels, _labels) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      url,
      siteName,
      description,
      created,
      isMarked,
      isArchived,
      readProgress,
      const DeepCollectionEquality().hash(_labels),
      imageUrl);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Bookmark(id: $id, title: $title, url: $url, siteName: $siteName, description: $description, created: $created, isMarked: $isMarked, isArchived: $isArchived, readProgress: $readProgress, labels: $labels, imageUrl: $imageUrl)';
  }
}

/// @nodoc
abstract mixin class _$BookmarkCopyWith<$Res>
    implements $BookmarkCopyWith<$Res> {
  factory _$BookmarkCopyWith(_Bookmark value, $Res Function(_Bookmark) _then) =
      __$BookmarkCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String url,
      @JsonKey(name: 'site_name') String? siteName,
      String? description,
      DateTime created,
      @JsonKey(name: 'is_marked') bool isMarked,
      @JsonKey(name: 'is_archived') bool isArchived,
      @JsonKey(name: 'read_progress') int readProgress,
      List<String> labels,
      @JsonKey(name: 'image_url') String? imageUrl});
}

/// @nodoc
class __$BookmarkCopyWithImpl<$Res> implements _$BookmarkCopyWith<$Res> {
  __$BookmarkCopyWithImpl(this._self, this._then);

  final _Bookmark _self;
  final $Res Function(_Bookmark) _then;

  /// Create a copy of Bookmark
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? url = null,
    Object? siteName = freezed,
    Object? description = freezed,
    Object? created = null,
    Object? isMarked = null,
    Object? isArchived = null,
    Object? readProgress = null,
    Object? labels = null,
    Object? imageUrl = freezed,
  }) {
    return _then(_Bookmark(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      siteName: freezed == siteName
          ? _self.siteName
          : siteName // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      created: null == created
          ? _self.created
          : created // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isMarked: null == isMarked
          ? _self.isMarked
          : isMarked // ignore: cast_nullable_to_non_nullable
              as bool,
      isArchived: null == isArchived
          ? _self.isArchived
          : isArchived // ignore: cast_nullable_to_non_nullable
              as bool,
      readProgress: null == readProgress
          ? _self.readProgress
          : readProgress // ignore: cast_nullable_to_non_nullable
              as int,
      labels: null == labels
          ? _self._labels
          : labels // ignore: cast_nullable_to_non_nullable
              as List<String>,
      imageUrl: freezed == imageUrl
          ? _self.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
