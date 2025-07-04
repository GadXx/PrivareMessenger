package utils

import (
	"crypto/ed25519"
	"encoding/base64"
	"errors"
)

func VerifySignature(identityKeyBase64, message, signatureBase64 string) error {

	pubKeyBytes, err := base64.StdEncoding.DecodeString(identityKeyBase64)
	if err != nil {
		return errors.New("invalid public key encoding")
	}
	sigBytes, err := base64.StdEncoding.DecodeString(signatureBase64)
	if err != nil {
		return errors.New("invalid signature encoding")
	}

	if len(pubKeyBytes) != ed25519.PublicKeySize {
		return errors.New("invalid public key length")
	}
	if len(sigBytes) != ed25519.SignatureSize {
		return errors.New("invalid signature length")
	}

	if !ed25519.Verify(pubKeyBytes, []byte(message), sigBytes) {
		return errors.New("signature verification failed")
	}

	return nil
}
