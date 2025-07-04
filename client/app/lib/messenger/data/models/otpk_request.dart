class OtpkRequest {
  final String identityKey;
  final String keyId;
  final String key;

  OtpkRequest({
    required this.identityKey,
    required this.keyId,
    required this.key,
  });

  factory OtpkRequest.fromJson(Map<String, dynamic> json) {
    return OtpkRequest(
      identityKey: json['identity_key'] as String,
      keyId: json['key_id'] as String,
      key: json['key'] as String, 
    );
  }
}