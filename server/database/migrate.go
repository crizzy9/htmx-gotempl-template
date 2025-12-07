package database

import (
	"fmt"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"myapp/server/config"
)

// RunMigrations runs database migrations
func RunMigrations(cfg *config.Config, migrationsPath string) error {
	db, err := Connect(cfg)
	if err != nil {
		return fmt.Errorf("failed to connect to database: %w", err)
	}
	defer db.Close()

	driver, err := postgres.WithInstance(db, &postgres.Config{})
	if err != nil {
		return fmt.Errorf("failed to create postgres driver: %w", err)
	}

	m, err := migrate.NewWithDatabaseInstance(
		fmt.Sprintf("file://%s", migrationsPath),
		"postgres",
		driver,
	)
	if err != nil {
		return fmt.Errorf("failed to create migrate instance: %w", err)
	}

	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("failed to run migrations: %w", err)
	}

	return nil
}

// CreateMigration creates a new migration file
func CreateMigration(name, migrationsPath string) error {
	// This would typically use migrate CLI tool, but for simplicity
	// we'll document the manual process in the README
	fmt.Printf("To create a new migration, run:\n")
	fmt.Printf("migrate create -ext sql -dir %s -seq %s\n", migrationsPath, name)
	return nil
}
