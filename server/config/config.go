package config

import (
	"os"
	"strconv"
)

// Config holds all application configuration
type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
}

// ServerConfig holds server-related configuration
type ServerConfig struct {
	Port int
	Host string
}

// DatabaseConfig holds database-related configuration
type DatabaseConfig struct {
	Host     string
	Port     int
	User     string
	Password string
	Name     string
	SSLMode  string
}

// LoadConfig loads configuration from environment variables or defaults
func LoadConfig() *Config {
	cfg := &Config{
		Server: ServerConfig{
			Port: getEnvAsInt("APP_PORT", 8080),
			Host: getEnvAsString("APP_HOST", "0.0.0.0"),
		},
		Database: DatabaseConfig{
			Host:     getEnvAsString("DB_HOST", "localhost"),
			Port:     getEnvAsInt("DB_PORT", 5432),
			User:     getEnvAsString("DB_USER", "postgres"),
			Password: getEnvAsString("DB_PASSWORD", "postgres"),
			Name:     getEnvAsString("DB_NAME", "myapp_db"),
			SSLMode:  getEnvAsString("DB_SSLMODE", "disable"),
		},
	}

	return cfg
}

// Helper function to get an environment variable as a string with a default value
func getEnvAsString(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultValue
}

// Helper function to get an environment variable as an integer with a default value
func getEnvAsInt(key string, defaultValue int) int {
	if value, exists := os.LookupEnv(key); exists {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}
