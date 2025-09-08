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
    echo "Setup script to rename the HTMX Go Template application and clean up template-specific files."
    echo ""
    echo "Options:"
    echo "  -a, --app-name APP_NAME       New application name (e.g., 'my-todo-app')"
    echo "  -m, --module MODULE_PATH      Go module path (e.g., 'github.com/user/repo' or 'my-app')"
    echo "  -h, --help                    Show this help message"
    echo ""
    echo "Interactive mode:"
    echo "  $0                            Run without arguments for interactive prompts"
    echo ""
    echo "Examples:"
    echo "  $0 -a my-todo-app -m github.com/johndoe/todo-app"
    echo "  $0 -a my-app -m my-local-app"
    echo ""
}

# Parse command line arguments
APP_NAME=""
MODULE_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--app-name)
            APP_NAME="$2"
            shift 2
            ;;
        -m|--module)
            MODULE_PATH="$2"
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

if [[ -z "$MODULE_PATH" ]]; then
    echo ""
    echo "Choose module structure:"
    echo "  1. Remote repository (e.g., github.com/username/repo)"
    echo "  2. Local/simple module (e.g., my-app)"
    echo ""
    echo -n "Enter choice (1 or 2): "
    read -r choice
    
    case $choice in
        1)
            echo -n "Enter git hosting service (github.com, gitlab.com, etc.): "
            read -r git_host
            echo -n "Enter username/organization: "
            read -r repo_user
            echo -n "Enter repository name: "
            read -r repo_name
            MODULE_PATH="$git_host/$repo_user/$repo_name"
            ;;
        2)
            echo -n "Enter simple module name (e.g., 'my-app'): "
            read -r MODULE_PATH
            ;;
        *)
            print_error "Invalid choice. Please enter 1 or 2."
            exit 1
            ;;
    esac
fi

# Validate inputs
if [[ -z "$APP_NAME" || -z "$MODULE_PATH" ]]; then
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
echo "  Module path:      $MODULE_PATH"
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
go mod edit -module "$MODULE_PATH"

# 2. Update all Go import paths
print_info "Updating Go import paths..."
if command -v rg >/dev/null 2>&1; then
    # Use ripgrep if available (faster)
    rg -l "myapp" --type go | xargs sed -i "s|myapp|$MODULE_PATH|g"
else
    # Fallback to find and grep
    find . -name "*.go" -exec sed -i "s|myapp|$MODULE_PATH|g" {} \;
fi

# 3. Update Makefile app name
print_info "Updating Makefile..."
sed -i "s/APP_NAME = myapp/APP_NAME = $APP_NAME/g" Makefile

# 4. Update .gitignore binary name
print_info "Updating .gitignore..."
sed -i "s/^myapp$/$APP_NAME/g" .gitignore

# 5. Update repository references in flake.nix and other config files
if [[ -f "flake.nix" ]]; then
    print_info "Updating flake.nix..."
    sed -i "s/description = \"A minimal template for building web applications with Go, HTMX, and Templ templates\";/description = \"$APP_NAME - Built with Go, HTMX, and Templ templates\";/" flake.nix
    # Only update homepage if it's a remote repository (contains dots)
    if [[ "$MODULE_PATH" == *"."* ]]; then
        sed -i "s|homepage = \"https://github.com/example/htmx-gotempl-template\";|homepage = \"https://$MODULE_PATH\";|" flake.nix
    fi
fi

# 6. Clean up and regenerate templates
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
print_info "Project '$APP_NAME' has been configured with module '$MODULE_PATH'"
echo ""
print_info "Files updated:"
echo "  ✓ Go module and import paths"
echo "  ✓ Makefile - Updated app name"  
echo "  ✓ .gitignore - Updated binary name"
echo "  ✓ flake.nix - Updated description and homepage"
echo ""
print_info "Development commands:"
echo "  - Start development server: make run"
echo "  - Build application: make build"
echo "  - Run with Docker: docker-compose up --build"
echo ""
print_success "Happy coding! 🚀"