package auth

import (
	"privatemessenger/internal/utils"
)

type AuthService struct{}

func NewAuthService() *AuthService {
	return &AuthService{}
}

func (s *AuthService) Authenticate(identityKey, nonce, signature string) error {
	return utils.VerifySignature(identityKey, nonce, signature)
}
