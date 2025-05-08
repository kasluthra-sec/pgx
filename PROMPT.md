We need to refactor this project so that it is using the safesql package while trying to keep the API and implementation as similar as possible to the current one. Documentation for safesql can be found here on https://pkg.go.dev/github.com/google/go-safeweb/safesql and also contains examples.
Do not use uncheckedconversions or legacyconversions, if this is the only way to proceed, then take note of where this is required.
Do not convert safesql.TrustedSQLString to a regular string unless it is the only way to proceed or it is safe to do so.

To prepare for the refactoring, analyse the call path for the QueryRow method in conn.go as used by our test script in sec-test/sec-test.go. You will need to make changes to the QueryRow method in conn.go to make it compatible with safesql. I have already updated the method to use safesql.TrustedSQLString instead of a regular string and pass that on to the c.Query method. You see that it throws an error becauase Query still expects a string. Go update the Query method so that it supports safesql.TrustedSQLString and passes that on to any and all methods that it uses. In turn, you also have to update those methods and any and all methods that they use and so forth until you have updated all methods that are being used by Query. Do not patch any other methods including other methods that call Query. Focus on the call path used by sec-test.go first. 
Do NOT patch any of the tests yet. They will fail and that is ok for now, we come back to this later.
If you have to introduce imports, only use "github.com/google/go-safeweb/safesql" and nothing else. If other imports are needed, check with me first and I can fix those dependencies before you proceed.

The idea is that you run cd sec-test && go run sec-test.go regularly to see what errors we still get and then fix these.
Start with crafting a refactor plan. Create a TODO list in a new file called TODO.md and add any tasks that you think are required to make the refactoring work including a detailed list of subtasks. You will use this list later to track the progress of the refactoring.

## Rules 
- Limit any suggested changes only to make the Query method and any downstream methods work and do not suggest any changes that are not required to make the Query method and any downstream methods work
- Do not make any modifications to sec-test.go
- Avoid using sql.String() altogether as this converts a TrustedSQLString to a regular string which we must avoid
- Avoid using uncheckedconversions or legacyconversions, if this is the only way to proceed, then take note of where this is required
- Only call methods that exist, do not make up method names
- Check your work for syntax errors and logic errors and correctness
- Test using sec-test.go but do not change the test script
- Do NOT run other tests

The sqlx package has been refactored earlier to work with safesql and can be referenced for examples: https://github.com/jmoiron/sqlx/pull/958/files.
