// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'label_info.freezed.dart';
part 'label_info.g.dart';

@freezed
abstract class LabelInfo with _$LabelInfo {
  const factory LabelInfo({
    /// 标签名称
    required String name,

    /// 具有此标签的书签数量
    required int count,

    /// 标签信息链接
    required String href,

    /// 具有此标签的书签链接
    @JsonKey(name: 'href_bookmarks') required String hrefBookmarks,
  }) = _LabelInfo;

  factory LabelInfo.fromJson(Map<String, Object?> json) =>
      _$LabelInfoFromJson(json);
}
