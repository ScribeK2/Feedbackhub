# System Patterns

## Architecture Overview

FeedbackHub follows standard Rails MVC architecture with Phlex views.

```
Request → Router → Controller → Model → View → Response
                        ↓
                    Database
```

## View Layer (Phlex)

### Base View
All views inherit from a base class that provides common functionality:

```ruby
class Views::Base < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::CSRF
end
```

### Component Pattern
Reusable components for UI elements:

```ruby
class Components::Button < Phlex::HTML
  def initialize(text:, variant: :primary, **attrs)
    @text = text
    @variant = variant
    @attrs = attrs
  end

  def view_template
    button(class: button_classes, **@attrs) { @text }
  end

  private

  def button_classes
    # PhlexyUI/DaisyUI classes
    "btn btn-#{@variant}"
  end
end
```

## Controller Patterns

### Standard CRUD
```ruby
class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  def index
    @posts = Post.recent.page(params[:page])
  end

  def show
  end

  # ... standard REST actions

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body)
  end
end
```

## Model Patterns

### Concerns for Shared Behavior
```ruby
# app/models/concerns/publishable.rb
module Publishable
  extend ActiveSupport::Concern

  included do
    scope :published, -> { where(published: true) }
    scope :draft, -> { where(published: false) }
  end

  def publish!
    update!(published: true, published_at: Time.current)
  end
end
```

## Turbo Patterns

### Frame Updates
```ruby
# Controller
def update
  if @post.update(post_params)
    render partial: "posts/post", locals: { post: @post }
  else
    render :edit, status: :unprocessable_entity
  end
end
```

### Stream Broadcasts
```ruby
# Model
after_create_commit -> { broadcast_prepend_to "posts" }
after_update_commit -> { broadcast_replace_to "posts" }
after_destroy_commit -> { broadcast_remove_to "posts" }
```

## Stimulus Patterns

### Controller Structure
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "output"]
  static values = { url: String }

  connect() {
    // Setup
  }

  submit(event) {
    event.preventDefault()
    // Handle submission
  }
}
```

## Error Handling

### Controller Level
```ruby
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def not_found
    render file: "public/404.html", status: :not_found
  end
end
```

### Model Validation
```ruby
class Post < ApplicationRecord
  validates :title, presence: true
  validate :content_is_safe

  private

  def content_is_safe
    # Custom validation logic
  end
end
```
