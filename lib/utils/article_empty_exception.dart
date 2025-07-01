class ArticleEmptyException implements Exception {
  final String? message;

  const ArticleEmptyException([this.message]);

  @override
  String toString() {
    return message ?? '文章内容为空，可能是提取过程出错';
  }
}
