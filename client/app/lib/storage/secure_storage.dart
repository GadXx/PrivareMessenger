// lib/features/auth/storage/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageKeys {
  final _storage = const FlutterSecureStorage();
  static const _prefix = 'signal_';

  Future<void> write(String key, String value) =>
      _storage.write(key: _prefix + key, value: value);

  Future<String?> read(String key) =>
      _storage.read(key: _prefix + key);

  Future<void> delete(String key) =>
      _storage.delete(key: _prefix + key);
}
