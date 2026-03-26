# Debug an Issue

Debug a specific issue using the appropriate sub-agents and testing tools.

## Steps

Here is the issue to debug: $ARGUMENT

### 1. Understand the problem

Read the issue description carefully. If more information is needed, ask clarifying questions.

### 2. Analyze the code

Use the Code Analyzer sub-agent to examine the relevant code and trace the logic flow to identify potential issues.

### 3. Run tests

Use the Test Runner sub-agent to run relevant tests and analyze any failures to understand what's breaking.

### 4. Identify the root cause

Based on the code analysis and test results, identify the root cause of the issue.

### 5. Fix the issue

Implement the fix using the appropriate sub-agent:
- Rails Programmer for backend fixes
- Phlex Developer for view/component fixes

### 6. Test the fix

Run tests to verify the fix works and doesn't break anything else.

### 7. Review the fix

Use the DHH Code Reviewer to ensure the fix meets Rails standards and is elegant.

### 8. Summary

Provide a summary of what was wrong, how it was fixed, and what tests were added or modified.
