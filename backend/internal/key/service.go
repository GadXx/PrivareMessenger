package key

import (
	"context"
	"errors"
	"log"

	"privatemessenger/internal/user"

	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

var (
	ErrKeyBundleNotFound = errors.New("key bundle not found")
	ErrNoOneTimeKeys     = errors.New("no available one-time pre-keys")
)

type KeyService struct {
	Repo user.UserRepository
}

func NewKeyService(repo user.UserRepository) *KeyService {
	return &KeyService{Repo: repo}
}

func (s *KeyService) AddOneTimePreKeys(ctx context.Context, IdentityKey string, keys []string, id []string) error {
	otpks := make([]user.OneTimePreKey, len(keys))

	for i, key := range keys {
		otpks[i] = user.OneTimePreKey{
			ID:          primitive.NewObjectID(),
			IdentityKey: IdentityKey,
			KeyId:       id[i],
			Key:         key,
			Used:        false,
			CreatedAt:   time.Now(),
		}
	}

	err := s.Repo.AddOneTimePreKeys(ctx, otpks)
	if err != nil {
		return err
	}

	return nil
}

func (s *KeyService) GetPublicKeyBundle(ctx context.Context, userID string) (*PublicKeyBundleDTO, error) {
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, err
	}
	bundle, err := s.Repo.GetUserKeyBundle(ctx, objID)
	if err != nil || bundle == nil {
		return nil, ErrKeyBundleNotFound
	}

	dto := &PublicKeyBundleDTO{
		UserID:             userID,
		IdentityKeyEd25519: bundle.IdentityKeyEd25519,
		IdentityKeyX25519:  bundle.IdentityKeyX25519,
		SignedPreKey:       bundle.SignedPreKey,
		SignedPreKeySig:    bundle.SignedPreKeySig,
	}
	return dto, nil
}

func (s *KeyService) TakeOneTimePreKey(ctx context.Context, identityKey string) (*OneTimePreKeyDTO, error) {
	otpk, err := s.Repo.TakeAndMarkOneTimePreKey(ctx, identityKey)
	if err != nil || otpk == nil {
		return nil, ErrNoOneTimeKeys
	}

	dto := &OneTimePreKeyDTO{
		IdentityKey: otpk.IdentityKey,
		KeyId:       otpk.KeyId,
		Key:         otpk.Key,
	}
	return dto, nil
}

func (s *KeyService) CountOneTimePreKeys(ctx context.Context, identityKey string) (int64, error) {
	log.Println(identityKey)
	if s == nil {
		log.Println("!!! KeyService is nil !!!")
	}
	if s.Repo == nil {
		log.Println("!!! s.Repo is nil !!!")
	}
	count, err := s.Repo.CountOneTimePreKeys(ctx, identityKey)
	return count, err
}

func (s *KeyService) DeleteUsedOneTimePreKey(ctx context.Context, identityKey string) error {
	return s.Repo.DeleteUsedOneTimePreKeys(ctx, identityKey)
}
