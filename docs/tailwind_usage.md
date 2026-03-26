# Tailwind CSS Usage Guide

FeedbackHub uses Tailwind CSS with DaisyUI for styling. This guide covers patterns and best practices.

## Stack Overview

| Tool | Purpose |
|------|---------|
| Tailwind CSS | Utility-first CSS framework |
| DaisyUI | Component library for Tailwind |
| PhlexyUI | Phlex wrappers for DaisyUI |

## DaisyUI Theme

DaisyUI provides pre-built themes. Configure in `tailwind.config.js`:

```javascript
module.exports = {
  plugins: [require("daisyui")],
  daisyui: {
    themes: ["light", "dark", "corporate", "business"],
  },
}
```

### Theme Colors

DaisyUI provides semantic color classes:

| Class | Purpose |
|-------|---------|
| `bg-base-100` | Main background |
| `bg-base-200` | Slightly darker background |
| `bg-base-300` | Even darker background |
| `text-base-content` | Main text color |
| `bg-primary` | Primary brand color |
| `bg-secondary` | Secondary color |
| `bg-accent` | Accent color |
| `bg-neutral` | Neutral color |
| `bg-info` | Informational |
| `bg-success` | Success state |
| `bg-warning` | Warning state |
| `bg-error` | Error state |

## Common Components

### Buttons

```ruby
# Using PhlexyUI
Button(variant: :primary) { "Primary" }
Button(variant: :secondary) { "Secondary" }
Button(variant: :accent) { "Accent" }
Button(variant: :ghost) { "Ghost" }
Button(variant: :link) { "Link" }
Button(variant: :outline) { "Outline" }

# Direct Tailwind classes
button(class: "btn btn-primary") { "Primary" }
button(class: "btn btn-sm") { "Small" }
button(class: "btn btn-lg") { "Large" }
```

### Cards

```ruby
# Using PhlexyUI
Card do |card|
  card.body do
    h2(class: "card-title") { "Title" }
    p { "Content" }
  end
end

# Direct classes
div(class: "card bg-base-100 shadow-xl") do
  div(class: "card-body") do
    h2(class: "card-title") { "Title" }
    p { "Content" }
  end
end
```

### Forms

```ruby
# Form control with label
div(class: "form-control w-full") do
  label(class: "label") do
    span(class: "label-text") { "Email" }
  end
  input(type: "email", class: "input input-bordered w-full")
end

# Input variants
input(class: "input input-bordered")     # Default
input(class: "input input-primary")      # Primary color
input(class: "input input-error")        # Error state
input(class: "input input-sm")           # Small
input(class: "input input-lg")           # Large
```

### Alerts

```ruby
# DaisyUI alerts
div(class: "alert alert-info") do
  span { "Info message" }
end

div(class: "alert alert-success") do
  span { "Success message" }
end

div(class: "alert alert-warning") do
  span { "Warning message" }
end

div(class: "alert alert-error") do
  span { "Error message" }
end
```

### Badges

```ruby
span(class: "badge") { "Default" }
span(class: "badge badge-primary") { "Primary" }
span(class: "badge badge-secondary") { "Secondary" }
span(class: "badge badge-accent") { "Accent" }
span(class: "badge badge-ghost") { "Ghost" }
span(class: "badge badge-outline") { "Outline" }
```

## Layout Patterns

### Container

```ruby
div(class: "container mx-auto px-4") do
  # Content
end
```

### Grid

```ruby
# Responsive grid
div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4") do
  # Grid items
end
```

### Flexbox

```ruby
# Horizontal layout
div(class: "flex items-center gap-4") do
  # Flex items
end

# Vertical layout
div(class: "flex flex-col gap-4") do
  # Flex items
end

# Space between
div(class: "flex justify-between items-center") do
  # Flex items
end
```

### Stack (DaisyUI)

```ruby
# Vertical stack
div(class: "stack") do
  div(class: "card bg-primary") { "1" }
  div(class: "card bg-secondary") { "2" }
  div(class: "card bg-accent") { "3" }
end
```

## Spacing System

Tailwind uses a consistent spacing scale:

| Class | Size |
|-------|------|
| `p-1` / `m-1` | 0.25rem (4px) |
| `p-2` / `m-2` | 0.5rem (8px) |
| `p-3` / `m-3` | 0.75rem (12px) |
| `p-4` / `m-4` | 1rem (16px) |
| `p-6` / `m-6` | 1.5rem (24px) |
| `p-8` / `m-8` | 2rem (32px) |

## Typography

```ruby
# Headings
h1(class: "text-4xl font-bold") { "Heading 1" }
h2(class: "text-3xl font-semibold") { "Heading 2" }
h3(class: "text-2xl font-medium") { "Heading 3" }

# Body text
p(class: "text-base") { "Normal text" }
p(class: "text-sm text-base-content/70") { "Secondary text" }
p(class: "text-xs") { "Small text" }

# Prose (for rich content)
div(class: "prose") do
  raw @content
end
```

## Responsive Design

Mobile-first responsive prefixes:

| Prefix | Breakpoint |
|--------|------------|
| (none) | 0px |
| `sm:` | 640px |
| `md:` | 768px |
| `lg:` | 1024px |
| `xl:` | 1280px |
| `2xl:` | 1536px |

```ruby
# Mobile-first responsive
div(class: "text-sm md:text-base lg:text-lg")
div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3")
div(class: "hidden md:block")  # Hidden on mobile
```

## Dark Mode

DaisyUI handles dark mode through themes:

```html
<!-- In layout, allow theme switching -->
<html data-theme="light">  <!-- or "dark" -->
```

Use semantic colors and they'll adapt automatically:

```ruby
# Good - adapts to theme
div(class: "bg-base-100 text-base-content")

# Avoid - won't adapt
div(class: "bg-white text-black")
```

## Best Practices

### 1. Use Semantic Colors

```ruby
# Good
div(class: "bg-primary text-primary-content")
div(class: "text-error")

# Avoid
div(class: "bg-blue-500 text-white")
div(class: "text-red-600")
```

### 2. Use DaisyUI Components

```ruby
# Good - consistent, accessible
button(class: "btn btn-primary")

# Avoid - reinventing the wheel
button(class: "px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600")
```

### 3. Prefer PhlexyUI in Phlex

```ruby
# Good - type-safe, clean
Button(variant: :primary) { "Submit" }

# OK - but more verbose
button(class: "btn btn-primary") { "Submit" }
```

### 4. Consistent Spacing

```ruby
# Good - using spacing scale
div(class: "p-4 mb-6 gap-4")

# Avoid - arbitrary values
div(class: "p-[17px] mb-[23px]")
```

### 5. Component-Based Styling

Extract repeated patterns into components rather than copying classes.

## Troubleshooting

### Classes Not Working

1. Check if class is in Tailwind's safelist
2. Rebuild CSS: `bin/rails tailwindcss:build`
3. Restart watch: `bin/dev`

### DaisyUI Theme Not Applying

1. Check `data-theme` attribute on `<html>`
2. Verify DaisyUI is in plugins array
3. Check theme is in `daisyui.themes` config
