class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized {
    final lower = message.toLowerCase();
    return statusCode == 401 ||
        statusCode == 403 ||
        lower.contains('token') ||
        lower.contains('unauthorized') ||
        lower.contains('yetkisiz') ||
        lower.contains('oturum');
  }

  @override
  String toString() => message;
}
