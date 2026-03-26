# Project Overview

FeedbackHub is a Rails 8 application using the modern Rails stack with Phlex components for views.

## Tech Stack

- **Backend**: Rails 8.1, Ruby
- **Views**: Phlex 2.4 components with PhlexyUI (DaisyUI)
- **Frontend**: Stimulus controllers, Turbo
- **Styling**: Tailwind CSS + DaisyUI
- **Database**: SQLite (Solid suite for production-ready infrastructure)
- **Rich Text**: Lexxy editor
- **Testing**: Minitest, Capybara for system tests

## Documentation Structure

- `/docs/` - Project documentation
  - `overview.md` - This file, project summary
  - `architecture.md` - Application architecture and patterns
  - `file_system_structure.md` - Directory organization
  - `phlex_architecture.md` - Phlex view layer patterns
  - `phlex_components.md` - Component design and usage
  - `phlex_scaffolding.md` - Scaffold generator for Phlex views
  - `tailwind_usage.md` - Tailwind CSS and DaisyUI patterns

## Architecture

The application follows standard Rails conventions with Phlex components replacing traditional ERB views:

- **Models**: Business logic and data persistence
- **Controllers**: Handle requests, orchestrate actions
- **Phlex Views**: Ruby-based view classes in `/app/views/`
- **Components**: Reusable UI components in `/app/views/components/`
- **Stimulus Controllers**: Client-side JavaScript behavior in `/app/javascript/controllers/`
- **Styles**: Tailwind CSS utilities via DaisyUI/PhlexyUI

## Quick Reference

| Task | Command |
|------|---------|
| Start dev server | `bin/dev` |
| Run tests | `rails test` |
| Run migrations | `rails db:migrate` |
| Rails console | `rails console` |
| Generate model | `rails g model Name field:type` |
