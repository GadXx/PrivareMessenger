// lib/features/auth/domain/auth_repository.dart
import '../data/auth_api.dart';
import '../data/models/register_request.dart';

class AuthRepository {
  final AuthApi api;
  AuthRepository(this.api);

  Future<void> reservLogin(String login, String identityKey) {
    return api.reservLogin(login, identityKey);
  }

  Future<String> register(RegisterRequest req) {
    return api.register(req);
  }
}
