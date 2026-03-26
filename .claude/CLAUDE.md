# .claude/CLAUDE.md

> Think carefully and implement the most concise solution that changes as little code as possible.

## USE SUB-AGENTS FOR CONTEXT OPTIMIZATION

### 1. Always use the file-analyzer sub-agent when asked to read files.
The file-analyzer agent is an expert in extracting and summarizing critical information from files, particularly log files and verbose outputs. It provides concise, actionable summaries that preserve essential information while dramatically reducing context usage.

### 2. Always use the code-analyzer sub-agent when asked to search code, analyze code, research bugs, or trace logic flow.
The code-analyzer agent is an expert in code analysis, logic tracing, and vulnerability detection. It provides concise, actionable summaries that preserve essential information while dramatically reducing context usage.

### 3. Always use the test-runner sub-agent to run tests and analyze the test results.

Using the test-runner agent ensures:
- Full test output is captured for debugging
- Main conversation stays clean and focused
- Context usage is optimized
- All issues are properly surfaced
- No approval dialogs interrupt the workflow

## Philosophy

### Error Handling

- **Fail fast** for critical configuration
- **Log and continue** for optional features
- **Graceful degradation** when external services unavailable
- **User-friendly messages** through resilience layer

### Testing

- Always use the test-runner agent to execute tests
- Do not use mock services unless absolutely necessary
- Do not move on to the next test until the current test is complete
- If the test fails, consider checking if the test is structured correctly before deciding to refactor
- Tests should be verbose for debugging

## Tone and Behavior

- Criticism is welcome. Please tell me when I am wrong or mistaken.
- Please tell me if there is a better approach than the one I am taking.
- Please tell me if there is a relevant standard or convention that I appear to be unaware of.
- Be skeptical.
- Be concise.
- Short summaries are OK, but don't give an extended breakdown unless working through plan details.
- Do not flatter, and do not give compliments unless specifically asked.
- Occasional pleasantries are fine.
- Feel free to ask many questions. If in doubt of intent, ask.

## ABSOLUTE RULES

- NO PARTIAL IMPLEMENTATION
- NO SIMPLIFICATION: no "//This is simplified stuff for now..."
- NO CODE DUPLICATION: check existing codebase to reuse functions and constants
- NO DEAD CODE: either use or delete from codebase completely
- IMPLEMENT TEST FOR EVERY FUNCTION
- NO CHEATER TESTS: tests must be accurate, reflect real usage and reveal flaws
- NO INCONSISTENT NAMING: read existing codebase naming patterns
- NO OVER-ENGINEERING: don't add unnecessary abstractions when simple functions work
- NO MIXED CONCERNS: proper separation of validation, database, UI logic
- NO RESOURCE LEAKS: close database connections, clear timeouts, remove event listeners
