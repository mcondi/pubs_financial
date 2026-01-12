class ApiAuthException implements Exception {
  final String message;
  const ApiAuthException(this.message);
  @override
  String toString() => message;

  static const invalidCredentials = ApiAuthException('Invalid username or password.');
  static const sessionExpired = ApiAuthException('Your session has expired. Please log in again.');
}

class ApiHttpException implements Exception {
  final int statusCode;
  final String message;
  const ApiHttpException({required this.statusCode, required this.message});
  @override
  String toString() => 'Server error ($statusCode): $message';
}
