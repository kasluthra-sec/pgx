# Prompt

## Instructions 
- If it doesn't already exist, create a new file called PATCHES.md and if it already exists, update it with any new changes or modifications
- Analyse how the Query() method works in the pgx package and provide instructions for how to make Query() compatible with safesql
- We will also need to make all downstream methods compatible with safesql
- In PATCHES.md, document a list of detailed code changes you'd suggest to achieve Query() compatibility with safesql

## Rules 
- Limit any suggested changes only to make the Query method and any downstream methods work and do not suggest any changes that are not required to make the Query method and any downstream methods work
- Do not make any modifications to sec-test.go
- Avoid using sql.String() altogether
- Avoid using uncheckedconversions or legacyconversions, if this is the only way to proceed, then take note of where this is required
- Only call methods that exist, do not make up method names

## Examples
sqlx was forked and patched to work with safesql - https://github.com/jmoiron/sqlx/pull/958/files
