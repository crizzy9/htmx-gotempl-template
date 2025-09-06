# HTMX Go Template

A minimal template for building web applications with Go, HTMX, and Templ templates.

## Features

- **Go HTTP Server**: Standard Go HTTP server with clean routing
- **HTMX Integration**: Dynamic content loading without JavaScript
- **Templ Templates**: Type-safe HTML templates in Go
- **Tailwind CSS**: Utility-first CSS framework
- **Environment Config**: Configuration via environment variables
- **Docker Support**: Multi-stage build with health checks
- **Development Tools**: Makefile with common tasks

## Template Setup

### Automated Setup Script

After cloning this template, use the included setup script to rename everything to your new application:

```bash
# Interactive mode (prompts for input)
./setup.sh

# Or provide arguments directly
./setup.sh -a my-todo-app -u johndoe -r todo-app
```

The script will:
- Update the Go module name and all import paths
- Rename application references in Makefile
- Update repository URLs in all configuration files
- Clean and regenerate templates
- Update Go dependencies
- Remove itself after completion

### Manual Setup (Alternative)

If you prefer manual setup, you can also use these commands:

```bash
# Set your new app name and repository URL
NEW_APP_NAME="my-new-app"
NEW_REPO_USER="yourusername"  
NEW_REPO_NAME="your-repo-name"

# Update Go module and imports
go mod edit -module "github.com/$NEW_REPO_USER/$NEW_REPO_NAME"
find . -name "*.go" -exec sed -i "s|myapp|github.com/$NEW_REPO_USER/$NEW_REPO_NAME|g" {} \;

# Update application name and repository references
sed -i "s/APP_NAME = myapp/APP_NAME = $NEW_APP_NAME/g" Makefile
sed -i "s/htmx-gotempl-template/$NEW_REPO_NAME/g" README.md flake.nix nixos-example.nix
sed -i "s/github.com\/example\/htmx-gotempl-template/github.com\/$NEW_REPO_USER\/$NEW_REPO_NAME/g" flake.nix

# Clean up and regenerate
make clean && make templ-generate && go mod tidy
```

## Quick Start

### Option 1: Local Development

1. **Clone and customize**:
   ```bash
   # Copy this template
   cp -r htmx-gotempl-template my-new-app
   cd my-new-app
   
   # Follow the "Template Setup" section above to rename everything
   ```

2. **Install dependencies**:
   ```bash
   go mod tidy
   go install github.com/a-h/templ/cmd/templ@latest
   ```

3. **Run the application**:
   ```bash
   make run
   ```

4. **Visit**: http://localhost:8080

### Option 2: Docker

1. **Clone and customize**:
   ```bash
   # Copy this template
   cp -r htmx-gotempl-template my-new-app
   cd my-new-app
   
   # Follow the "Template Setup" section above to rename everything
   ```

2. **Run with Docker**:
   ```bash
   # Build and run in one command
   docker-compose up --build
   
   # Or use Makefile commands
   make docker-run
   ```

3. **Visit**: http://localhost:8080

4. **Stop the application**:
   ```bash
   # Stop containers
   docker-compose down
   
   # Or use Makefile
   make docker-stop
   ```

#### Docker Production Example

For production deployment with SSL and database:

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: my-app
    environment:
      - APP_HOST=0.0.0.0
      - APP_PORT=8080
      - DATABASE_URL=postgres://user:pass@db:5432/myapp
    depends_on:
      - db
    restart: unless-stopped
    networks:
      - app-network

  nginx:
    image: nginx:alpine
    container_name: my-app-proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/ssl/certs
    depends_on:
      - app
    restart: unless-stopped
    networks:
      - app-network

  db:
    image: postgres:15-alpine
    container_name: my-app-db
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
    networks:
      - app-network

volumes:
  postgres_data:

networks:
  app-network:
    driver: bridge
