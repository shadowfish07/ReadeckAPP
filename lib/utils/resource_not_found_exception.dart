class ResourceNotFoundException implements Exception {
  final String message;

  const ResourceNotFoundException(this.message);

  @override
  String toString() {
    Object? message = this.message;
    return "Exception: $message";
  }
}
