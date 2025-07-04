// lib/features/auth/data/models/register_request.dart
class RegisterRequest {
  final String username;
  final String login;
  final String identityKey;
  final String xIdentityKey;
  final String signedPreKeyId;
  final String signedPreKey;
  final String signedPreKeySig;
  final String registrationId;

  RegisterRequest({
    required this.username,
    required this.login,
    required this.identityKey,
    required this.xIdentityKey,
    required this.signedPreKeyId,
    required this.signedPreKey,
    required this.signedPreKeySig,
    required this.registrationId,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'login': login,
    'identity_key_ed25519': identityKey,
    'identity_key_x25519': xIdentityKey,
    'signed_pre_key_id': signedPreKeyId,
    'signed_pre_key': signedPreKey,
    'signed_pre_key_sig': signedPreKeySig,
    'registration_id': registrationId,
  };
}
