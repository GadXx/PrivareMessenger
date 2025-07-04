class ChatRequest {
  final String id;
  final String identityKey;
  final String xIdentityKey;
  final String signedPreKey;
  final String signedPreKeyId;
  final String signedPreKeySig;
  final String registrationId;

  ChatRequest({
    required this.id,
    required this.identityKey,
    required this.xIdentityKey,
    required this.signedPreKeyId,
    required this.signedPreKey,
    required this.signedPreKeySig,
    required this.registrationId,
  });

  factory ChatRequest.fromJson(Map<String, dynamic> json) {
    return ChatRequest(
      id: json['user_id'] as String,
      identityKey: json['IdentityKeyEd25519'] as String,
      xIdentityKey: json['IdentityKeyX25519'] as String,
      signedPreKeyId: json['signed_pre_key_id'] as String,
      signedPreKey: json['signed_pre_key'] as String,
      signedPreKeySig: json['signed_pre_key_sig'] as String,
      registrationId: json['registration_id'] as String,
    );
  }
}