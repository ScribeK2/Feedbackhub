# Standard Patterns

Common patterns that all commands and agents should follow.

## Core Principles

1. **Fail Fast** - Check critical prerequisites, then proceed
2. **Trust the System** - Don't over-validate things that rarely fail
3. **Clear Errors** - When something fails, say exactly what and how to fix it
4. **Minimal Output** - Show what matters, skip decoration

## Standard Validations

### Minimal Preflight
Only check what's absolutely necessary:
- If command needs specific file: check it exists
- If missing, tell user exact command to fix it

### Error Messages
Keep them short and actionable:
```
File not found: Run `rails generate model User`
```

## Standard Output Formats

### Success Output
```
Done
  - Key result 1
  - Key result 2
Next: Single suggested action
```

### List Output
```
3 items found:
- item 1: key detail
- item 2: key detail
- item 3: key detail
```

## Common Patterns to Avoid

### DON'T: Over-validate
```
# Bad - too many checks
1. Check directory exists
2. Check permissions
3. Check git status
4. Validate every field
```

### DO: Check essentials
```
# Good - just what's needed
1. Check target exists
2. Try the operation
3. Handle failure clearly
```

### DON'T: Verbose output
```
# Bad - too much information
Starting operation...
Validating prerequisites...
Step 1 complete
Step 2 complete
Statistics: ...
Tips: ...
```

### DO: Concise output
```
# Good - just results
Done: 3 files created
Failed: auth.test.rb (syntax error - line 42)
```

## Quick Reference

### Status Indicators
- Success (use sparingly)
- Error (always with solution)
- Warning (only if action needed)

### Exit Strategies
- Success: Brief confirmation
- Failure: Clear error + exact fix
- Partial: Show what worked, what didn't

## Remember

Focus on the happy path, fail gracefully when things go wrong.
