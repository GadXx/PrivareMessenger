import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:app/storage/secure_storage.dart';
import '../utils/sign_util.dart';
import 'package:cryptography/cryptography.dart';
import 'package:app/messenger/utils/chat_util.dart';
import 'package:app/storage/message_storage.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  Timer? _prekeysTimer;
  StreamController<dynamic>? _broadcastController;

  /// Получить broadcast stream (можно подписываться где угодно)
  Stream<dynamic>? get stream => _broadcastController?.stream;

  /// Подключение к WebSocket
  Future<void> connect() async {
    print('=> Подключаемся к WS...');
    if (_channel != null) return;

    // Пересоздаём broadcast controller на каждый connect
    await _broadcastController?.close();
    _broadcastController = StreamController<dynamic>.broadcast();

    final storageKey = SecureStorageKeys();
    final idPub = await storageKey.read('identityPublic');
    final nonce = DateTime.now().millisecondsSinceEpoch.toString();
    final signature = await signNonce(nonce);

    _channel = WebSocketChannel.connect(Uri.parse('ws://192.168.0.105:8080/ws'));
    _channel!.sink.add(jsonEncode({
      'type': 'auth',
      'identity_key': idPub,
      'nonce': nonce,
      'signature': signature,
    }));

    _channel!.stream.listen(
      (data) {
        _handleIncomingMessage(data);
        // Проверяем, не закрыт ли контроллер
        if (!(_broadcastController?.isClosed ?? true)) {
          _broadcastController?.add(data);
        }
      },
      onDone: () {
        print("=> WS канал закрыт");
        // Можно реализовать автоматическое переподключение здесь
      },
      onError: (e) {
        print("=> Ошибка в WS:");
        if (!(_broadcastController?.isClosed ?? true)) {
          _broadcastController?.addError(e);
        }
      },
      cancelOnError: false,
    );
    _startPreKeysTimer();
  }

  void _startPreKeysTimer() {
    print('=> Старт проверки одноразовых ключей!');
    _prekeysTimer?.cancel();
    send({"type": "check_prekeys"});
    _prekeysTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      print('=> Проверяем одноразовые ключи!');
      send({"type": "check_prekeys"});
    });
  }

  Future<void> _handleIncomingMessage(dynamic data) async {
    print('=> Пришло сообщение: $data');
    final msg = jsonDecode(data);
    final type = msg['type'];
    if (type == 'message') {
      print('=== ПОЛУЧЕНИЕ СООБЩЕНИЯ ===');
      print('msg[from]: ${msg['from']}');
      print('msg[ephemeral_pub]: ${msg['ephemeral_pub']}');
      print('msg[otpk_id]: ${msg['otpk_id']}');
      print('msg[content]: ${msg['content']}');

      final plaintext = await receivingMessage(msg['from'], msg['ephemeral_pub'], msg['otpk_id'], msg['content']);

      print('Расшифрованное сообщение: $plaintext');
    }
    else if (type == 'need_more_prekeys') {
      final needed = msg['needed'] ?? 100;
      print("Сервер просит $needed pre-keys");

      // Сгенерируй pre-keys
      final newKeys = await generatePreKeys(needed);

      // Отправь их на сервер
      send({
        "type": "add_prekeys",
        "keys": newKeys.map((e) => e["publicKey"]).toList(),
        "id": newKeys.map((e) => e["id"]).toList(),
      });
    } else if (type == 'prekeys_count') {
      print('=> Сервер вернул количество prekeys: ${msg['count']}');
      // Тут можно обновить UI, вызвать callback и т.д.
    }
    // Можно обрабатывать другие типы сообщений!
  }

  // Генерация одноразовых prekeys (только публичные части!)
  Future<List<Map<String, dynamic>>> generatePreKeys(int count) async {
    final algorithm = X25519(); // !!!
    List<Map<String, dynamic>> keys = [];
    for (int i = 0; i < count; i++) {
      final keyPair = await algorithm.newKeyPair();
      final pubKeyBytes = (await keyPair.extract()).publicKey.bytes;
      final privKeyBytes = await keyPair.extractPrivateKeyBytes();

      final keyId = (DateTime.now().millisecondsSinceEpoch + i).toString();

      final storageKey = SecureStorageKeys();
      await storageKey.write('prekey_$keyId', base64Encode(privKeyBytes));
      await storageKey.write('prekey_public_$keyId', base64Encode(pubKeyBytes));
      keys.add({
        "id": keyId,
        "publicKey": base64Encode(pubKeyBytes),
      });
    }
    return keys;
  }

  void send(dynamic msg) {
    print('=> Отправка в сокет: $msg');
    _channel?.sink.add(jsonEncode(msg));
  }

  /// Отключение и закрытие контроллера
  void disconnect() {
    print('=> Отключаемся от WS...');
    _prekeysTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _channel = null;
    _broadcastController?.close();
    _broadcastController = null;
  }
}
