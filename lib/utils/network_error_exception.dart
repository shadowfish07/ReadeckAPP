class NetworkErrorException implements Exception {
  final String message;
  final Uri uri;
  final int? statusCode;

  const NetworkErrorException(this.message, this.uri, [this.statusCode]);

  @override
  String toString() {
    return "NetworkErrorException: $message, uri: $uri, statusCode: $statusCode";
  }
}
