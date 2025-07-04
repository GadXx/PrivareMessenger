import 'package:app/messenger/data/chat_api.dart';
import 'package:app/messenger/data/models/chat_request.dart';
import 'package:app/messenger/data/models/otpk_request.dart';

class ChatRepository {
  final ChatApi api;
  ChatRepository(this.api);

  Future<ChatRequest> getKeyBundle(String id) {
    return api.getKeyBundle(id);
  }

  Future<OtpkRequest> getOtpk(String idk) {
    return api.getOtpk(idk);
  }
}