# Technology Context

## Stack Overview

| Layer | Technology |
|-------|------------|
| Framework | Rails 8.1 |
| Views | Phlex 2.4 + PhlexyUI |
| Frontend | Turbo, Stimulus, Tailwind CSS |
| Database | SQLite 3 |
| Background Jobs | Solid Queue |
| Caching | Solid Cache |
| WebSockets | Solid Cable |
| Rich Text | Lexxy |

## Key Dependencies

### Core
- `rails` ~> 8.1.3 - Web framework
- `sqlite3` >= 2.1 - Database
- `puma` >= 5.0 - Web server

### Views
- `phlex` ~> 2.4 - View components
- `phlex-rails` ~> 2.4 - Rails integration
- `phlexy_ui` ~> 0.3 - DaisyUI components

### Frontend
- `turbo-rails` - SPA-like page updates
- `stimulus-rails` - JavaScript controllers
- `tailwindcss-rails` - CSS framework
- `importmap-rails` - JavaScript imports

### Infrastructure
- `solid_queue` - Database-backed job queue
- `solid_cache` - Database-backed cache
- `solid_cable` - Database-backed Action Cable

### Content
- `lexxy` ~> 0.1.26.beta - Rich text editor
- `image_processing` ~> 1.2 - Image handling
- `rouge` - Code syntax highlighting

## Development Tools

- `debug` - Ruby debugger
- `web-console` - In-browser console
- `brakeman` - Security analysis
- `rubocop-rails-omakase` - Style guide
- `bundler-audit` - Dependency audit

## Deployment

- `kamal` - Container deployment
- `thruster` - HTTP caching/compression
