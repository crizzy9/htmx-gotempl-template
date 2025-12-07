package main

import (
	"fmt"
	"log"
	"net/http"

	"myapp/server/api"
	"myapp/server/config"
	"myapp/server/database"
)

func main() {
	// Load configuration
	appConfig := config.LoadConfig()

	// Connect to database
	db, err := database.Connect(appConfig)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Run migrations
	err = database.RunMigrations(appConfig, "migrations")
	if err != nil {
		log.Printf("Warning: Failed to run migrations: %v", err)
	}

	// Create handlers and mux
	handlers := api.NewHandlers(appConfig, db)
	mux := http.NewServeMux()
	handlers.RegisterRoutes(mux)

	// Serve static files for /static
	mux.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("web/static"))))

	// Start the server
	serverAddr := fmt.Sprintf("%s:%d", appConfig.Server.Host, appConfig.Server.Port)
	log.Printf("Server started at %s", serverAddr)
	if err := http.ListenAndServe(serverAddr, mux); err != nil {
		log.Fatal(err)
	}
}
