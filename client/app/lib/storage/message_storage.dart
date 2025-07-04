// lib/features/auth/storage/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageMessages {
  final _storage = const FlutterSecureStorage();
  static const _prefix = 'chat_';

  Future<void> write(String id, String value) =>
      _storage.write(key: _prefix + id, value: value);

  Future<String?> read(String id) =>
      _storage.read(key: _prefix + id);

  Future<void> delete(String id) =>
      _storage.delete(key: _prefix + id);
}
