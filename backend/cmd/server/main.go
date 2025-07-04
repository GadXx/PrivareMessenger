package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"privatemessenger/internal/bootstrap"
	"syscall"
	"time"
)

func main() {
	app := bootstrap.NewApp()

	srv := &http.Server{
		Addr:    ":8080",
		Handler: app.Router,
	}

	go func() {
		log.Println("Server started at 0.0.0.0:8080")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("listen: %s\n", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	app.Shutdown()
	log.Println("Server exiting")
}
