package message

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

type MessageRepository struct {
	collection *mongo.Collection
}

func NewMessageRepository(db *mongo.Database) *MessageRepository {
	return &MessageRepository{
		collection: db.Collection("messages"),
	}
}

func (r *MessageRepository) Save(ctx context.Context, msg *Message) error {
	msg.ID = primitive.NewObjectID()
	msg.CreatedAt = time.Now()
	msg.ExpireAt = msg.CreatedAt.Add(7 * 24 * time.Hour)

	if msg.Timestamp == 0 {
		msg.Timestamp = msg.CreatedAt.UnixMilli()
	}
	msg.Delivered = false

	_, err := r.collection.InsertOne(ctx, msg)
	return err
}

func (r *MessageRepository) GetUndeliveredMessages(ctx context.Context, userID string) ([]Message, error) {
	filter := bson.M{"to": userID, "delivered": false}
	cur, err := r.collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	var messages []Message
	if err := cur.All(ctx, &messages); err != nil {
		return nil, err
	}
	return messages, nil
}

func (r *MessageRepository) MarkAsDelivered(ctx context.Context, id primitive.ObjectID) error {
	_, err := r.collection.UpdateOne(ctx,
		bson.M{"_id": id},
		bson.M{"$set": bson.M{"delivered": true}})
	return err
}
