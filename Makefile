.PHONY: build run docker-build docker-run docker-stop clean help templ-generate db-up db-down db-reset db-migrate

# Default target
.DEFAULT_GOAL := help

# Variables
APP_NAME = myapp
DOCKER_IMAGE = $(APP_NAME)
DOCKER_CONTAINER = $(APP_NAME)

# Generate Templ templates
templ-generate:
	@echo "Generating Templ templates..."
	@templ generate

# Build the application
build: templ-generate
	@echo "Building $(APP_NAME)..."
	@go build -o $(APP_NAME) ./server

# Run the application locally
run: templ-generate build
	@echo "Running $(APP_NAME)..."
	@./$(APP_NAME)

# Build the Docker image
docker-build:
	@echo "Building Docker image $(DOCKER_IMAGE)..."
	@docker-compose build

# Run the application in Docker
docker-run:
	@echo "Running $(APP_NAME) in Docker..."
	@docker-compose up -d
	@echo "$(APP_NAME) is now running at http://localhost:8080"

# Stop the Docker container
docker-stop:
	@echo "Stopping $(APP_NAME) Docker container..."
	@docker-compose down

# Start database only
db-up:
	@echo "Starting database..."
	@docker-compose up -d postgres

# Stop database
db-down:
	@echo "Stopping database..."
	@docker-compose stop postgres

# Reset database (stop, remove volume, and restart)
db-reset:
	@echo "Resetting database..."
	@docker-compose down postgres
	@docker volume rm htmx-gotempl-template_postgres_data 2>/dev/null || true
	@docker-compose up -d postgres
	@echo "Database reset complete. Waiting for startup..."
	@sleep 5

# Run migrations manually (requires migrate CLI tool)
db-migrate:
	@echo "Running database migrations..."
	@echo "Note: This requires the migrate CLI tool to be installed"
	@echo "Install with: go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest"
	@migrate -path ./migrations -database "postgresql://postgres:postgres@localhost:5432/myapp_db?sslmode=disable" up

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -f $(APP_NAME)
	@go clean

# Show help
help:
	@echo "Available targets:"
	@echo "  templ-generate - Generate Templ templates"
	@echo "  build         - Build the application"
	@echo "  run           - Run the application locally"
	@echo "  docker-build  - Build the Docker image"
	@echo "  docker-run    - Run the application in Docker"
	@echo "  docker-stop   - Stop the Docker container"
	@echo "  db-up         - Start database only"
	@echo "  db-down       - Stop database"
	@echo "  db-reset      - Reset database (remove all data)"
	@echo "  db-migrate    - Run database migrations manually"
	@echo "  clean         - Clean build artifacts"
	@echo "  help          - Show this help message"