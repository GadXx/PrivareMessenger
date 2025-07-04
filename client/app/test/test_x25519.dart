import 'dart:convert';
import 'package:cryptography/cryptography.dart';

void main() async {
  final a = await X25519().newKeyPair(); // user A
  final b = await X25519().newKeyPair(); // user B

  final aPub = await a.extractPublicKey();
  final bPub = await b.extractPublicKey();

  final dh1 = await X25519().sharedSecretKey(keyPair: a, remotePublicKey: bPub);
  final dh2 = await X25519().sharedSecretKey(keyPair: b, remotePublicKey: aPub);

  print('A->B: ${base64Encode(await dh1.extractBytes())}');
  print('B->A: ${base64Encode(await dh2.extractBytes())}');

  
}