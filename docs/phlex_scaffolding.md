# Phlex View Scaffolding

This project includes a custom `phlex_scaffold` generator that creates Phlex views and controllers instead of ERB.

## Quick Start

### Option A: Use the Custom Generator Directly

```bash
bin/rails generate phlex_scaffold:scaffold Post title:string body:text published:boolean
```

### Option B: Make Phlex the Default (Recommended)

Add to `config/application.rb`:

```ruby
config.generators do |g|
  g.template_engine :phlex_scaffold
end
```

Then use the regular scaffold command:

```bash
bin/rails generate scaffold Post title:string body:text published:boolean
```

## What Gets Generated

For `rails g phlex_scaffold:scaffold Post title:string body:text`:

```
app/
├── controllers/
│   └── posts_controller.rb      # Controller with Phlex view rendering
└── views/
    └── posts/
        ├── index.rb             # List all posts
        ├── show.rb              # Show single post
        ├── new.rb               # New post form
        ├── edit.rb              # Edit post form
        └── _form.rb             # Shared form component
```

## Generated Features

### Controller

- Renders Phlex views directly
- Standard RESTful actions
- Strong parameters
- Proper error handling with `status: :unprocessable_entity`

### Views

**Index View:**
- Lists all records in a table
- Show, Edit, Delete action buttons
- "New" button in header

**Show View:**
- Displays record details in a card
- Edit and Back navigation

**New/Edit Views:**
- Render shared Form component
- Back navigation

**Form Component:**
- Type-aware form fields:
  - `string` → text input
  - `text` → textarea
  - `boolean` → checkbox
  - `integer/decimal/float` → number input
  - `date` → date picker
  - `datetime` → datetime picker
  - `email` → email input
- Validation error display
- DaisyUI form styling

## Examples

### Blog Post

```bash
bin/rails g phlex_scaffold:scaffold Post title:string body:text published:boolean author:string
```

### Feedback Item

```bash
bin/rails g phlex_scaffold:scaffold Feedback title:string description:text status:string priority:integer
```

### User Profile

```bash
bin/rails g phlex_scaffold:scaffold Profile user:references bio:text website:string public:boolean
```

## Customization

Templates are in `lib/generators/phlex_scaffold/scaffold/templates/`:

- `controller.rb.erb` - Controller template
- `index.rb.erb` - Index view
- `show.rb.erb` - Show view
- `new.rb.erb` - New view
- `edit.rb.erb` - Edit view
- `_form.rb.erb` - Form component

Modify these to change:
- CSS classes and styling
- Component usage
- Form field rendering
- Navigation structure

## Dependencies

The generated views assume:

1. `Views::Base` exists in `app/views/base.rb`
2. DaisyUI classes are available (via Tailwind)

Both are included in this project.
