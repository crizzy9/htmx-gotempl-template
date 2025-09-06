package config

import (
	"os"
	"strconv"
)

// Config holds all application configuration
type Config struct {
	Server ServerConfig
}

// ServerConfig holds server-related configuration
type ServerConfig struct {
	Port int
	Host string
}

// LoadConfig loads configuration from environment variables or defaults
func LoadConfig() *Config {
	cfg := &Config{
		Server: ServerConfig{
			Port: getEnvAsInt("APP_PORT", 8080),
			Host: getEnvAsString("APP_HOST", "0.0.0.0"),
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
