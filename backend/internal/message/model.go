package message

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Message struct {
	ID           primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	From         string             `bson:"from" json:"from"`
	To           string             `bson:"to" json:"to"`
	Ciphertext   string             `bson:"ciphertext" json:"ciphertext"`
	EphemeralKey string             `bson:"ephemeral_key" json:"ephemeral_key"`
	PreKeyID     string             `bson:"pre_key_id" json:"pre_key_id"`
	Timestamp    int64              `bson:"timestamp" json:"timestamp"`
	Delivered    bool               `bson:"delivered" json:"delivered"`
	CreatedAt    time.Time          `bson:"created_at" json:"created_at"`
	ExpireAt     time.Time          `bson:"expire_at" json:"expire_at"`
}
