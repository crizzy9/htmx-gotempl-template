#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Setup script to rename the HTMX Go Template application and repository references."
    echo ""
    echo "Options:"
    echo "  -a, --app-name APP_NAME       New application name (e.g., 'my-todo-app')"
    echo "  -u, --repo-user USER          GitHub username/organization (e.g., 'johndoe')"
    echo "  -r, --repo-name REPO_NAME     Repository name (e.g., 'todo-app')"
    echo "  -h, --help                    Show this help message"
    echo ""
    echo "Interactive mode:"
    echo "  $0                            Run without arguments for interactive prompts"
    echo ""
    echo "Example:"
    echo "  $0 -a my-todo-app -u johndoe -r todo-app"
    echo ""
}

# Parse command line arguments
APP_NAME=""
REPO_USER=""
REPO_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--app-name)
            APP_NAME="$2"
            shift 2
            ;;
        -u|--repo-user)
            REPO_USER="$2"
            shift 2
            ;;
        -r|--repo-name)
            REPO_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Interactive prompts if arguments not provided
if [[ -z "$APP_NAME" ]]; then
    echo -n "Enter your new application name (e.g., 'my-todo-app'): "
    read -r APP_NAME
fi

if [[ -z "$REPO_USER" ]]; then
    echo -n "Enter your GitHub username/organization (e.g., 'johndoe'): "
    read -r REPO_USER
fi

if [[ -z "$REPO_NAME" ]]; then
    echo -n "Enter your repository name (e.g., 'todo-app'): "
    read -r REPO_NAME
fi

# Validate inputs
if [[ -z "$APP_NAME" || -z "$REPO_USER" || -z "$REPO_NAME" ]]; then
    print_error "All parameters are required!"
    show_usage
    exit 1
fi

# Validate that we're in the right directory
if [[ ! -f "go.mod" ]] || [[ ! -d "server" ]] || [[ ! -f "Makefile" ]]; then
    print_error "This script must be run from the root of the htmx-gotempl-template project"
    exit 1
fi

# Check if this is still the template (has myapp module)
if ! grep -q "^module myapp$" go.mod; then
    print_warning "This project appears to have already been renamed (go.mod doesn't contain 'module myapp')"
    echo -n "Continue anyway? (y/N): "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

print_info "Setting up project with the following configuration:"
echo "  Application name: $APP_NAME"
echo "  Repository user:  $REPO_USER"
echo "  Repository name:  $REPO_NAME"
echo "  Full module path: github.com/$REPO_USER/$REPO_NAME"
echo ""

echo -n "Continue? (y/N): "
read -r confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

print_info "Starting project setup..."

# 1. Update Go module
print_info "Updating Go module name..."
go mod edit -module "github.com/$REPO_USER/$REPO_NAME"

# 2. Update all Go import paths
print_info "Updating Go import paths..."
if command -v rg >/dev/null 2>&1; then
    # Use ripgrep if available (faster)
    rg -l "myapp" --type go | xargs sed -i "s|myapp|github.com/$REPO_USER/$REPO_NAME|g"
else
    # Fallback to find and grep
    find . -name "*.go" -exec sed -i "s|myapp|github.com/$REPO_USER/$REPO_NAME|g" {} \;
fi

# 3. Update Makefile app name
print_info "Updating Makefile..."
sed -i "s/APP_NAME = myapp/APP_NAME = $APP_NAME/g" Makefile

# 4. Update repository references
print_info "Updating repository references..."
sed -i "s/htmx-gotempl-template/$REPO_NAME/g" README.md flake.nix nixos-example.nix
sed -i "s|github.com/example/htmx-gotempl-template|github.com/$REPO_USER/$REPO_NAME|g" flake.nix

# 5. Update flake description
print_info "Updating flake description..."
sed -i "s/description = \"A minimal template for building web applications with Go, HTMX, and Templ templates\";/description = \"$APP_NAME - Built with Go, HTMX, and Templ templates\";/" flake.nix

# 6. Clean up and regenerate
print_info "Cleaning up and regenerating templates..."
if command -v make >/dev/null 2>&1; then
    make clean >/dev/null 2>&1 || true
    make templ-generate >/dev/null 2>&1 || print_warning "Failed to generate templates. Run 'make templ-generate' manually."
else
    print_warning "Make not found. Run 'make clean && make templ-generate' manually."
fi

# 7. Update Go dependencies
print_info "Updating Go dependencies..."
go mod tidy

# 8. Remove this setup script
print_info "Removing setup script..."
rm -f "$0"

print_success "Project setup completed successfully!"
echo ""
print_info "Next steps:"
echo "  1. Initialize git repository: git init"
echo "  2. Add remote origin: git remote add origin https://github.com/$REPO_USER/$REPO_NAME.git"
echo "  3. Make initial commit: git add . && git commit -m 'Initial commit'"
echo "  4. Push to repository: git push -u origin main"
echo ""
print_info "Development commands:"
echo "  - Start development server: make run"
echo "  - Build application: make build"
echo "  - Run with Docker: docker-compose up --build"
echo ""
print_success "Happy coding! 🚀"