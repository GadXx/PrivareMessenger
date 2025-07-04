package ws

type AuthPayload struct {
	Type        string `json:"type"`
	IdentityKey string `json:"identity_key"`
	Nonce       string `json:"nonce"`
	Signature   string `json:"signature"`
}

type IncomingMessage struct {
	Type         string `json:"type"`
	From         string `json:"from"`
	ReceiverID   string `json:"receiver_id"`
	Content      string `json:"content"`
	EphemeralPub string `json:"ephemeral_pub"`
	OtpkID       string `json:"otpk_id"`
	Timestamp    int64  `json:"timestamp"`
}

type CheckPreKeysPayload struct {
	Type string `json:"type"`
}

type NeedMorePreKeysPayload struct {
	Type   string `json:"type"`
	Needed int    `json:"needed"`
}

type AddPreKeysPayload struct {
	Type string   `json:"type"`
	Keys []string `json:"keys"`
	Id   []string `json:"id"`
}

type PreKeysCountPayload struct {
	Type  string `json:"type"`
	Count int64  `json:"count"`
}
