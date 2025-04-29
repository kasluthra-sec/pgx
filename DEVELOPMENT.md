# Docker Development Environment

This project uses Docker to provide a consistent development environment for pgx. The setup includes both a PostgreSQL server and a Go development environment.

## Prerequisites

- Docker and Docker Compose installed on your system

## Getting Started

1. Build and start the development environment:

```bash
docker compose up --build
```

2. Run tests:

```bash
docker compose exec pgx-dev go test ./...
```

3. View skipped tests:

```bash
docker compose exec pgx-dev go test ./... -v | grep SKIP
```

## Environment Details

The Docker setup includes:

- PostgreSQL 15 server running on port 5015
- Go development environment with all necessary dependencies
- Pre-configured SSL certificates for TLS testing
- Support for all test connection types (TCP, Unix socket, SSL, etc.)

## Stopping the Environment

To stop the development environment:

```bash
docker compose down
```

This will stop and remove all containers, but will keep the volumes for future use.
