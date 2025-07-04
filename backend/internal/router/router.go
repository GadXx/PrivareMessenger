package router

import (
	"privatemessenger/internal/auth"
	"privatemessenger/internal/key"
	"privatemessenger/internal/message"
	"privatemessenger/internal/middleware"
	"privatemessenger/internal/user"
	"privatemessenger/internal/ws"

	"github.com/go-chi/chi/v5"
	chiMiddleware "github.com/go-chi/chi/v5/middleware"
)

func NewRouter(
	userHandler *user.UserHandler,
	keyHandler *key.KeyHandler,
	messageService *message.MessageService,
	authService *auth.AuthService,
) *chi.Mux {
	mainRouter := chi.NewRouter()
	mainRouter.Use(chiMiddleware.Logger)
	mainRouter.Use(chiMiddleware.Recoverer)
	mainRouter.Use(middleware.ErrorHandler)

	mainRouter.Post("/api/pre-register", userHandler.ReservLogin)
	mainRouter.Post("/api/register", userHandler.Register)
	mainRouter.Get("/api/get-user-by-login/{login}", userHandler.GetUserByLogin)
	mainRouter.Post("/api/count-one-time-pre-keys", keyHandler.CountOneTimePreKeys)
	mainRouter.Get("/api/get-one-time-pre-key", keyHandler.GetOneTimePreKey)
	mainRouter.Get("/api/get-key-bundle/{user_id}", keyHandler.GetPublicKeyBundle)

	wsHandler := ws.WebSocketHandler{
		MessageService: messageService,
		AuthService:    authService,
		KeyService:     keyHandler.KeyService,
		Hub:            ws.NewHub(),
	}
	wsRouter := chi.NewRouter()
	wsRouter.HandleFunc("/ws", wsHandler.HandleWS)
	mainRouter.Mount("/", wsRouter)

	return mainRouter
}
