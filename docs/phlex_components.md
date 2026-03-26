# Phlex Components Guide

This guide covers component design patterns for FeedbackHub using Phlex and PhlexyUI.

## Component Organization

```
app/views/components/
├── base.rb                 # Base component class
├── button.rb               # Button component
├── card.rb                 # Card component
├── badge.rb                # Badge component
├── avatar.rb               # Avatar component
├── form/
│   ├── field.rb            # Form field wrapper
│   ├── input.rb            # Text input
│   ├── textarea.rb         # Textarea
│   ├── select.rb           # Select dropdown
│   └── checkbox.rb         # Checkbox
└── layout/
    ├── navbar.rb           # Navigation bar
    ├── sidebar.rb          # Sidebar
    └── footer.rb           # Footer
```

## Base Component

All components inherit from a common base:

```ruby
# app/views/components/base.rb
class Components::Base < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include PhlexyUI

  # Shared helpers can go here
end
```

## Using PhlexyUI (DaisyUI)

PhlexyUI provides DaisyUI components as Phlex classes:

### Button

```ruby
# Basic button
Button { "Click me" }

# With variant
Button(variant: :primary) { "Primary" }
Button(variant: :secondary) { "Secondary" }
Button(variant: :accent) { "Accent" }
Button(variant: :ghost) { "Ghost" }

# With size
Button(size: :sm) { "Small" }
Button(size: :lg) { "Large" }

# As link
Button(href: "/posts") { "View Posts" }
```

### Card

```ruby
Card do |card|
  card.body do
    h2(class: "card-title") { "Card Title" }
    p { "Card content goes here." }
  end
  card.actions do
    Button(variant: :primary) { "Action" }
  end
end
```

### Form Inputs

```ruby
FormControl do |fc|
  fc.label { "Email" }
  fc.input(type: "email", placeholder: "you@example.com")
end

FormControl do |fc|
  fc.label { "Message" }
  fc.textarea(placeholder: "Your message...")
end
```

### Alert

```ruby
Alert(variant: :info) { "This is an info message." }
Alert(variant: :success) { "Operation completed!" }
Alert(variant: :warning) { "Please review your input." }
Alert(variant: :error) { "Something went wrong." }
```

### Modal

```ruby
Modal(id: "confirm-modal") do |modal|
  modal.box do
    h3(class: "font-bold text-lg") { "Confirm Action" }
    p(class: "py-4") { "Are you sure?" }
    div(class: "modal-action") do
      Button { "Cancel" }
      Button(variant: :primary) { "Confirm" }
    end
  end
end
```

## Custom Components

### Form Field Component

```ruby
class Components::Form::Field < Components::Base
  def initialize(label:, error: nil, required: false, **attrs)
    @label = label
    @error = error
    @required = required
    @attrs = attrs
  end

  def view_template(&)
    div(class: "form-control w-full", **@attrs) do
      label(class: "label") do
        span(class: "label-text") do
          plain @label
          span(class: "text-error") { " *" } if @required
        end
      end

      yield if block_given?

      if @error
        label(class: "label") do
          span(class: "label-text-alt text-error") { @error }
        end
      end
    end
  end
end

# Usage
render Components::Form::Field.new(label: "Email", required: true, error: @errors[:email]) do
  input(type: "email", name: "email", class: "input input-bordered w-full")
end
```

### Feedback Card Component

```ruby
class Components::FeedbackCard < Components::Base
  def initialize(feedback:)
    @feedback = feedback
  end

  def view_template
    Card(class: "hover:shadow-lg transition-shadow") do |card|
      card.body do
        header
        content
        footer_actions
      end
    end
  end

  private

  def header
    div(class: "flex justify-between items-start") do
      div do
        h3(class: "card-title text-lg") { @feedback.title }
        p(class: "text-sm text-base-content/70") do
          "by #{@feedback.user.name} • #{time_ago(@feedback.created_at)}"
        end
      end
      render Components::Badge.new(text: @feedback.status, variant: status_variant)
    end
  end

  def content
    p(class: "mt-4") { @feedback.excerpt }
  end

  def footer_actions
    div(class: "card-actions justify-end mt-4") do
      Button(variant: :ghost, size: :sm) { "Comment" }
      Button(variant: :primary, size: :sm, href: feedback_path(@feedback)) { "View" }
    end
  end

  def status_variant
    case @feedback.status
    when "open" then :info
    when "in_progress" then :warning
    when "resolved" then :success
    else :neutral
    end
  end

  def time_ago(time)
    # Simple time ago helper
    "#{((Time.current - time) / 1.day).to_i} days ago"
  end
end
```

### Avatar Component

```ruby
class Components::Avatar < Components::Base
  SIZES = {
    sm: "w-8 h-8",
    md: "w-12 h-12",
    lg: "w-16 h-16",
    xl: "w-24 h-24"
  }.freeze

  def initialize(user:, size: :md, show_name: false)
    @user = user
    @size = size
    @show_name = show_name
  end

  def view_template
    div(class: "flex items-center gap-2") do
      div(class: "avatar") do
        div(class: "#{SIZES[@size]} rounded-full") do
          if @user.avatar.attached?
            img(src: url_for(@user.avatar), alt: @user.name)
          else
            placeholder
          end
        end
      end
      span { @user.name } if @show_name
    end
  end

  private

  def placeholder
    div(class: "bg-neutral text-neutral-content #{SIZES[@size]} rounded-full flex items-center justify-center") do
      span { @user.initials }
    end
  end
end
```

## Component Composition

Build complex UIs by composing simple components:

```ruby
class Views::Feedback::Show < ApplicationView
  def initialize(feedback:, comments:)
    @feedback = feedback
    @comments = comments
  end

  def view_template
    div(class: "max-w-4xl mx-auto") do
      render Components::FeedbackCard.new(feedback: @feedback)

      div(class: "mt-8") do
        h2(class: "text-xl font-bold mb-4") { "Comments" }

        @comments.each do |comment|
          render Components::CommentCard.new(comment: comment)
        end

        render Components::Form::CommentForm.new(feedback: @feedback)
      end
    end
  end
end
```

## Benefits of This Approach

1. **~85% code reduction** for common patterns
2. **Consistent styling** across the application
3. **Accessible by default** when using DaisyUI
4. **Type-safe** - Ruby catches errors at runtime
5. **Testable** - components can be unit tested
6. **Composable** - build complex UIs from simple parts

## Best Practices

### 1. Single Responsibility
Each component should do one thing well.

### 2. Accept Configuration Props
```ruby
def initialize(variant:, size: :md, disabled: false, **html_attrs)
```

### 3. Use Semantic Variants
```ruby
# Good
Button(variant: :primary)
Alert(variant: :warning)

# Avoid
Button(class: "bg-blue-500")
```

### 4. Provide Sensible Defaults
```ruby
def initialize(size: :md, variant: :default)
  @size = size
  @variant = variant
end
```

### 5. Document Complex Components
Add comments explaining non-obvious behavior or slot usage.
