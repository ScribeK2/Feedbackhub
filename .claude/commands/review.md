# Review Recent Code Changes

Review recent code changes to ensure they meet project standards and DHH's Rails conventions.

## Steps

### 1. Identify modifications

Examine git status and commit history to locate changed code:

```bash
git status
git diff --name-only HEAD~5
git log --oneline -10
```

### 2. DHH Code Review

Use the DHH Code Reviewer sub-agent to evaluate all changed files against Rails best practices and DHH's standards for elegance.

### 3. Review the changes

For each modified file:
- Check code style and conventions
- Verify proper error handling
- Look for potential bugs or edge cases
- Ensure tests exist for new functionality

### 3. Check Rails conventions

Verify adherence to Rails best practices:
- RESTful routes
- Strong parameters
- Proper use of callbacks
- N+1 query prevention

### 4. Check Phlex conventions

For view changes:
- Component structure
- Proper use of PhlexyUI
- Stimulus/Turbo integration

### 5. Verify testing

Confirm all tests pass following modifications:

```bash
rails test
```

### 6. Document findings

Summarize review results:
- Issues found
- Suggestions for improvement
- Tests that should be added
