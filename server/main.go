package main

import (
	"fmt"
	"log"
	"net/http"

	"myapp/server/api"
	"myapp/server/config"
)

func main() {
	// Load configuration
	appConfig := config.LoadConfig()

	// Create handlers and mux
	handlers := api.NewHandlers(appConfig)
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
