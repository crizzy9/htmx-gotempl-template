package services

import (
	"database/sql"
	"fmt"

	"myapp/server/models"
)

// PostService handles post-related database operations
type PostService struct {
	db *sql.DB
}

// NewPostService creates a new PostService
func NewPostService(db *sql.DB) *PostService {
	return &PostService{db: db}
}

// GetAllPosts retrieves all published posts
func (s *PostService) GetAllPosts() ([]models.Post, error) {
	query := `
		SELECT id, title, content, user_id, published, created_at, updated_at 
		FROM posts 
		WHERE published = true 
		ORDER BY created_at DESC`

	rows, err := s.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to query posts: %w", err)
	}
	defer rows.Close()

	var posts []models.Post
	for rows.Next() {
		var post models.Post
		err := rows.Scan(&post.ID, &post.Title, &post.Content, &post.UserID, &post.Published, &post.CreatedAt, &post.UpdatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan post: %w", err)
		}
		posts = append(posts, post)
	}

	return posts, nil
}

// GetPostByID retrieves a post by ID
func (s *PostService) GetPostByID(id int) (*models.Post, error) {
	query := `
		SELECT id, title, content, user_id, published, created_at, updated_at 
		FROM posts 
		WHERE id = $1`

	var post models.Post
	err := s.db.QueryRow(query, id).Scan(
		&post.ID, &post.Title, &post.Content, &post.UserID, &post.Published, &post.CreatedAt, &post.UpdatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("post not found")
		}
		return nil, fmt.Errorf("failed to get post: %w", err)
	}

	return &post, nil
}

// CreatePost creates a new post
func (s *PostService) CreatePost(title, content string, userID int) (*models.Post, error) {
	query := `
		INSERT INTO posts (title, content, user_id, published) 
		VALUES ($1, $2, $3, false) 
		RETURNING id, title, content, user_id, published, created_at, updated_at`

	var post models.Post
	err := s.db.QueryRow(query, title, content, userID).Scan(
		&post.ID, &post.Title, &post.Content, &post.UserID, &post.Published, &post.CreatedAt, &post.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create post: %w", err)
	}

	return &post, nil
}

// PublishPost publishes a post
func (s *PostService) PublishPost(id int) error {
	query := `UPDATE posts SET published = true, updated_at = NOW() WHERE id = $1`

	result, err := s.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to publish post: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get affected rows: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("post not found")
	}

	return nil
}
