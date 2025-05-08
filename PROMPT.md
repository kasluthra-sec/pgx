# Prompt

## Instructions 
- Create a new file called PATCHES.md
- Analyse how the Query() method works in the pgx package and make recommendations for how to make pgx compatible with safesql 
- We will also need to make all downstream methods compatible with safesql
- Add a list of changes you'd suggest making in PATCHES.md

## Rules 
- Limit any suggested changes only to make the Query method work and do not suggest any changes that are not required to make the Query method work
- Do not make any modifications to sec-test.go
- Do not use sql.String() anywhere. If this is the only way to proceed, then take note of where this is required
- Do not use uncheckedconversions or legacyconversions anywhere. If this is the only way to proceed, then take note of where this is required
- Only call methods that exist, do not make up method names

## Examples
sqlx was forked and patched to work with safesql - https://github.com/jmoiron/sqlx/pull/958/files
