# File System Structure

## Application Structure

```
feedbackhub/
├── app/
│   ├── assets/                 # Static assets
│   │   └── stylesheets/        # CSS files
│   ├── channels/               # Action Cable channels
│   ├── controllers/            # Rails controllers
│   │   ├── application_controller.rb
│   │   ├── hub_controller.rb
│   │   ├── feedback_controller.rb
│   │   └── admin/
│   │       └── templates_controller.rb
│   ├── helpers/                # View helpers
│   ├── javascript/
│   │   ├── controllers/        # Stimulus controllers
│   │   └── application.js
│   ├── jobs/                   # Background jobs (Solid Queue)
│   ├── mailers/                # Email templates
│   ├── models/                 # ActiveRecord models
│   │   ├── feedback_template.rb
│   │   └── feedback_submission.rb
│   └── views/                  # Phlex views
│       ├── base.rb             # Base view class (Views::Base)
│       └── components/         # Phlex components (PhlexyUI)
│           ├── application_component.rb
│           ├── base.rb
│           ├── admin/
│           │   ├── template_form_component.rb
│           │   └── template_list_component.rb
│           ├── feedback/
│           │   ├── card_component.rb
│           │   ├── form_component.rb
│           │   └── success_component.rb
│           ├── hub/
│           │   ├── index_component.rb
│           │   └── submission_modal_component.rb
│           ├── layouts/
│           │   └── application_layout.rb
│           └── shared/
│               ├── flash_component.rb
│               └── theme_toggle_component.rb
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
│   │   ├── hub_controller_test.rb
│   │   ├── feedback_controller_test.rb
│   │   └── admin/
│   │       └── templates_controller_test.rb
│   ├── fixtures/               # Test data
│   │   ├── feedback_templates.yml
│   │   └── feedback_submissions.yml
│   ├── models/                 # Model tests
│   │   ├── feedback_template_test.rb
│   │   └── feedback_submission_test.rb
│   └── test_helper.rb
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

Components use PhlexyUI (DaisyUI wrapper) and are organized by domain:

```
app/views/
├── base.rb                     # Views::Base (for non-component views)
└── components/
    ├── application_component.rb  # Root component (includes PhlexyUI)
    ├── base.rb                   # Components::Base (utility methods)
    ├── admin/
    │   ├── template_form_component.rb
    │   └── template_list_component.rb
    ├── feedback/
    │   ├── card_component.rb
    │   ├── form_component.rb
    │   └── success_component.rb
    ├── hub/
    │   ├── index_component.rb
    │   └── submission_modal_component.rb
    ├── layouts/
    │   └── application_layout.rb
    └── shared/
        ├── flash_component.rb
        └── theme_toggle_component.rb
```

## Naming Conventions

### Components
- Class name: `Admin::TemplateFormComponent`
- File name: `app/views/components/admin/template_form_component.rb`

### Shared Components
- Class name: `Shared::FlashComponent`
- File name: `app/views/components/shared/flash_component.rb`

### Stimulus Controllers
- Class name: N/A (JavaScript)
- File name: `app/javascript/controllers/form_controller.js`
- HTML: `data-controller="form"`

## Test Organization

Tests mirror the app structure:

```
test/
├── controllers/
│   ├── hub_controller_test.rb
│   ├── feedback_controller_test.rb
│   └── admin/
│       └── templates_controller_test.rb
├── fixtures/
│   ├── feedback_templates.yml
│   └── feedback_submissions.yml
├── models/
│   ├── feedback_template_test.rb
│   └── feedback_submission_test.rb
└── test_helper.rb
```
