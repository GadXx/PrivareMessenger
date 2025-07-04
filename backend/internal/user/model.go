package user

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type User struct {
	ID        primitive.ObjectID `bson:"_id"`
	Username  string             `bson:"username"`
	Login     string             `bson:"login"`
	KeyBundle KeyBundle          `bson:"key_bundle"`
	CreatedAt time.Time          `bson:"created_at"`
	UpdatedAt time.Time          `bson:"updated_at"`
}

type KeyBundle struct {
	IdentityKeyEd25519 string `bson:"identity_key_ed25519"`
	IdentityKeyX25519  string `bson:"identity_key_x25519"`
	SignedPreKey       string `bson:"signed_pre_key"`
	SignedPreKeyId     string `bson:"signed_pre_key_id"`
	SignedPreKeySig    string `bson:"signed_pre_key_sig"`
	RegistrationId     string `bson:"registration_id"`
}

type OneTimePreKey struct {
	ID          primitive.ObjectID `bson:"_id,omitempty"`
	IdentityKey string             `bson:"identity_key"`
	KeyId       string             `bson:"key_id"`
	Key         string             `bson:"key"`
	Used        bool               `bson:"used"`
	CreatedAt   time.Time          `bson:"created_at"`
}
