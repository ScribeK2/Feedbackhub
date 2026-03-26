# Application Architecture

FeedbackHub is built following "The Rails Way" philosophy with modern tooling.

## Core Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Framework | Rails 8.1 | Web application framework |
| Views | Phlex 2.4 | Type-safe HTML generation |
| UI Components | PhlexyUI | DaisyUI component library |
| Styling | Tailwind CSS | Utility-first CSS |
| Interactivity | Turbo + Stimulus | SPA-like behavior |
| Database | SQLite | Data persistence |
| Jobs | Solid Queue | Background processing |
| Cache | Solid Cache | Application caching |
| WebSockets | Solid Cable | Real-time features |
| Rich Text | Lexxy | Rich text editing |

## Architectural Layers

### View Layer (Phlex)

Phlex replaces traditional ERB templates with Ruby classes:

```ruby
class Views::Posts::Show < Views::Base
  def initialize(post:)
    @post = post
  end

  def view_template
    h1 { @post.title }
    div(class: "prose") { raw @post.body }
  end
end
```

Benefits:
- Type-safe HTML generation
- Full Ruby tooling support (autocomplete, refactoring)
- Composable components
- Better performance than ERB

### Frontend Interactivity

**Turbo** provides SPA-like navigation:
- Turbo Drive for fast page transitions
- Turbo Frames for partial page updates
- Turbo Streams for real-time updates

**Stimulus** adds progressive enhancement:
- Data attribute-based controllers
- Lightweight JavaScript sprinkles
- Works with server-rendered HTML

### Controller Layer

Controllers orchestrate requests following Rails conventions:

```ruby
class PostsController < ApplicationController
  def show
    @post = Post.find(params[:id])
    # Phlex views are rendered automatically
  end

  def create
    @post = Post.new(post_params)
    if @post.save
      redirect_to @post
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

### Model Layer

Models contain business logic following "Fat Models, Skinny Controllers":

```ruby
class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy

  validates :title, presence: true
  validates :body, presence: true

  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }

  def publish!
    update!(published: true, published_at: Time.current)
  end
end
```

## Design Philosophy

### Convention Over Configuration
Follow Rails conventions. Don't invent custom patterns when Rails provides a solution.

### Fat Models, Skinny Controllers
Business logic belongs in models. Controllers handle HTTP concerns only.

### Simple Authorization
Use association-based authorization when possible:

```ruby
# Good - simple and secure
current_user.posts.find(params[:id])

# Avoid - requires separate authorization check
Post.find(params[:id]) # then check user access
```

### Progressive Enhancement
Build features that work without JavaScript first, then enhance with Turbo/Stimulus.

## Testing Approach

- **Minitest** for unit and integration tests
- **Real database** interactions (no excessive mocking)
- **Capybara** for system tests
- **Fixtures** for test data

## Related Documentation

- [File System Structure](file_system_structure.md) - Directory organization
- [Phlex Architecture](phlex_architecture.md) - View layer patterns
- [Phlex Components](phlex_components.md) - Component design
- [Tailwind Usage](tailwind_usage.md) - Styling patterns
