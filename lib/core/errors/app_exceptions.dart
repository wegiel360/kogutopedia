class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException($code): $message';
}

class DatabaseException extends AppException {
  const DatabaseException(String message, {String? code})
      : super(message, code: code);
}

class MediaException extends AppException {
  const MediaException(String message, {String? code})
      : super(message, code: code);
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException(String permission)
      : super('Brak uprawnienia: $permission', code: 'PERMISSION_DENIED');
}

class StorageException extends AppException {
  const StorageException(String message, {String? code})
      : super(message, code: code);
}
