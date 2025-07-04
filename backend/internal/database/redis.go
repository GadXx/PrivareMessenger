package db

import (
	"context"
	"os"
	"sync"

	"github.com/redis/go-redis/v9"
)

var (
	redisClient *redis.Client
	once        sync.Once
)

func NewRedisClient() *redis.Client {
	once.Do(func() {
		redisClient = redis.NewClient(&redis.Options{
			Addr:     os.Getenv("REDIS_ADDR"),
			Password: os.Getenv("REDIS_PASSWORD"),
			DB:       0,
		})
	})
	return redisClient
}

func PingRedis() error {
	return redisClient.Ping(context.Background()).Err()
}

func CloseRedis() error {
	if redisClient != nil {
		return redisClient.Close()
	}
	return nil
}
