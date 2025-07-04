package user

import (
	"context"
	"errors"
	"fmt"
	db "privatemessenger/internal/database"

	"log"

	"github.com/redis/go-redis/v9"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type UserService struct {
	Repo UserRepository
}

func NewUserService(repo UserRepository) *UserService {
	return &UserService{
		Repo: repo,
	}
}

var (
	ErrUserAlreadyExists = errors.New("user already exists")
	ErrUserNotFound      = errors.New("user not found")
)

func (s *UserService) ReservLogin(ctx context.Context, login, identityKey string) error {
	_, err := s.Repo.FindByLogin(ctx, login)
	if err != nil {
		return err
	}
	rdb := db.NewRedisClient()
	key := fmt.Sprintf("login:%s", login)
	set, err := rdb.SetNX(ctx, key, identityKey, 0).Result()
	if err != nil {
		return err
	}
	if !set {
		return errors.New("login already exists")
	}
	return nil
}

func (s *UserService) Register(
	ctx context.Context,
	username,
	login,
	IdentityKeyEd25519, IdentityKeyX25519, signedPreKey, signedPreKeySig string,
	SignedPreKeyId, RegistrationId string,
) (*User, error) {
	rdb := db.NewRedisClient()
	key := fmt.Sprintf("login:%s", login)
	IdentityKeyEd25519Temp, err := rdb.Get(ctx, key).Result()
	if err != nil {
		if err == redis.Nil {
			return nil, errors.New("login is not reserved")
		}
		return nil, err
	}
	if IdentityKeyEd25519 != IdentityKeyEd25519Temp {
		return nil, errors.New("invalid identity key")
	}

	user := &User{
		ID:       primitive.NewObjectID(),
		Username: username,
		Login:    login,
		KeyBundle: KeyBundle{
			IdentityKeyEd25519: IdentityKeyEd25519,
			IdentityKeyX25519:  IdentityKeyX25519,
			SignedPreKey:       signedPreKey,
			SignedPreKeyId:     SignedPreKeyId,
			SignedPreKeySig:    signedPreKeySig,
			RegistrationId:     RegistrationId,
		},
	}
	user, err = s.Repo.CreateUser(ctx, user)
	if err != nil {
		log.Printf("error creating user: %v", err)
		return nil, err
	}

	_ = rdb.Del(ctx, key).Err()
	return user, nil
}

func (s *UserService) SearchUserByLogin(ctx context.Context, login string) (*User, error) {
	user, err := s.Repo.FindByLogin(ctx, login)
	if err != nil {
		return nil, ErrUserNotFound
	}
	return user, nil
}
