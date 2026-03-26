# Phlex View Architecture

This guide outlines how FeedbackHub implements its view layer using Phlex.

## Overview

Phlex is a pure Ruby HTML generation library that replaces ERB templates with Ruby classes. Benefits include:

- Type-safe HTML generation
- Full IDE support (autocomplete, refactoring)
- Composable, testable components
- Better performance than ERB

## Directory Structure

```
app/views/
├── application_view.rb         # Base view class
├── components/                 # Reusable components
│   ├── button.rb
│   ├── card.rb
│   └── form/
│       ├── field.rb
│       └── input.rb
├── layouts/
│   └── application_layout.rb   # Main layout
└── [resource]/                 # Resource views
    ├── index_view.rb
    ├── show_view.rb
    ├── new_view.rb
    └── edit_view.rb
```

## Base View Class

All views inherit from a common base:

```ruby
# app/views/application_view.rb
class ApplicationView < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::CSRF
  include Phlex::Rails::Helpers::FormWith
  # Add other Rails helpers as needed
end
```

## View Patterns

### Basic View

```ruby
class Views::Posts::Show < ApplicationView
  def initialize(post:)
    @post = post
  end

  def view_template
    article(class: "prose") do
      h1 { @post.title }
      div { raw @post.body }

      footer(class: "mt-4") do
        render Components::Button.new(href: edit_post_path(@post)) { "Edit" }
      end
    end
  end
end
```

### List View

```ruby
class Views::Posts::Index < ApplicationView
  def initialize(posts:)
    @posts = posts
  end

  def view_template
    h1 { "Posts" }

    if @posts.any?
      ul(class: "space-y-4") do
        @posts.each do |post|
          li { render PostCard.new(post: post) }
        end
      end
    else
      p(class: "text-muted") { "No posts yet." }
    end
  end
end
```

### Form View

```ruby
class Views::Posts::New < ApplicationView
  def initialize(post:)
    @post = post
  end

  def view_template
    h1 { "New Post" }
    render Views::Posts::Form.new(post: @post, url: posts_path)
  end
end
```

## Controller Integration

Controllers render Phlex views directly:

```ruby
class PostsController < ApplicationController
  def show
    @post = Post.find(params[:id])
    render Views::Posts::Show.new(post: @post)
  end

  def index
    @posts = Post.recent
    render Views::Posts::Index.new(posts: @posts)
  end
end
```

Or use implicit rendering with proper naming:

```ruby
class PostsController < ApplicationController
  def show
    @post = Post.find(params[:id])
    # Automatically renders Views::Posts::Show if it exists
  end
end
```

## Component Patterns

### Simple Component

```ruby
class Components::Badge < Phlex::HTML
  def initialize(text:, variant: :default)
    @text = text
    @variant = variant
  end

  def view_template
    span(class: badge_classes) { @text }
  end

  private

  def badge_classes
    base = "badge"
    case @variant
    when :success then "#{base} badge-success"
    when :warning then "#{base} badge-warning"
    when :error then "#{base} badge-error"
    else "#{base} badge-neutral"
    end
  end
end
```

### Component with Block

```ruby
class Components::Card < Phlex::HTML
  def initialize(title: nil, **attrs)
    @title = title
    @attrs = attrs
  end

  def view_template
    div(class: "card bg-base-100 shadow", **@attrs) do
      div(class: "card-body") do
        h2(class: "card-title") { @title } if @title
        yield if block_given?
      end
    end
  end
end

# Usage
render Components::Card.new(title: "Hello") do
  p { "Card content here" }
end
```

### Component with Slots

```ruby
class Components::Modal < Phlex::HTML
  def initialize(title:)
    @title = title
  end

  def view_template(&)
    dialog(class: "modal") do
      div(class: "modal-box") do
        h3(class: "font-bold text-lg") { @title }
        yield_content(&)
      end
    end
  end

  def body(&)
    div(class: "py-4", &)
  end

  def actions(&)
    div(class: "modal-action", &)
  end
end

# Usage
render Components::Modal.new(title: "Confirm") do |modal|
  modal.body { p { "Are you sure?" } }
  modal.actions do
    button(class: "btn") { "Cancel" }
    button(class: "btn btn-primary") { "Confirm" }
  end
end
```

## PhlexyUI Integration

PhlexyUI provides DaisyUI components as Phlex classes:

```ruby
# Using PhlexyUI components
class Views::Posts::Show < ApplicationView
  include PhlexyUI

  def view_template
    Card do |card|
      card.body do
        h2(class: "card-title") { @post.title }
        p { @post.excerpt }
      end
      card.actions do
        Button(variant: :primary) { "Read More" }
      end
    end
  end
end
```

## Best Practices

### 1. Keep Views Simple
```ruby
# Good - presentation only
def view_template
  h1 { @post.title }
  p { @post.formatted_date }  # formatting in model
end

# Avoid - logic in view
def view_template
  h1 { @post.title }
  p { @post.created_at.strftime("%B %d, %Y") }
end
```

### 2. Extract Components
```ruby
# Good - reusable component
render Components::UserAvatar.new(user: @post.author)

# Avoid - repeated inline HTML
img(src: @post.author.avatar_url, class: "w-8 h-8 rounded-full")
```

### 3. Use Semantic Names
```ruby
# Good
class Components::FeedbackCard < Phlex::HTML
class Views::Dashboard::Index < ApplicationView

# Avoid
class Components::Card1 < Phlex::HTML
class Views::Page < ApplicationView
```

### 4. Separate Attributes from Configuration
```ruby
# Good - clear separation
def initialize(variant:, size:, **html_attrs)
  @variant = variant
  @size = size
  @html_attrs = html_attrs
end

def view_template
  button(class: computed_classes, **@html_attrs) { yield }
end
```

## Testing Views

```ruby
class Views::Posts::ShowTest < ActiveSupport::TestCase
  def test_renders_post_title
    post = posts(:one)
    view = Views::Posts::Show.new(post: post)
    html = view.call

    assert_includes html, post.title
  end
end
```

## Migration from ERB

### Before (ERB)
```erb
<article class="post">
  <h1><%= @post.title %></h1>
  <div class="prose">
    <%= @post.body %>
  </div>
</article>
```

### After (Phlex)
```ruby
class Views::Posts::Show < ApplicationView
  def initialize(post:)
    @post = post
  end

  def view_template
    article(class: "post") do
      h1 { @post.title }
      div(class: "prose") { raw @post.body }
    end
  end
end
```
