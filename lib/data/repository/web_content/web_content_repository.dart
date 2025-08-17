import 'package:readeck_app/data/service/web_content_service.dart';
import 'package:result_dart/result_dart.dart';

/// Repository interface for web content fetching
/// Follows the Repository pattern to separate business logic from data sources
abstract class WebContentRepository {
  /// Fetches web content including title and content from the given URL
  ///
  /// [url] - The URL to fetch content from
  /// [timeout] - Request timeout duration, defaults to 10 seconds
  ///
  /// Returns a [Result] containing [WebContent] on success, or an exception on failure
  AsyncResult<WebContent> fetchWebContent(
    String url, {
    Duration timeout = const Duration(seconds: 10),
  });

  /// Dispose resources
  void dispose();
}

/// Implementation of WebContentRepository using WebContentService
class WebContentRepositoryImpl implements WebContentRepository {
  WebContentRepositoryImpl(this._webContentService);

  final WebContentService _webContentService;

  @override
  AsyncResult<WebContent> fetchWebContent(
    String url, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    return _webContentService.fetchWebContent(url, timeout: timeout);
  }

  @override
  void dispose() {
    _webContentService.dispose();
  }
}
