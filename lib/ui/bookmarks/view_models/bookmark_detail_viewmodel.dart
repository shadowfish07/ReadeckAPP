import 'package:flutter/foundation.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:logger/logger.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';

class BookmarkDetailViewModel extends ChangeNotifier {
  BookmarkDetailViewModel(
      this._readeckApiClient, this._bookmarkRepository, this.bookmark) {
    loadArticleContent = Command.createAsync<void, String>(_loadArticleContent,
        initialValue: '', includeLastResultInCommandResults: true)
      ..execute();

    updateReadProgressCommand = Command.createSync<int, int>((s) => s,
        initialValue: 0)
      ..debounce(const Duration(milliseconds: 500)).listen((readProgress, _) {
        _updateReadProgress(readProgress);
      });
  }

  final _log = Logger();
  final ReadeckApiClient _readeckApiClient;
  final BookmarkRepository _bookmarkRepository;
  final Bookmark bookmark;

  late Command<void, String> loadArticleContent;
  late Command<int, void> updateReadProgressCommand;

  String get articleHtml => loadArticleContent.value;
  bool get isLoading => loadArticleContent.isExecuting.value;
  Exception? get error {
    final commandError = loadArticleContent.errors.value?.error;
    if (commandError is Exception) {
      return commandError;
    } else if (commandError != null) {
      return Exception(commandError.toString());
    }
    return null;
  }

  Future<String> _loadArticleContent(void _) async {
    try {
      _log.d('Loading article content for bookmark: ${bookmark.id}');

      final result = await _readeckApiClient.getBookmarkArticle(bookmark.id);

      if (result.isSuccess()) {
        final htmlContent = result.getOrThrow();
        _log.d(
            'Successfully loaded article content, length: ${htmlContent.length}');
        return htmlContent;
      } else {
        final error = result.exceptionOrNull();
        _log.e('Failed to load article content: $error');
        throw error ?? Exception('Unknown error occurred');
      }
    } catch (e) {
      _log.e('Exception while loading article content: $e');
      rethrow;
    }
  }

  void retry() {
    loadArticleContent.execute();
  }

  Future<void> _updateReadProgress(int readProgress) async {
    try {
      _log.d(
          'Updating read progress for bookmark: ${bookmark.id}, progress: $readProgress');

      final result = await _bookmarkRepository.updateReadProgress(
          bookmark.id, readProgress);

      if (result.isSuccess()) {
        _log.d('Successfully updated read progress');
      } else {
        final error = result.exceptionOrNull();
        _log.e('Failed to update read progress: $error');
        throw error ?? Exception('Failed to update read progress');
      }
    } catch (e) {
      _log.e('Exception while updating read progress: $e');
      rethrow;
    }
  }
}
