
import 'dart:convert';
import 'package:app/storage/message_storage.dart';
import 'package:cryptography/cryptography.dart';
import 'package:app/messenger/data/models/chat_request.dart';
import 'package:app/storage/secure_storage.dart';
import 'package:app/messenger/data/ws_service.dart';
import 'package:app/messenger/core/signal_core.dart';
import 'package:app/messenger/domain/chat_repository.dart';
import 'package:app/messenger/data/chat_api.dart';


Future<String> sendFirstMessage(
  String message,
  String chatId, 
  ChatRequest bundle
  ) async {

  final repo = ChatRepository(ChatApi('http://192.168.0.105:8080'));
  final storage = SecureStorageKeys();

  // 1. Получаем Ed25519 seed отправителя (используем как seed для X25519 identity)
  final senderIdentityPrivateXB64 = await storage.read('xIdentityPrivate');

  final senderIdentitySeed = base64Decode(senderIdentityPrivateXB64!);

  // 2. Создаем X25519 identity отправителя из seed
  final senderIdentityKeyPairX = await X25519().newKeyPairFromSeed(senderIdentitySeed);
  final senderIdentityPublicX = await senderIdentityKeyPairX.extractPublicKey();
  print('=== ОТПРАВКА СООБЩЕНИЯ ===');
  print('X25519 identity private: ${base64Encode(await senderIdentityKeyPairX.extractPrivateKeyBytes())}');
  print('X25519 identity public:  ${base64Encode(senderIdentityPublicX.bytes)}');

  // 3. КОНВЕРТАЦИЯ identityKey ПОЛУЧАТЕЛЯ: Ed25519 seed -> X25519 public key
  final receiverIdentityXB64 = bundle.xIdentityKey; // Ed25519 public key (32 байта)
  final receiverIdentityEdBytes = base64Decode(receiverIdentityXB64);
  final receiverIdentityPub = SimplePublicKey(
    receiverIdentityEdBytes,
    type: KeyPairType.x25519,
  );

  // 4. SignedPreKey и OTPK приходят уже в X25519 формате (или тоже преобразуй, если Ed25519!)
  final receiverSignedPrePubBytes = base64Decode(bundle.signedPreKey); // X25519
  final receiverSignedPrePub = SimplePublicKey(
    receiverSignedPrePubBytes,
    type: KeyPairType.x25519,
  );

  SimplePublicKey? receiverOtpkPub;
  String? otpkId;

  final receiverIdentityEdB64 = bundle.identityKey;
  final otpkResponse = await repo.getOtpk(receiverIdentityEdB64);
  if (otpkResponse != null) {
    receiverOtpkPub = SimplePublicKey(
      base64Decode(otpkResponse.key),
      type: KeyPairType.x25519,
    );
    otpkId = otpkResponse.keyId;
    print('receiverOtpkPub: $receiverOtpkPub, otpkId: $otpkId');
  }

  // 6. Генерация ephemeral ключа
  final senderEphemeralKeyPair = await X25519().newKeyPair();
  final ephemeralPublicKey = await senderEphemeralKeyPair.extractPublicKey();
  final ephemeralPubBytes = ephemeralPublicKey.bytes;
  print('ephemeralPubBytes: ${base64Encode(ephemeralPubBytes)}');
  print('ephemeralPrivate: ${base64Encode(await senderEphemeralKeyPair.extractPrivateKeyBytes())}');

  // 7. Вычисляем общий секрет
  final sharedSecret = await SignalCore.senderComputeSharedSecret(
    senderIdentityKeyPair: senderIdentityKeyPairX,
    receiverIdentityPub: receiverIdentityPub,
    receiverSignedPreKeyPub: receiverSignedPrePub,
    receiverOneTimePreKeyPub: receiverOtpkPub,
    senderEphemeralKeyPair: senderEphemeralKeyPair,
  );
  print("SENDER SHARED SECRET: ${base64Encode(sharedSecret)}");

  // 8. Шифруем сообщение
  final encryptedMessage = await SignalCore.encryptMessage(sharedSecret, message);

  // 9. Отправляем через WebSocket
  final ws = WebSocketService();
  ws.send({
    'type': 'message',
    'from': base64Encode(senderIdentityPublicX.bytes),
    'receiver_id': bundle.identityKey, // или receiverIdentityPubX (если нужно в X25519 формате)
    'content': encryptedMessage,
    'ephemeral_pub': base64Encode(ephemeralPubBytes),
    'otpk_id': otpkId,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });

  print('=== ОТПРАВЛЕНО СООБЩЕНИЕ ===');
  print('receiver_id: ${receiverIdentityEdB64}');
  print('content: $encryptedMessage');
  print('ephemeral_pub: ${base64Encode(ephemeralPubBytes)}');
  print('otpk_id: $otpkId');
  print('timestamp: ${DateTime.now().millisecondsSinceEpoch}');

  return encryptedMessage;
}

