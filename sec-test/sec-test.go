package main

import (
	"context"
	"fmt"
	"os"

	"github.com/google/go-safeweb/safesql"
	"github.com/jackc/pgx/v5"
)

func main() {
	connStr := "host=localhost port=5015 user=pgx_md5 password=secret dbname=pgx_test sslmode=disable"
	conn, err := pgx.Connect(context.Background(), connStr)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Unable to connect to database: %v\n", err)
		os.Exit(1)
	}
	defer conn.Close(context.Background())

	var version string
	err = conn.QueryRow(context.Background(), safesql.New("SELECT version();")).Scan(&version)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to query version: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("Postgres version:", version)
}
