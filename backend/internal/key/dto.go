package key

type PublicKeyBundleDTO struct {
	UserID             string `json:"user_id"`
	IdentityKeyEd25519 string `bson:"identity_key_ed25519"`
	IdentityKeyX25519  string `bson:"identity_key_x25519"`
	SignedPreKey       string `json:"signed_pre_key"`
	SignedPreKeyId     string `json:"signed_pre_key_id"`
	SignedPreKeySig    string `json:"signed_pre_key_sig"`
	RegistrationId     string `json:"registration_id"`
}

type OneTimePreKeyDTO struct {
	IdentityKey string `json:"identity_key"`
	KeyId       string `json:"key_id"`
	Key         string `json:"key"`
}
