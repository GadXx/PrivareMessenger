import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/chat_request.dart';
import 'models/otpk_request.dart';

class ChatApi {
  final String baseUrl;
  ChatApi(this.baseUrl);

  Future<ChatRequest> getKeyBundle(String id) async {
    final url = Uri.parse('$baseUrl/api/get-key-bundle/$id');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      print(response.body);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ChatRequest.fromJson(data);
    } else {
      throw Exception('Failed to get key bundle');
    }
  }

  Future<OtpkRequest> getOtpk(String idk) async {
    final url = Uri.parse('$baseUrl/api/get-one-time-pre-key?idk=${Uri.encodeComponent(idk)}');
    final response = await http.get(url);
    print(idk);
    if (response.statusCode == 200) {
      // Декодируем Map из json
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      print("ВСЕ ОК");
      return OtpkRequest.fromJson(data);
    } else {
      throw Exception('Failed to get otpk');
    }
  }
}