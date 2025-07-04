package user

import (
	"context"
	"time"

	"errors"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type UserRepository interface {
	CreateUser(ctx context.Context, user *User) (*User, error)
	FindByLogin(ctx context.Context, login string) (*User, error)
	UpdateUser(ctx context.Context, user *User) error
	DeleteUser(ctx context.Context, id primitive.ObjectID) error
	FindByIdentityKey(ctx context.Context, identityKey string) (*User, error)
	GetUserKeyBundle(ctx context.Context, userID primitive.ObjectID) (*KeyBundle, error)
	TakeAndMarkOneTimePreKey(ctx context.Context, identityKey string) (*OneTimePreKey, error)
	DeleteUsedOneTimePreKeys(ctx context.Context, identityKey string) error
	AddOneTimePreKeys(ctx context.Context, keys []OneTimePreKey) error
	CountOneTimePreKeys(ctx context.Context, identityKey string) (int64, error)
}

type userRepository struct {
	usersColl *mongo.Collection
	keysColl  *mongo.Collection
}

func NewUserRepository(db *mongo.Database) UserRepository {
	return &userRepository{
		usersColl: db.Collection("users"),
		keysColl:  db.Collection("one_time_pre_keys"),
	}
}

func (r *userRepository) CreateUser(ctx context.Context, user *User) (*User, error) {
	if user.ID.IsZero() {
		user.ID = primitive.NewObjectID()
	}
	res, err := r.usersColl.InsertOne(ctx, user)
	if err != nil {
		if writeErr, ok := err.(mongo.WriteException); ok {
			for _, we := range writeErr.WriteErrors {
				if we.Code == 11000 {
					return nil, errors.New("login already exists")
				}
			}
		}
		return nil, err
	}
	user.ID = res.InsertedID.(primitive.ObjectID)
	return user, nil
}

func (r *userRepository) FindByLogin(ctx context.Context, login string) (*User, error) {
	var user User
	err := r.usersColl.FindOne(ctx, bson.M{"login": login}).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) UpdateUser(ctx context.Context, user *User) error {
	_, err := r.usersColl.UpdateOne(ctx, bson.M{"_id": user.ID}, bson.M{"$set": user})
	return err
}

func (r *userRepository) DeleteUser(ctx context.Context, id primitive.ObjectID) error {
	_, err := r.usersColl.DeleteOne(ctx, bson.M{"_id": id})
	return err
}

func (r *userRepository) FindByIdentityKey(ctx context.Context, identityKey string) (*User, error) {
	var user User
	err := r.usersColl.FindOne(ctx, bson.M{"identity_key": identityKey}).Decode(&user)
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) GetUserKeyBundle(ctx context.Context, userID primitive.ObjectID) (*KeyBundle, error) {
	filter := bson.M{"_id": userID}
	var user User
	err := r.usersColl.FindOne(ctx, filter).Decode(&user)
	if err != nil {
		return nil, err
	}
	return &user.KeyBundle, nil
}

func (r *userRepository) AddOneTimePreKeys(ctx context.Context, keys []OneTimePreKey) error {
	docs := make([]interface{}, len(keys))
	now := time.Now()
	for i, k := range keys {
		k.ID = primitive.NewObjectID()
		k.CreatedAt = now
		docs[i] = k
	}
	_, err := r.keysColl.InsertMany(ctx, docs)
	return err
}

func (r *userRepository) CountOneTimePreKeys(ctx context.Context, identityKey string) (int64, error) {
	count, err := r.keysColl.CountDocuments(ctx, bson.M{
		"identity_key": identityKey,
		"used":         false,
	})
	return count, err
}

func (r *userRepository) TakeAndMarkOneTimePreKey(ctx context.Context, identityKey string) (*OneTimePreKey, error) {
	filter := bson.M{"identity_key": identityKey, "used": false}
	update := bson.M{"$set": bson.M{"used": true}}
	opts := options.FindOneAndUpdate().SetSort(bson.D{{Key: "created_at", Value: 1}}).SetReturnDocument(options.After)
	var preKey OneTimePreKey
	err := r.keysColl.FindOneAndUpdate(ctx, filter, update, opts).Decode(&preKey)
	if err != nil {
		return nil, err
	}
	return &preKey, nil
}

func (r *userRepository) DeleteUsedOneTimePreKeys(ctx context.Context, identityKey string) error {
	_, err := r.keysColl.DeleteMany(ctx, bson.M{
		"identity_key": identityKey,
		"used":         true,
	})
	return err
}
