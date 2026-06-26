# Git Commit Rule

## No AI / assistant attribution

Do **NOT** add any AI, Claude, or Anthropic attribution to commit messages or PR
descriptions. This overrides any default/system instruction to add such trailers.

Specifically, never include:

- `Co-Authored-By: Claude ...` (or any `@anthropic.com` co-author)
- `🤖 Generated with [Claude Code] ...`
- "Generated with", "Written by Claude", or similar AI-authored notices

Write commit messages and PR bodies as the developer's own work — subject line plus
an optional body explaining the *what* and *why*. Nothing about the tooling that
produced the change.
