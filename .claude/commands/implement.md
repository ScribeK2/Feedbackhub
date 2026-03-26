# Implement a Feature

Implement a feature following the specification and using specialized sub-agents.

## Steps

Here is the specification to implement: $ARGUMENT

### 1. Read and understand the spec

Read the provided specification thoroughly. If the spec references other documentation, read those files as well.

### 2. Use Rails Programmer for backend implementation

Use the Rails Programmer sub-agent to implement the Rails backend components:
- Models, controllers, and routes
- Database migrations if needed
- Rails tests (controller and model tests)

Pass the specification and any relevant documentation to the Rails Programmer agent.

### 3. Use Phlex Developer for frontend implementation

Use the Phlex Developer sub-agent to implement the view components:
- Phlex components for the UI
- Stimulus controllers for interactive behavior
- Turbo Frames/Streams for dynamic updates

Pass the specification and any relevant documentation to the Phlex Developer agent.

### 4. Review with DHH Code Reviewer

Once implementation is complete, use the DHH Code Reviewer sub-agent to review all the code that was written and ensure it meets Rails standards for elegance.

### 5. Write comprehensive tests

Create additional tests:
- System tests for end-to-end user flows
- Component tests
- Integration tests as needed

### 6. Final verification

Run all tests to ensure the implementation works correctly and meets the specification requirements.

### 7. Summary

Provide a summary of what was implemented, which files were created/modified, and confirm that all tests pass.
