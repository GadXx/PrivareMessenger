package message

import (
	"context"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type MessageService struct {
	repo *MessageRepository
}

func NewMessageService(repo *MessageRepository) *MessageService {
	return &MessageService{repo: repo}
}

func (s *MessageService) SaveMessage(ctx context.Context, msg *Message) error {
	return s.repo.Save(ctx, msg)
}

func (s *MessageService) DeliverUndelivered(ctx context.Context, userID string) ([]Message, error) {
	return s.repo.GetUndeliveredMessages(ctx, userID)
}

func (s *MessageService) MarkAsDelivered(ctx context.Context, id string) error {
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return err
	}
	return s.repo.MarkAsDelivered(ctx, objID)
}