```

### Option 3: NixOS Self-Hosting (Recommended for NixOS users)

1. **Add as flake input** to your NixOS configuration:
   ```nix
   # In your flake.nix inputs
   htmx-gotempl-app = {
     url = "github:youruser/your-htmx-gotempl-app";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   ```

2. **Import and enable the service**:
   ```nix
   # In your NixOS configuration
   imports = [ htmx-gotempl-app.nixosModules.default ];
   
   services.htmx-gotempl-app = {
     enable = true;
     port = 8080;
     openFirewall = true;
   };
   ```

3. **Rebuild your system**:
   ```bash
   sudo nixos-rebuild switch --flake .#your-config
   ```

4. **Visit**: http://your-server:8080

#### NixOS Complete Example

Here's a complete NixOS configuration with SSL and reverse proxy:

```nix
# flake.nix
{
  description = "My NixOS server with HTMX Go Templ app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    htmx-gotempl-app = {
      url = "github:youruser/your-htmx-gotempl-app";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, htmx-gotempl-app, ... }: {
    nixosConfigurations.myserver = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        htmx-gotempl-app.nixosModules.default
        
        ({ config, pkgs, ... }: {
          # Enable the HTMX Go Templ app
          services.htmx-gotempl-app = {
            enable = true;
            port = 8080;
            host = "127.0.0.1";  # Only local access
            # openFirewall = false;  # We'll use nginx instead
          };

          # Nginx reverse proxy with SSL
          services.nginx = {
            enable = true;
            recommendedTlsSettings = true;
            recommendedOptimisation = true;
            recommendedGzipSettings = true;
            recommendedProxySettings = true;

            virtualHosts."your-domain.com" = {
              enableACME = true;
              forceSSL = true;
              
              locations."/" = {
                proxyPass = "http://127.0.0.1:8080";
                proxyWebsockets = true;
                extraConfig = ''
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto $scheme;
                '';
              };
            };
          };

          # Let's Encrypt SSL certificates
          security.acme = {
            acceptTerms = true;
            defaults.email = "admin@your-domain.com";
          };

          # Open firewall for HTTP/HTTPS
          networking.firewall.allowedTCPPorts = [ 80 443 ];

          # Basic system configuration
          time.timeZone = "UTC";
          system.stateVersion = "24.05";
        })
      ];
    };
  };
}
```

#### Deploy to NixOS

```bash
# Clone your configuration
git clone https://github.com/youruser/nixos-config
cd nixos-config

# Deploy to remote server
nixos-rebuild switch --flake .#myserver --target-host root@your-server

# Or deploy locally
sudo nixos-rebuild switch --flake .#myserver
```

## Project Structure

```
├── server/
│   ├── api/           # HTTP handlers
│   ├── config/        # Configuration management
│   ├── templates/     # Templ template files (.templ)
│   └── main.go        # Application entry point
├── web/
│   └── static/
│       └── css/       # Static CSS files
├── go.mod             # Go module file
├── Makefile          # Build and run commands
├── Dockerfile        # Docker build configuration
├── docker-compose.yml # Docker services configuration  
├── .dockerignore     # Docker ignore patterns
├── flake.nix         # Nix flake with NixOS module
├── flake.lock        # Nix flake lock file
├── nixos-example.nix # Example NixOS configuration
├── flake-usage-example.nix # Example flake usage
└── README.md         # This file
```

## Available Commands

### Local Development
- `make run` - Generate templates, build, and run the app
- `make build` - Build the application binary
- `make templ-generate` - Generate Go code from .templ files
- `make clean` - Clean build artifacts

### Docker Commands
- `make docker-build` - Build the Docker image
- `make docker-run` - Run the application in Docker
- `make docker-stop` - Stop the Docker container

### Nix Commands
- `nix develop` - Enter development shell with all dependencies
- `nix build` - Build the application package
- `nix run` - Build and run the application
- `nix flake check` - Validate flake configuration

### Help
- `make help` - Show all available commands

## Configuration Examples

### Environment Variables

Set these in your environment, Docker Compose, or NixOS configuration:

```bash
# Basic configuration
APP_PORT=8080          # Server port (default: 8080)
APP_HOST=0.0.0.0      # Server host (default: 0.0.0.0)

# Add your own environment variables in server/config/config.go
DATABASE_URL=postgres://user:pass@localhost/myapp
API_KEY=your-secret-key
```

### Docker Environment File

Create `.env` file for Docker development:

```env
# .env
APP_PORT=8080
APP_HOST=0.0.0.0
DATABASE_URL=postgres://user:pass@db:5432/myapp
API_KEY=dev-secret-key
```

Then reference in docker-compose.yml:

```yaml
services:
  app:
    build: .
    env_file: .env
    # or environment variables directly
    environment:
      - APP_PORT=8080
      - DATABASE_URL=postgres://user:pass@db:5432/myapp
```

## Configuration

Set these environment variables to customize the application:

- `APP_PORT` - Server port (default: 8080)
- `APP_HOST` - Server host (default: 0.0.0.0)

## Development Workflow

### Local Development
1. **Edit templates**: Modify `.templ` files in `server/templates/`
2. **Add handlers**: Create new handlers in `server/api/`
3. **Style components**: Edit CSS in `web/static/css/`
4. **Generate**: Run `make templ-generate` after template changes
5. **Test**: Run `make run` to see changes

### Docker Development
1. **Make changes**: Edit your code as needed
2. **Rebuild and run**: `docker-compose up --build`
3. **View logs**: `docker-compose logs -f app`
4. **Stop**: `docker-compose down`

### NixOS Development
1. **Enter dev shell**: `nix develop`
2. **Make changes**: Edit your code as needed
3. **Build package**: `nix build`
4. **Test service**: `nix run` or build and deploy to test system

## HTMX Integration

This template includes HTMX for dynamic content. Example usage:

```html
<!-- Basic HTMX button -->
<button 
    hx-get="/api/hello" 
    hx-target="#response"
    class="px-4 py-2 bg-blue-500 text-white rounded"
>
    Click Me!
</button>
<div id="response"></div>

<!-- Form with HTMX -->
<form hx-post="/api/submit" hx-target="#form-result">
    <input type="text" name="message" placeholder="Enter message" />
    <button type="submit">Submit</button>
