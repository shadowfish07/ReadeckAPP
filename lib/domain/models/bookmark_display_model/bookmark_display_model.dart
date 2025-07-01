import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';

part 'bookmark_display_model.freezed.dart';

@freezed
abstract class BookmarkDisplayModel with _$BookmarkDisplayModel {
  factory BookmarkDisplayModel({
    required Bookmark bookmark,
    ReadingStatsForView? stats,
  }) = _BookmarkDisplayModel;
}
