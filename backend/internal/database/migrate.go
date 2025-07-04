package db

import (
	"context"
	"log"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func EnsureUserIndexes(db *mongo.Database) {
	users := db.Collection("users")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := users.Indexes().CreateOne(
		ctx,
		mongo.IndexModel{
			Keys:    bson.D{{Key: "login", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
	)
	if err != nil {
		log.Fatalf("failed to create index for login: %v", err)
	}
}

func EnsureOneTimePreKeyIndexes(db *mongo.Database) {
	preKeys := db.Collection("one_time_pre_keys")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := preKeys.Indexes().CreateOne(
		ctx,
		mongo.IndexModel{
			Keys: bson.D{
				{Key: "user_id", Value: 1},
				{Key: "used", Value: 1},
			},
		},
	)
	if err != nil {
		log.Fatalf("failed to create index for one_time_pre_keys: %v", err)
	}
}
