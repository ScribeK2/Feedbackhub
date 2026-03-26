# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> Think carefully and implement the most concise solution that changes as little code as possible.

## Essential Information

This is a Rails 8 + Phlex application called FeedbackHub. **Always check the `/docs/` folder for detailed documentation before making changes.**

## Quick Start

```bash
bin/rails server   # Start development server
bin/dev            # Start with Procfile (CSS watching)
rails db:migrate   # Run pending migrations
rails test         # Run test suite
```

## Technology Stack

- **Framework**: Rails 8.1
- **Views**: Phlex 2.4 + PhlexyUI (DaisyUI components)
- **Frontend**: Turbo, Stimulus, Tailwind CSS
- **Database**: SQLite with Solid Queue/Cache/Cable
- **Rich Text**: Lexxy

## Documentation Structure

Start with `/docs/overview.md` which indexes all documentation:

- **[Architecture](docs/architecture.md)** - Application structure and patterns
- **[File System Structure](docs/file_system_structure.md)** - Directory organization
- **[Phlex Architecture](docs/phlex_architecture.md)** - View layer patterns
- **[Phlex Components](docs/phlex_components.md)** - Component design and usage
- **[Tailwind Usage](docs/tailwind_usage.md)** - Styling patterns with DaisyUI
- **[Phlex Scaffolding](docs/phlex_scaffolding.md)** - Generate Phlex views with scaffolds

## Critical Database Rules

### NEVER WIPE OR RESET THE DEVELOPMENT DATABASE

- **NEVER run `rails db:drop` in development**
- **NEVER run `rails db:reset` in development**
- **NEVER run `rails db:setup` on an existing database**
- **NEVER run destructive ActiveRecord commands like `Model.destroy_all` in development console**
- The development database contains important data that must be preserved
- Only run migrations that are additive or safely reversible
- If you need to test something destructive, use the test database only

### NEVER KILL THE DEVELOPMENT SERVER

- **NEVER kill the Rails server process (pid in tmp/pids/server.pid)**
- **NEVER kill background bash processes running `bin/dev` or `bin/rails server`**
- If you need to test something, use the existing running server

## USE SUB-AGENTS FOR CONTEXT OPTIMIZATION

### 1. Always use the file-analyzer sub-agent when asked to read files.
The file-analyzer agent is an expert in extracting and summarizing critical information from files, particularly log files and verbose outputs.

### 2. Always use the code-analyzer sub-agent when asked to search code, analyze code, research bugs, or trace logic flow.
The code-analyzer agent is an expert in code analysis, logic tracing, and vulnerability detection.

### 3. Always use the test-runner sub-agent to run tests and analyze the test results.
Using the test-runner agent ensures full test output is captured for debugging.

## Philosophy

### Error Handling

- **Fail fast** for critical configuration
- **Log and continue** for optional features
- **Graceful degradation** when external services unavailable
- **User-friendly messages** through resilience layer

### Testing

- Always use the test-runner agent to execute tests
- Do not use mock services unless absolutely necessary
- Tests should be verbose for debugging
- If a test fails, check if the test is structured correctly before refactoring

## Tone and Behavior

- Criticism is welcome. Please tell me when I am wrong or mistaken.
- Please tell me if there is a better approach than the one I am taking.
- Please tell me if there is a relevant standard or convention that I appear to be unaware of.
- Be skeptical and concise.
- Do not flatter or give compliments unless specifically asked.
- Feel free to ask questions. If in doubt of intent, ask.

## ABSOLUTE RULES

- NO PARTIAL IMPLEMENTATION
- NO SIMPLIFICATION: no "//This is simplified for now..."
- NO CODE DUPLICATION: check existing codebase to reuse functions and constants
- NO DEAD CODE: either use or delete completely
- IMPLEMENT TEST FOR EVERY FUNCTION
- NO CHEATER TESTS: tests must reflect real usage and reveal flaws
- NO INCONSISTENT NAMING: read existing codebase naming patterns
- NO OVER-ENGINEERING: don't add unnecessary abstractions
- NO MIXED CONCERNS: proper separation of concerns
- NO RESOURCE LEAKS: close connections, clear timeouts, remove listeners
