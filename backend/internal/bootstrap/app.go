package bootstrap

import (
	"log"
	"net/http"
	"privatemessenger/internal/auth"
	db "privatemessenger/internal/database"
	"privatemessenger/internal/key"
	"privatemessenger/internal/message"
	"privatemessenger/internal/router"
	"privatemessenger/internal/user"

	"github.com/go-chi/chi/v5"
	"go.mongodb.org/mongo-driver/mongo"
)

type App struct {
	Router      *chi.Mux
	MongoClient *mongo.Client
}

func NewApp() *App {
	mongoClient, database, err := db.ConnectMongo()
	if err != nil {
		log.Fatalf("failed to connect to MongoDB: %v", err)
	}
	db.EnsureUserIndexes(database)
	db.EnsureOneTimePreKeyIndexes(database)

	userRepo := user.NewUserRepository(database)
	userService := user.NewUserService(userRepo)
	userHandler := user.NewUserHandler(userService)

	keyService := key.NewKeyService(userRepo)
	keyHandler := key.NewKeyHandler(keyService)

	messageRepository := message.NewMessageRepository(database)
	messageService := message.NewMessageService(messageRepository)

	router := router.NewRouter(userHandler, keyHandler, messageService, auth.NewAuthService())

	return &App{
		Router:      router,
		MongoClient: mongoClient,
	}
}

func (a *App) Run() {
	log.Println("Server started at 0.0.0.0:8080")
	log.Fatal(http.ListenAndServe("0.0.0.0:8080", a.Router))
}

func (a *App) Shutdown() {
	if err := db.DisconnectMongo(a.MongoClient); err != nil {
		log.Printf("failed to disconnect MongoDB: %v", err)
	}
	if err := db.CloseRedis(); err != nil {
		log.Printf("failed to close Redis: %v", err)
	}
}
