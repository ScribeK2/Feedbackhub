# File System Structure

## Application Structure

```
feedbackhub/
├── app/
│   ├── assets/                 # Static assets
│   │   └── stylesheets/        # CSS files
│   ├── channels/               # Action Cable channels
│   ├── controllers/            # Rails controllers
│   │   └── application_controller.rb
│   ├── helpers/                # View helpers
│   ├── javascript/
│   │   ├── controllers/        # Stimulus controllers
│   │   └── application.js
│   ├── jobs/                   # Background jobs (Solid Queue)
│   ├── mailers/                # Email templates
│   ├── models/                 # ActiveRecord models
│   └── views/                  # Phlex views
│       ├── components/         # Reusable UI components
│       ├── layouts/            # Layout views
│       └── [resource]/         # Resource-specific views
├── bin/                        # Executable scripts
│   ├── dev                     # Start development server
│   ├── rails                   # Rails CLI
│   └── setup                   # Initial setup
├── config/                     # Configuration
│   ├── environments/           # Per-environment config
│   ├── initializers/           # Boot-time setup
│   ├── database.yml            # Database config
│   └── routes.rb               # URL routing
├── db/
│   ├── migrate/                # Database migrations
│   ├── schema.rb               # Current schema
│   └── seeds.rb                # Seed data
├── docs/                       # Project documentation
├── lib/                        # Custom libraries
│   └── tasks/                  # Rake tasks
├── public/                     # Static files served directly
├── test/                       # Test suite
│   ├── controllers/            # Controller tests
│   ├── fixtures/               # Test data
│   ├── models/                 # Model tests
│   └── system/                 # System/integration tests
├── .claude/                    # Claude Code configuration
│   ├── agents/                 # Sub-agent definitions
│   ├── commands/               # Custom commands
│   ├── context/                # Project context docs
│   └── rules/                  # Coding rules
├── CLAUDE.md                   # Claude Code instructions
├── Gemfile                     # Ruby dependencies
└── package.json                # JavaScript dependencies
```

## Key Locations

| Purpose | Location |
|---------|----------|
| Phlex Views | `app/views/` |
| Components | `app/views/components/` |
| Controllers | `app/controllers/` |
| Models | `app/models/` |
| Stimulus | `app/javascript/controllers/` |
| Styles | `app/assets/stylesheets/` |
| Tests | `test/` |
| Documentation | `docs/` |
| Claude Config | `.claude/` |

## Phlex View Organization

Views mirror the controller structure:

```
app/views/
├── application_view.rb         # Base view class
├── components/
│   ├── button.rb
│   ├── card.rb
│   └── form_field.rb
├── layouts/
│   └── application_layout.rb
├── posts/
│   ├── index_view.rb
│   ├── show_view.rb
│   ├── new_view.rb
│   └── edit_view.rb
└── shared/
    └── _flash.rb
```

## Naming Conventions

### Views
- Class name: `Views::Posts::IndexView` or `Views::Posts::Index`
- File name: `app/views/posts/index_view.rb` or `app/views/posts/index.rb`

### Components
- Class name: `Components::Button`
- File name: `app/views/components/button.rb`

### Stimulus Controllers
- Class name: N/A (JavaScript)
- File name: `app/javascript/controllers/dropdown_controller.js`
- HTML: `data-controller="dropdown"`

## Test Organization

Tests mirror the app structure:

```
test/
├── controllers/
│   └── posts_controller_test.rb
├── fixtures/
│   ├── posts.yml
│   └── users.yml
├── models/
│   └── post_test.rb
├── system/
│   └── posts_test.rb
└── test_helper.rb
```
