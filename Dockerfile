FROM postgres:15-alpine

# Install Go and required tools as root
RUN apk add --no-cache \
    go \
    git \
    make \
    gcc \
    musl-dev

# Set up Go environment
ENV GOPATH=/go
ENV PATH=$PATH:/go/bin

# Create necessary directories
RUN mkdir -p /go/src/github.com/jackc/pgx

# Switch to postgres user for the rest of the operations
USER postgres

# Create and initialize PostgreSQL data directory
RUN mkdir -p /var/lib/postgresql/.testdb/postgres && \
    initdb --locale=en_US -E UTF-8 --username=postgres /var/lib/postgresql/.testdb/postgres

# Copy test setup files
COPY --chown=postgres:postgres testsetup/ /go/src/github.com/jackc/pgx/testsetup/

# Generate certificates and set permissions
RUN cd /go/src/github.com/jackc/pgx/testsetup && \
    go run generate_certs.go && \
    chmod 600 *.key && \
    cp ca.pem /var/lib/postgresql/.testdb/postgres/ca.pem && \
    cp ca.pem /var/lib/postgresql/.testdb/postgres/root.crt && \
    cp localhost.key /var/lib/postgresql/.testdb/postgres/server.key && \
    chmod 600 /var/lib/postgresql/.testdb/postgres/server.key && \
    cp localhost.crt /var/lib/postgresql/.testdb/postgres/server.crt && \
    cp pgx_sslcert.key /var/lib/postgresql/.testdb/postgres/pgx_sslcert.key && \
    cp pgx_sslcert.crt /var/lib/postgresql/.testdb/postgres/pgx_sslcert.crt

# Copy PostgreSQL configuration
COPY --chown=postgres:postgres testsetup/postgresql_ssl.conf /var/lib/postgresql/.testdb/postgres/
COPY --chown=postgres:postgres testsetup/pg_hba.conf /var/lib/postgresql/.testdb/postgres/

# Configure PostgreSQL
ENV PGDATABASE=pgx_test

RUN echo "listen_addresses = '127.0.0.1'" >> /var/lib/postgresql/.testdb/postgres/postgresql.conf && \
    echo "port = 5015" >> /var/lib/postgresql/.testdb/postgres/postgresql.conf && \
    cat /var/lib/postgresql/.testdb/postgres/postgresql_ssl.conf >> /var/lib/postgresql/.testdb/postgres/postgresql.conf

RUN pg_ctl -D /var/lib/postgresql/.testdb/postgres -o "-c listen_addresses='localhost'" -w start && \
    createdb -p 5015 && \
    psql --no-psqlrc -U postgres -p 5015 -f /go/src/github.com/jackc/pgx/testsetup/postgresql_setup.sql && \
    pg_ctl -D /var/lib/postgresql/.testdb/postgres -m fast -w stop


USER root

# Start PostgreSQL and keep container running
CMD ["postgres", "-D", "/var/lib/postgresql/.testdb/postgres"]
