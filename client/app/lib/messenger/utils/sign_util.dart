import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:app/storage/secure_storage.dart';

Future<String> signNonce(String nonce) async {
  final storage = SecureStorageKeys();
  final privB64 = await storage.read('identityPrivate');
  final pubB64 = await storage.read('identityPublic');
  if (privB64 == null || pubB64 == null) {
    throw Exception('Нет приватного или публичного ключа');
  }

  final privBytes = base64Decode(privB64);
  final pubBytes = base64Decode(pubB64);

  // Воссоздай ключ, но укажи тип Ed25519!
  final keyPair = SimpleKeyPairData(
    privBytes,
    publicKey: SimplePublicKey(pubBytes, type: KeyPairType.ed25519),
    type: KeyPairType.ed25519,
  );

  final signature = await Ed25519().sign(
    utf8.encode(nonce),
    keyPair: keyPair,
  );

  return base64Encode(signature.bytes);
}
