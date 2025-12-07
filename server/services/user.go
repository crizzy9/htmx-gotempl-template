package services

import (
	"database/sql"
	"fmt"

	"myapp/server/models"
)

// UserService handles user-related database operations
type UserService struct {
	db *sql.DB
}

// NewUserService creates a new UserService
func NewUserService(db *sql.DB) *UserService {
	return &UserService{db: db}
}

// GetAllUsers retrieves all users from the database
func (s *UserService) GetAllUsers() ([]models.User, error) {
	query := `
		SELECT id, email, name, created_at, updated_at 
		FROM users 
		ORDER BY created_at DESC`

	rows, err := s.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to query users: %w", err)
	}
	defer rows.Close()

	var users []models.User
	for rows.Next() {
		var user models.User
		err := rows.Scan(&user.ID, &user.Email, &user.Name, &user.CreatedAt, &user.UpdatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan user: %w", err)
		}
		users = append(users, user)
	}

	return users, nil
}

// GetUserByID retrieves a user by ID
func (s *UserService) GetUserByID(id int) (*models.User, error) {
	query := `
		SELECT id, email, name, created_at, updated_at 
		FROM users 
		WHERE id = $1`

	var user models.User
	err := s.db.QueryRow(query, id).Scan(
		&user.ID, &user.Email, &user.Name, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return &user, nil
}

// CreateUser creates a new user
func (s *UserService) CreateUser(email, name string) (*models.User, error) {
	query := `
		INSERT INTO users (email, name) 
		VALUES ($1, $2) 
		RETURNING id, email, name, created_at, updated_at`

	var user models.User
	err := s.db.QueryRow(query, email, name).Scan(
		&user.ID, &user.Email, &user.Name, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return &user, nil
}

// UpdateUser updates an existing user
func (s *UserService) UpdateUser(id int, email, name string) (*models.User, error) {
	query := `
		UPDATE users 
		SET email = $1, name = $2, updated_at = NOW() 
		WHERE id = $3 
		RETURNING id, email, name, created_at, updated_at`

	var user models.User
	err := s.db.QueryRow(query, email, name, id).Scan(
		&user.ID, &user.Email, &user.Name, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to update user: %w", err)
	}

	return &user, nil
}

// DeleteUser deletes a user by ID
func (s *UserService) DeleteUser(id int) error {
	query := `DELETE FROM users WHERE id = $1`

	result, err := s.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to delete user: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get affected rows: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("user not found")
	}

	return nil
}
