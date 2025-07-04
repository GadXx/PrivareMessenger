import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class SimpleKeyUtil {
  static Future<Map<String, String>> generateAllKeys() async {
    // Генерируем identity как Ed25519 (универсальный)
    final edIdentity = await Ed25519().newKeyPair();
    final edIdentityData = await edIdentity.extract();
    final edIdentityPrivate = edIdentityData.bytes; // 32 байта
    final edIdentityPublic = edIdentityData.publicKey.bytes; // 32 байта

    final xIdentityKeyPair = await X25519().newKeyPairFromSeed(edIdentityPrivate);
    final xIdentityData = await xIdentityKeyPair.extract();
    final xIdentityPrivate = await xIdentityKeyPair.extractPrivateKeyBytes();
    final xIdentityPublic = xIdentityData.publicKey.bytes;

    // Для DH: используем эти же байты, но как X25519!
    // Для подписи: используем Ed25519

    // SignedPreKey X25519 (DH)
    final signedPreKeyPair = await X25519().newKeyPair();
    final signedPreKeyData = await signedPreKeyPair.extract();
    final signedPreKeyPrivate = await signedPreKeyPair.extractPrivateKeyBytes();
    final signedPreKeyPublic = signedPreKeyData.publicKey.bytes;

    // Подпись signedPreKeyPublic Ed25519-identity-ключом (Signal-стандарт!)
    final signature = await Ed25519().sign(
      signedPreKeyPublic,
      keyPair: edIdentity,
    );

    final registrationId = DateTime.now().millisecondsSinceEpoch % 100000;
    final signedPreKeyId = DateTime.now().millisecondsSinceEpoch % 100000;

    return {
      // Identity (для DH - X25519, для подписи - Ed25519)
      'identityPrivate': base64Encode(edIdentityPrivate),
      'identityPublic': base64Encode(edIdentityPublic),
      
      'xIdentityPrivate': base64Encode(xIdentityPrivate),
      'xIdentityPublic': base64Encode(xIdentityPublic),
      // SignedPreKey (X25519)
      'signedPreKeyId': signedPreKeyId.toString(),
      'signedPrePublic': base64Encode(signedPreKeyPublic),
      'signedPrePrivate': base64Encode(signedPreKeyPrivate),
      'signedPreSignature': base64Encode(signature.bytes), // подпись SPK

      // Для Signal
      'registrationId': registrationId.toString(),
    };
  }
}
