# Test Execution Rules

Guidelines for running and analyzing tests.

## Always Use Test Runner Agent

When tests need to be run, always use the test-runner sub-agent. This ensures:
- Full test output is captured
- Results are properly analyzed
- Context usage is optimized
- Issues are clearly surfaced

## Test Commands

```bash
# Full test suite
rails test

# Specific test file
rails test test/models/user_test.rb

# Specific test by line
rails test test/models/user_test.rb:42

# System tests
rails test:system

# With verbose output
rails test -v
```

## Analysis Requirements

After running tests, always report:
1. Total tests, assertions, failures, errors
2. Specific failure messages with file:line
3. Any deprecation warnings
4. Recommendations for fixes

## Test Failure Protocol

When a test fails:
1. Read the failure message carefully
2. Check if the test is correct before changing implementation
3. Understand what the test expects vs what it got
4. Fix either the test or implementation as appropriate
5. Re-run to verify the fix

## Never Mock Unless Necessary

Prefer real objects over mocks. Only use mocks when:
- External API calls would be made
- Time-sensitive operations
- Truly unavoidable dependencies
