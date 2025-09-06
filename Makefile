.PHONY: build run docker-build docker-run docker-stop clean help templ-generate

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
	@echo "  clean         - Clean build artifacts"
	@echo "  help          - Show this help message"