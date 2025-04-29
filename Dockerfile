FROM golang:1.23-alpine

WORKDIR /go/src/github.com/jackc/pgx

# Install required tools
RUN apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev

# Create necessary directories
RUN mkdir -p .testdb

CMD ["/bin/sh"]