Future<String> receivingMessage(
  String from,
  String ephemeralPub,
  String otpkId,
  String content
  ) async {
    final storage = SecureStorageKeys();
    final identityPrivateB64   = await storage.read('identityPrivate');   // Ed25519 seed
    final signedPrePrivateB64  = await storage.read('signedPrePrivate');  // X25519 private
    final signedPrePublicB64   = await storage.read('signedPrePublic');   // X25519 public
    final otpkPrivateB64       = otpkId != null ? await storage.read('prekey_$otpkId') : null;      // X25519 private
    final otpkPublicB64        = otpkId != null ? await storage.read('prekey_public_$otpkId') : null; // X25519 public

    print('identityPrivateB64: $identityPrivateB64');
    print('signedPrePrivateB64: $signedPrePrivateB64');
    print('signedPrePublicB64:  $signedPrePublicB64');
    print('otpkPrivateB64:      $otpkPrivateB64');
    print('otpkPublicB64:       $otpkPublicB64');

    // Проверка на null
    if (identityPrivateB64 == null ||
        signedPrePrivateB64 == null ||
        signedPrePublicB64 == null) {
      throw Exception("No keys in storage!");
    }

    // 1. Преобразуем Ed25519 seed из стораджа в X25519 identityKeyPair
    final recipientIdentitySeed = base64Decode(identityPrivateB64);
    final recipientIdentityKeyPairX = await X25519().newKeyPairFromSeed(recipientIdentitySeed);

    final recipientIdentityPrivateX = await recipientIdentityKeyPairX.extractPrivateKeyBytes();
    final recipientIdentityPublicX  = await recipientIdentityKeyPairX.extractPublicKey();

    final identityPrivate = SimpleKeyPairData(
      recipientIdentityPrivateX,
      publicKey: SimplePublicKey(recipientIdentityPublicX.bytes, type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );

    final signedPrePrivate = SimpleKeyPairData(
      base64Decode(signedPrePrivateB64),
      publicKey: SimplePublicKey(
        base64Decode(signedPrePublicB64),
        type: KeyPairType.x25519,
      ),
      type: KeyPairType.x25519,
    );

    SimpleKeyPairData? otpkPrivate;
    if (otpkPrivateB64 != null && otpkPublicB64 != null) {
      otpkPrivate = SimpleKeyPairData(
        base64Decode(otpkPrivateB64),
        publicKey: SimplePublicKey(
          base64Decode(otpkPublicB64),
          type: KeyPairType.x25519,
        ),
        type: KeyPairType.x25519,
      );
    }

    final senderIdentityPub = SimplePublicKey(
      base64Decode(from),
      type: KeyPairType.x25519,
    );
    final senderEphemeralPub = SimplePublicKey(
      base64Decode(ephemeralPub),
      type: KeyPairType.x25519,
    );

    // 2. DH + расшифровка
    final sharedSecret = await SignalCore.receiverComputeSharedSecret(
      receiverIdentityKeyPair: identityPrivate,
      receiverSignedPreKeyPair: signedPrePrivate,
      senderIdentityPub: senderIdentityPub,
      senderEphemeralPub: senderEphemeralPub,
      receiverOneTimePreKeyPair: otpkPrivate,
    );
    print("RECEIVER SHARED SECRET: ${base64Encode(sharedSecret)}");

    final plaintext = await SignalCore.decryptMessage(
      sharedSecret,
      content,
    );

    print('Расшифрованное сообщение: $plaintext');

    return plaintext;
}