# PATCHES for pgx to be compatible with safesql

## Overview

This document outlines the changes required to make the pgx library compatible with the `github.com/google/go-safeweb/safesql` package. The goal is to prevent SQL injection vulnerabilities by ensuring that only trusted SQL strings can be executed.

## Analysis of Query Method

The current `Query` method in `conn.go` accepts a string parameter for SQL queries:

```go
func (c *Conn) Query(ctx context.Context, sql string, args ...any) (Rows, error) {
    // Implementation
}
```

The safesql package introduces a `TrustedSQLString` type that ensures SQL strings are safe by construction. The `TrustedSQLString` can only be created from compile-time constants using the `safesql.New()` function, making it impossible to accidentally execute user-controlled SQL strings.

## Required Changes

### 1. Modify Query Method Signature

Change the `Query` method to accept `safesql.TrustedSQLString` instead of a plain string:

```go
func (c *Conn) Query(ctx context.Context, sql safesql.TrustedSQLString, args ...any) (Rows, error)
```

Inside the method, use `sql.String()` to get the underlying string value.

### 2. Downstream Methods

The following downstream methods also need to be updated to use `safesql.TrustedSQLString`:

- `Conn.Exec`
- `Conn.Prepare`
- `Conn.CopyFrom`
- `Tx.Query`
- `Tx.Exec`
- `Tx.Prepare`
- Any other methods that accept SQL strings directly

### 3. Batch Operations

Update the Batch struct and related methods to use `safesql.TrustedSQLString` for SQL queries:

```go
type BatchItem struct {
    SQL  safesql.TrustedSQLString
    Args []any
}
```

### 4. Internal Helper Methods

Update internal methods that process SQL strings to handle `safesql.TrustedSQLString`:

- `sanitizeForSimpleQuery`
- `deallocateInvalidatedCachedStatements`
- Any other methods that process SQL strings

## Detailed Changes

### conn.go

1. Update the `Query` method:
```go
func (c *Conn) Query(ctx context.Context, sql safesql.TrustedSQLString, args ...any) (Rows, error) {
    if c.queryTracer != nil {
        ctx = c.queryTracer.TraceQueryStart(ctx, c, TraceQueryStartData{SQL: sql.String(), Args: args})
    }
    
    // Rest of the method using sql.String() where the original sql string was used
    // ...
}
```

2. Update the `Exec` method:
```go
func (c *Conn) Exec(ctx context.Context, sql safesql.TrustedSQLString, args ...any) (pgconn.CommandTag, error) {
    // Implementation using sql.String()
}
```

3. Update the `Prepare` method:
```go
func (c *Conn) Prepare(ctx context.Context, name string, sql safesql.TrustedSQLString) (*pgconn.StatementDescription, error) {
    // Implementation using sql.String()
}
```

### tx.go

1. Update the `Query` method:
```go
func (tx *Tx) Query(ctx context.Context, sql safesql.TrustedSQLString, args ...any) (Rows, error) {
    // Implementation using sql.String()
}
```

2. Update the `Exec` method:
```go
func (tx *Tx) Exec(ctx context.Context, sql safesql.TrustedSQLString, args ...any) (pgconn.CommandTag, error) {
    // Implementation using sql.String()
}
```

### batch.go

1. Update the `Queue` method:
```go
func (b *Batch) Queue(sql safesql.TrustedSQLString, args ...any) *Batch {
    // Implementation using sql.String()
}
```

## Implementation Notes

1. When implementing these changes, avoid using `sql.String()` directly in places where it's not necessary. Instead, pass the `TrustedSQLString` object through the call chain and only call `String()` when interfacing with the underlying pgconn package.

2. The `QueryRow` method is already using `safesql.TrustedSQLString` in its signature, but it's calling `Query` with `sql.String()`. This should be updated to pass the `TrustedSQLString` directly to the updated `Query` method.

3. Be careful with methods that build SQL dynamically (like `CopyFrom`). These may need special handling to ensure they work with the safesql package's constraints.

## Potential Challenges

1. Methods that build SQL dynamically might be difficult to adapt to the safesql model. In these cases, consider using helper functions from the safesql package like `TrustedSQLStringConcat` and `TrustedSQLStringJoin`.

2. Some third-party libraries or extensions might expect plain strings. Interfaces with these libraries might need adapters.

## Testing Strategy

1. Update existing tests to use `safesql.New()` for SQL strings.
2. Add tests that verify compile-time errors when trying to pass untrusted strings.
3. Ensure all existing functionality continues to work with the new types.
