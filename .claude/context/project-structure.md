# Project Structure

## Directory Layout

```
feedbackhub/
├── app/
│   ├── assets/          # CSS, images
│   ├── channels/        # Action Cable channels
│   ├── controllers/     # Request handlers
│   ├── helpers/         # View helpers
│   ├── javascript/      # Stimulus controllers
│   │   └── controllers/
│   ├── jobs/            # Background jobs (Solid Queue)
│   ├── mailers/         # Email templates
│   ├── models/          # ActiveRecord models
│   └── views/           # Phlex views
│       ├── components/  # Reusable components
│       └── layouts/     # Application layouts
├── bin/                 # Executable scripts
├── config/              # Configuration
│   ├── environments/    # Per-environment config
│   ├── initializers/    # Boot-time setup
│   └── routes.rb        # URL routing
├── db/
│   ├── migrate/         # Database migrations
│   ├── schema.rb        # Current schema
│   └── seeds.rb         # Seed data
├── lib/                 # Custom libraries
├── public/              # Static files
├── test/                # Test suite
│   ├── controllers/     # Controller tests
│   ├── fixtures/        # Test data
│   ├── models/          # Model tests
│   └── system/          # System/integration tests
└── .claude/             # Claude Code configuration
    ├── agents/          # Agent definitions
    ├── commands/        # Custom commands
    ├── context/         # Project context docs
    └── rules/           # Coding rules
```

## Key Files

| File | Purpose |
|------|---------|
| `config/routes.rb` | URL routing definitions |
| `config/database.yml` | Database configuration |
| `Gemfile` | Ruby dependencies |
| `package.json` | JavaScript dependencies |
| `CLAUDE.md` | AI agent instructions |

## Conventions

### Views (Phlex)
- One class per view in `app/views/`
- Inherit from `Views::Base` or `Phlex::HTML`
- Components in `app/views/components/`

### Controllers
- RESTful actions
- Thin controllers, fat models
- Use concerns for shared behavior

### Models
- Validations, associations, scopes
- Business logic in models
- Query methods as scopes

### Tests
- Mirror app structure in `test/`
- Fixtures in `test/fixtures/`
- System tests for full flows
