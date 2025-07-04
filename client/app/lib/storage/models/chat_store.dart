import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class ChatSessionState {
  final String chatId;
  final List<int> rootKey;            // основной секрет
  final List<int> sendingChainKey;    // цепочка для отправки сообщений
  final List<int> receivingChainKey;  // цепочка для приёма сообщений
  final SimpleKeyPair myRatchetKey;   // твой DH-пар ключ для ratchet
  final SimplePublicKey theirRatchetPub; // текущий публичный DH-ключ собеседника
  final int sendCount;
  final int recvCount;

  ChatSessionState({
    required this.chatId,
    required this.rootKey,
    required this.sendingChainKey,
    required this.receivingChainKey,
    required this.myRatchetKey,
    required this.theirRatchetPub,
    required this.sendCount,
    required this.recvCount,
  });

  // сериализация/десериализация для хранения
  Future<Map<String, dynamic>> toJsonAsync() async {
    final privBytes = await myRatchetKey.extractPrivateKeyBytes();
    final pubData = await myRatchetKey.extract();
    return {
      'chatId': chatId,
      'rootKey': base64Encode(rootKey),
      'sendingChainKey': base64Encode(sendingChainKey),
      'receivingChainKey': base64Encode(receivingChainKey),
      'myRatchetPrivate': base64Encode(privBytes),
      'myRatchetPublic': base64Encode(pubData.publicKey.bytes),
      'theirRatchetPub': base64Encode(theirRatchetPub.bytes),
      'sendCount': sendCount,
      'recvCount': recvCount,
    };
  }
}
