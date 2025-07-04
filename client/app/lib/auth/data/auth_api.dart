// lib/features/auth/data/auth_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/register_request.dart';

class AuthApi {
  final String baseUrl;
  AuthApi(this.baseUrl);

  Future<void> reservLogin(String login, String identityKey) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/pre-register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'login': login,
        'identity_key': identityKey,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Ошибка резервации логина: ${response.body}');
    }
  }

  Future<String> register(RegisterRequest req) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(req.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Ошибка регистрации: ${response.body}');
    }
    final body = jsonDecode(response.body);
    return body['user_id'] as String;
  }
}


