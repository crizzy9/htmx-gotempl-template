package api

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"

	"myapp/server/config"
	"myapp/server/services"
	"myapp/server/templates"
)

// Handlers encapsulates dependencies for HTTP handlers
type Handlers struct {
	Config      *config.Config
	UserService *services.UserService
	PostService *services.PostService
}

// NewHandlers creates a new Handlers instance
func NewHandlers(cfg *config.Config, db *sql.DB) *Handlers {
	return &Handlers{
		Config:      cfg,
		UserService: services.NewUserService(db),
		PostService: services.NewPostService(db),
	}
}

// RegisterRoutes registers all HTTP handlers to the given mux/router
func (h *Handlers) RegisterRoutes(r *http.ServeMux) {
	r.HandleFunc("/api/hello", h.HelloHandler)
	r.HandleFunc("/health", h.HealthHandler)
	r.HandleFunc("/", h.IndexHandler)

	// User routes
	r.HandleFunc("/api/users", h.UsersHandler)
	r.HandleFunc("/api/users/create", h.CreateUserHandler)
	r.HandleFunc("/api/users/", h.UserHandler)

	// Post routes
	r.HandleFunc("/api/posts", h.PostsHandler)
	r.HandleFunc("/api/posts/create", h.CreatePostHandler)
	r.HandleFunc("/api/posts/", h.PostHandler)
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

// UsersHandler handles requests to /api/users
func (h *Handlers) UsersHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	users, err := h.UserService.GetAllUsers()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
}

// CreateUserHandler handles user creation
func (h *Handlers) CreateUserHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	email := r.FormValue("email")
	name := r.FormValue("name")

	if email == "" || name == "" {
		http.Error(w, "Email and name are required", http.StatusBadRequest)
		return
	}

	user, err := h.UserService.CreateUser(email, name)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

// UserHandler handles individual user requests
func (h *Handlers) UserHandler(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Path[len("/api/users/"):]
	if idStr == "" {
		http.Error(w, "User ID required", http.StatusBadRequest)
		return
	}

	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	switch r.Method {
	case http.MethodGet:
		user, err := h.UserService.GetUserByID(id)
		if err != nil {
			http.Error(w, err.Error(), http.StatusNotFound)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(user)

	case http.MethodDelete:
		err := h.UserService.DeleteUser(id)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusNoContent)

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// PostsHandler handles requests to /api/posts
func (h *Handlers) PostsHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	posts, err := h.PostService.GetAllPosts()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(posts)
}

// CreatePostHandler handles post creation
func (h *Handlers) CreatePostHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	title := r.FormValue("title")
	content := r.FormValue("content")
	userIDStr := r.FormValue("user_id")

	if title == "" || content == "" || userIDStr == "" {
		http.Error(w, "Title, content, and user_id are required", http.StatusBadRequest)
		return
	}

	userID, err := strconv.Atoi(userIDStr)
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	post, err := h.PostService.CreatePost(title, content, userID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(post)
}

// PostHandler handles individual post requests
func (h *Handlers) PostHandler(w http.ResponseWriter, r *http.Request) {
	idStr := r.URL.Path[len("/api/posts/"):]
	if idStr == "" {
		http.Error(w, "Post ID required", http.StatusBadRequest)
		return
	}

	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "Invalid post ID", http.StatusBadRequest)
		return
	}

	switch r.Method {
	case http.MethodGet:
		post, err := h.PostService.GetPostByID(id)
		if err != nil {
			http.Error(w, err.Error(), http.StatusNotFound)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(post)

	case http.MethodPost:
		action := r.FormValue("action")
		if action == "publish" {
			err := h.PostService.PublishPost(id)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.WriteHeader(http.StatusOK)
		} else {
			http.Error(w, "Invalid action", http.StatusBadRequest)
		}

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}
