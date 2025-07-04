import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class SignalCore {
  static final algorithm = X25519();
  static final cipher = AesGcm.with256bits();

  static String _b64(List<int> b) => base64Encode(b);

  // SENDER (ИСПОЛНЯЕТ ТОЧНО ПО X3DH)
  static Future<List<int>> senderComputeSharedSecret({
    required SimpleKeyPair senderIdentityKeyPair,
    required SimplePublicKey receiverIdentityPub,
    required SimplePublicKey receiverSignedPreKeyPub,
    SimplePublicKey? receiverOneTimePreKeyPub,
    required SimpleKeyPair senderEphemeralKeyPair, 
  }) async {
    final senderIdentity = await senderIdentityKeyPair.extract();
    final senderEphemeral = await senderEphemeralKeyPair.extract();

    print('\n--- SENDER COMPUTE SHARED SECRET ---');
    print('Sender identity private:  ${_b64(await senderIdentityKeyPair.extractPrivateKeyBytes())}');
    print('Sender identity public:   ${_b64(senderIdentity.publicKey.bytes)}');
    print('Sender ephemeral private: ${_b64(await senderEphemeralKeyPair.extractPrivateKeyBytes())}');
    print('Sender ephemeral public:  ${_b64(senderEphemeral.publicKey.bytes)}');
    print('Receiver identity public:      ${_b64(receiverIdentityPub.bytes)}');
    print('Receiver signed prekey public: ${_b64(receiverSignedPreKeyPub.bytes)}');
    if (receiverOneTimePreKeyPub != null) {
      print('Receiver OTPK public: ${_b64(receiverOneTimePreKeyPub.bytes)}');
    }

    // DH1 = X25519(eph_priv, id_rec_pub)
    final dh1 = await X25519().sharedSecretKey(
      keyPair: senderEphemeralKeyPair,
      remotePublicKey: receiverIdentityPub,
    );
    // DH2 = X25519(eph_priv, spk_rec_pub)
    final dh2 = await X25519().sharedSecretKey(
      keyPair: senderEphemeralKeyPair,
      remotePublicKey: receiverSignedPreKeyPub,
    );
    // DH3 = X25519(id_snd_priv, spk_rec_pub)
    final dh3 = await X25519().sharedSecretKey(
      keyPair: senderIdentityKeyPair,
      remotePublicKey: receiverSignedPreKeyPub,
    );

    print('DH1 (Eph_priv, Rec_id_pub):      ${_b64(await senderEphemeralKeyPair.extractPrivateKeyBytes())}, ${_b64(receiverIdentityPub.bytes)} = ${_b64(await dh1.extractBytes())}');
    print('DH2 (Eph_priv, Rec_signed_pub):  ${_b64(await senderEphemeralKeyPair.extractPrivateKeyBytes())}, ${_b64(receiverSignedPreKeyPub.bytes)} = ${_b64(await dh2.extractBytes())}');
    print('DH3 (Id_priv, Rec_signed_pub):   ${_b64(await senderIdentityKeyPair.extractPrivateKeyBytes())}, ${_b64(receiverSignedPreKeyPub.bytes)} = ${_b64(await dh3.extractBytes())}');

    // Склеиваем всё в один массив байт!
    final combined = <int>[
      ...await dh1.extractBytes(),
      ...await dh2.extractBytes(),
      ...await dh3.extractBytes(),
    ];

    if (receiverOneTimePreKeyPub != null) {
      // DH4 = X25519(eph_priv, opk_rec_pub)
      final dh4 = await X25519().sharedSecretKey(
        keyPair: senderEphemeralKeyPair,
        remotePublicKey: receiverOneTimePreKeyPub,
      );
      print('DH4 (Eph_priv, Rec_OTPK_pub):   ${_b64(await senderEphemeralKeyPair.extractPrivateKeyBytes())}, ${_b64(receiverOneTimePreKeyPub.bytes)} = ${_b64(await dh4.extractBytes())}');
      combined.addAll(await dh4.extractBytes());
    }

    print('Combined DHs (before hash): ${_b64(combined)}');

    final hashed = await Sha256().hash(combined);
    print('Shared secret (SHA256):     ${_b64(hashed.bytes)}');
    print('--- END SENDER ---\n');
    return hashed.bytes;
  }

  // RECEIVER (ТОЧНО ТАК ЖЕ!!!)
  static Future<List<int>> receiverComputeSharedSecret({
    required SimpleKeyPair receiverIdentityKeyPair,
    required SimpleKeyPair receiverSignedPreKeyPair,
    required SimplePublicKey senderIdentityPub,
    required SimplePublicKey senderEphemeralPub,
    SimpleKeyPair? receiverOneTimePreKeyPair,
  }) async {
    final receiverIdentity = await receiverIdentityKeyPair.extract();
    final receiverSigned = await receiverSignedPreKeyPair.extract();

    print('\n--- RECEIVER COMPUTE SHARED SECRET ---');
    print('Receiver identity private:  ${_b64(await receiverIdentityKeyPair.extractPrivateKeyBytes())}');
    print('Receiver identity public:   ${_b64(receiverIdentity.publicKey.bytes)}');
    print('Receiver signed pre priv:   ${_b64(await receiverSignedPreKeyPair.extractPrivateKeyBytes())}');
    print('Receiver signed pre pub:    ${_b64(receiverSigned.publicKey.bytes)}');
    print('Sender identity public:     ${_b64(senderIdentityPub.bytes)}');
    print('Sender ephemeral public:    ${_b64(senderEphemeralPub.bytes)}');
    if (receiverOneTimePreKeyPair != null) {
      final otpk = await receiverOneTimePreKeyPair.extract();
      print('Receiver OTPK private:  ${_b64(await receiverOneTimePreKeyPair.extractPrivateKeyBytes())}');
      print('Receiver OTPK public:   ${_b64(otpk.publicKey.bytes)}');
    }

    // DH1 = DH(eph, id_rec)  ===  DH(id_rec_priv, eph_pub)
    final dh1 = await X25519().sharedSecretKey(
      keyPair: receiverIdentityKeyPair,
      remotePublicKey: senderEphemeralPub,
    );
    // DH2 = DH(eph, spk_rec) ===  DH(spk_rec_priv, eph_pub)
    final dh2 = await X25519().sharedSecretKey(
      keyPair: receiverSignedPreKeyPair,
      remotePublicKey: senderEphemeralPub,
    );
    // DH3 = DH(id_snd, spk_rec) ===  DH(spk_rec_priv, id_snd_pub)
    final dh3 = await X25519().sharedSecretKey(
      keyPair: receiverSignedPreKeyPair,
      remotePublicKey: senderIdentityPub,
    );

    print('DH1 (Id_priv, Eph_pub):         ${_b64(await receiverIdentityKeyPair.extractPrivateKeyBytes())}, ${_b64(senderEphemeralPub.bytes)} = ${_b64(await dh1.extractBytes())}');
    print('DH2 (Signed_priv, Eph_pub):     ${_b64(await receiverSignedPreKeyPair.extractPrivateKeyBytes())}, ${_b64(senderEphemeralPub.bytes)} = ${_b64(await dh2.extractBytes())}');
    print('DH3 (Signed_priv, Sender_id_pub): ${_b64(await receiverSignedPreKeyPair.extractPrivateKeyBytes())}, ${_b64(senderIdentityPub.bytes)} = ${_b64(await dh3.extractBytes())}');

    // Склеиваем в один длинный массив
    final combined = <int>[
      ...await dh1.extractBytes(),
      ...await dh2.extractBytes(),
      ...await dh3.extractBytes(),
    ];

    if (receiverOneTimePreKeyPair != null) {
      // DH4 = DH(eph, opk_rec) === DH(opk_rec_priv, eph_pub)
      final dh4 = await X25519().sharedSecretKey(
        keyPair: receiverOneTimePreKeyPair,
        remotePublicKey: senderEphemeralPub,
      );
      print('DH4 (OTPK_priv, Eph_pub):       ${_b64(await receiverOneTimePreKeyPair.extractPrivateKeyBytes())}, ${_b64(senderEphemeralPub.bytes)} = ${_b64(await dh4.extractBytes())}');
      combined.addAll(await dh4.extractBytes());
    }

    print('Combined DHs (before hash): ${_b64(combined)}');

    final hashed = await Sha256().hash(combined);
    print('Shared secret (SHA256):     ${_b64(hashed.bytes)}');
    print('--- END RECEIVER ---\n');
    return hashed.bytes;
  }

  /// Шифрование сообщения
  static Future<String> encryptMessage(List<int> sharedSecret, String message) async {
    print('\n--- ENCRYPTION ---');
    print('Shared secret: ${_b64(sharedSecret)}');

    final nonce = cipher.newNonce();
    print('Nonce:         ${_b64(nonce)}');

    final secretKey = SecretKey(sharedSecret);
    final secretBox = await cipher.encrypt(
      utf8.encode(message),
      secretKey: secretKey,
      nonce: nonce,
    );

    print('Ciphertext:    ${_b64(secretBox.cipherText)}');
    print('MAC:           ${_b64(secretBox.mac.bytes)}');
    print('--- END ENCRYPTION ---\n');

    

    return base64Encode([...nonce, ...secretBox.cipherText, ...secretBox.mac.bytes]);
  }

  /// Дешифровка сообщения
  static Future<String> decryptMessage(List<int> sharedSecret, String encryptedMessage) async {
    print('\n--- DECRYPTION ---');
    print('Shared secret:  ${_b64(sharedSecret)}');

    final data = base64Decode(encryptedMessage);
    final nonce = data.sublist(0, 12);
    final cipherText = data.sublist(12, data.length - 16);
    final macBytes = data.sublist(data.length - 16);

    print('Nonce:          ${_b64(nonce)}');
    print('Ciphertext:     ${_b64(cipherText)}');
    print('MAC:            ${_b64(macBytes)}');

    final secretKey = SecretKey(sharedSecret);
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));
    final decrypted = await cipher.decrypt(secretBox, secretKey: secretKey);

    print('Plaintext:      ${utf8.decode(decrypted)}');
    print('--- END DECRYPTION ---\n');

    return utf8.decode(decrypted);
  }
}