</form>
<div id="form-result"></div>

<!-- Live search -->
<input 
    type="text" 
    name="search"
    hx-get="/api/search" 
    hx-trigger="keyup changed delay:300ms"
    hx-target="#search-results"
    placeholder="Search..."
/>
<div id="search-results"></div>

<!-- Auto-refresh content -->
<div 
    hx-get="/api/status" 
    hx-trigger="every 30s"
    hx-target="this"
>
    Loading status...
</div>
```

### Adding HTMX Handlers

```go
// In server/api/handlers.go
func (h *Handlers) SearchHandler(w http.ResponseWriter, r *http.Request) {
    query := r.URL.Query().Get("search")
    
    if r.Header.Get("HX-Request") == "true" {
        // Return HTML fragment for HTMX
        w.Header().Set("Content-Type", "text/html")
        results := searchResults(query)
        fragment := templates.SearchResults(results)
        fragment.Render(r.Context(), w)
        return
    }
    
    // Return JSON for direct API calls
    w.Header().Set("Content-Type", "application/json")
    results := searchResults(query)
    json.NewEncoder(w).Encode(results)
}
```

## Docker Features

- **Multi-stage build**: Optimized image size with builder pattern
- **Security**: Runs as non-root user
- **Health checks**: Built-in health monitoring
- **Hot reload**: Use `docker-compose up --build` for development
- **Environment variables**: Configurable through docker-compose.yml

## NixOS Features

- **Declarative deployment**: Configuration as code
- **Reproducible builds**: Same result every time
- **Systemd integration**: Proper service management with security hardening
- **Automatic firewall management**: Optional firewall rules
- **Rollback support**: Easy rollbacks with NixOS generations
- **Zero-downtime updates**: Atomic system updates

## Customization

### 1. Update Module Name

See the "Template Setup" section at the beginning of this README for complete renaming commands.

### 2. Add New Routes and Handlers

```go
// In server/api/handlers.go
func (h *Handlers) NewFeatureHandler(w http.ResponseWriter, r *http.Request) {
    // Your handler logic
    data := getData()
    
    if r.Header.Get("HX-Request") == "true" {
        // HTMX request - return HTML fragment
        fragment := templates.NewFeatureFragment(data)
        fragment.Render(r.Context(), w)
        return
    }
    
    // Regular request - return full page or JSON
    page := templates.NewFeaturePage(data)
    page.Render(r.Context(), w)
}

// Register in RegisterRoutes()
func (h *Handlers) RegisterRoutes(mux *http.ServeMux) {
    // ... existing routes
    mux.HandleFunc("/new-feature", h.NewFeatureHandler)
}
```

### 3. Create Templates

```go
// In server/templates/new-feature.templ
package templates

templ NewFeaturePage(data YourDataType) {
    @Base("New Feature") {
        <div class="container mx-auto p-4">
            <h1 class="text-2xl font-bold">New Feature</h1>
            @NewFeatureFragment(data)
        </div>
    }
}

templ NewFeatureFragment(data YourDataType) {
    <div id="feature-content">
        for _, item := range data.Items {
            <div class="p-2 border rounded">{ item.Name }</div>
        }
    </div>
}
```

```bash
# Generate templates
make templ-generate
```

### 4. Add Configuration Options

```go
// In server/config/config.go
type Config struct {
    Server      ServerConfig
    Database    DatabaseConfig  // Add new config sections
    ExternalAPI ExternalAPIConfig
}

type DatabaseConfig struct {
    URL             string
    MaxConnections  int
    TimeoutSeconds  int
}

// In LoadConfig()
func LoadConfig() Config {
    return Config{
        Server: ServerConfig{
            Port: getEnvAsString("APP_PORT", "8080"),
            Host: getEnvAsString("APP_HOST", "0.0.0.0"),
        },
        Database: DatabaseConfig{
            URL:             getEnvAsString("DATABASE_URL", ""),
            MaxConnections:  getEnvAsInt("DB_MAX_CONNECTIONS", 10),
            TimeoutSeconds:  getEnvAsInt("DB_TIMEOUT_SECONDS", 30),
        },
    }
}
```

## Production Deployment

### Docker Production
- Use environment-specific docker-compose files
- Set up proper logging and monitoring
- Configure reverse proxy (nginx/traefik)
- Add database services to docker-compose.yml
- Set up CI/CD pipelines

### NixOS Production
The flake includes a complete NixOS module with:
- **Systemd service** with security hardening
- **Automatic user/group creation**
- **Firewall management**
- **SSL/TLS support** (with nginx reverse proxy example)
- **Service monitoring** and automatic restarts

Additional configuration files are provided for reference:
- [`nixos-example.nix`](./nixos-example.nix) - Standalone NixOS configuration
- [`flake-usage-example.nix`](./flake-usage-example.nix) - Flake input usage example

These examples include:
- SSL certificates with Let's Encrypt
- Nginx reverse proxy configuration
- Proper security settings
- Production-ready systemd service configuration

## License

This template is provided as-is for starting new projects.
