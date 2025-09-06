# AI Agents Development Guide

This document provides context for AI development assistants working on this HTMX + Go + Templ application.

## Project Architecture

### Tech Stack
- **Backend**: Go with standard library HTTP server
- **Frontend**: HTMX for dynamic interactions, Tailwind CSS for styling  
- **Templates**: Templ (type-safe Go HTML templates)
- **Build**: Makefile for common tasks
- **Deployment**: Docker ready

### Key Conventions

1. **Module Structure**: 
   - Change module name from `myapp` to actual project name
   - Update all import paths accordingly

2. **Template Development**:
   - Write `.templ` files in `server/templates/`
   - Run `make templ-generate` after changes
   - Templates generate corresponding `_templ.go` files

3. **Handler Pattern**:
   - HTTP handlers in `server/api/handlers.go`
   - Register routes in `RegisterRoutes()` method
   - Return JSON for API endpoints, HTML fragments for HTMX

4. **HTMX Integration**:
   - Check `HX-Request` header to differentiate HTMX requests
   - Return HTML fragments for HTMX, full JSON for direct API calls
   - Use HTMX attributes: `hx-get`, `hx-post`, `hx-target`, `hx-trigger`

## Development Workflow

### Before Making Changes
1. **Understand the request**: Read user requirements carefully
2. **Check existing structure**: Review current handlers, templates, and routes
3. **Plan changes**: Identify what files need modification

### Adding New Features
1. **Templates**: Create/modify `.templ` files for UI components
2. **Handlers**: Add new handlers in `api/handlers.go` 
3. **Routes**: Register new routes in `RegisterRoutes()`
4. **Generate**: Run `make templ-generate` for template changes
5. **Test**: Use `make run` to test changes locally

### Common Tasks

#### Adding a New Page/Route
```go
// In handlers.go
func (h *Handlers) NewPageHandler(w http.ResponseWriter, r *http.Request) {
    page := templates.NewPage(h.Config)
    err := page.Render(r.Context(), w)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
    }
}

// In RegisterRoutes()
r.HandleFunc("/new-page", h.NewPageHandler)
```

#### Creating HTMX Endpoint
```go
func (h *Handlers) HTMXHandler(w http.ResponseWriter, r *http.Request) {
    data := getDataFromRequest(r)
    
    if r.Header.Get("HX-Request") == "true" {
        // Return HTML fragment for HTMX
        w.Header().Set("Content-Type", "text/html")
        fragment := templates.DataFragment(data)
        fragment.Render(r.Context(), w)
    } else {
        // Return JSON for direct API access
        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(data)
    }
}
```

#### Adding Configuration
```go
// In config/config.go - add to Config struct
type Config struct {
    Server   ServerConfig
    NewField string
}

// In LoadConfig()
cfg.NewField = getEnvAsString("APP_NEW_FIELD", "default_value")
```

## File Locations

- **Templates**: `server/templates/*.templ` (source files)
- **Generated Templates**: `server/templates/*_templ.go` (auto-generated)
- **Handlers**: `server/api/handlers.go`
- **Config**: `server/config/config.go`
- **Static Assets**: `web/static/css/styles.css`
- **Main**: `server/main.go`

## Build Commands

- `make templ-generate` - Generate Go code from .templ files
- `make build` - Build binary (includes templ generation)
- `make run` - Build and run application
- `make clean` - Clean build artifacts

## Best Practices

1. **Always generate templates** after `.templ` file changes
2. **Handle both HTMX and direct requests** in API endpoints
3. **Use semantic HTML** with appropriate HTMX attributes
4. **Follow Go conventions** for naming and structure
5. **Test locally** with `make run` before considering complete
6. **Update imports** when changing module name
7. **Use environment variables** for configuration

## Common Patterns

### HTMX Form Submission
```html
<form hx-post="/api/submit" hx-target="#result">
    <input type="text" name="data" />
    <button type="submit">Submit</button>
</form>
<div id="result"></div>
```

### Dynamic Content Loading
```html
<div hx-get="/api/content" hx-trigger="load" hx-target="this">
    Loading...
</div>
```

### Search with Debounce
```html
<input 
    type="text" 
    hx-get="/api/search" 
    hx-trigger="keyup changed delay:500ms" 
    hx-target="#search-results"
/>
```

This guide should help AI agents understand the project structure and development patterns for effective assistance.