package api

import (
	"encoding/json"
	"net/http"

	"myapp/server/config"
	"myapp/server/templates"
)

// Handlers encapsulates dependencies for HTTP handlers
type Handlers struct {
	Config *config.Config
}

// NewHandlers creates a new Handlers instance
func NewHandlers(cfg *config.Config) *Handlers {
	return &Handlers{Config: cfg}
}

// RegisterRoutes registers all HTTP handlers to the given mux/router
func (h *Handlers) RegisterRoutes(r *http.ServeMux) {
	r.HandleFunc("/api/hello", h.HelloHandler)
	r.HandleFunc("/health", h.HealthHandler)
	r.HandleFunc("/", h.IndexHandler)
}

// IndexHandler renders the main page
func (h *Handlers) IndexHandler(w http.ResponseWriter, r *http.Request) {
	indexPage := templates.IndexPage(h.Config)
	err := indexPage.Render(r.Context(), w)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

// HelloHandler handles /api/hello requests
func (h *Handlers) HelloHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]string{
		"message": "Hello, World!",
		"status":  "success",
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// HealthHandler returns basic health info
func (h *Handlers) HealthHandler(w http.ResponseWriter, r *http.Request) {
	status := map[string]string{
		"status":  "ok",
		"version": "1.0.0",
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(status)
}
