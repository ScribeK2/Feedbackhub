source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "sqlite3", ">= 2.1"
gem "puma", ">= 5.0"
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"

# Phlex views
gem "phlex", "~> 2.4"
gem "phlex-rails", "~> 2.4"
gem "phlexy_ui", "~> 0.3"

# Solid suite (SQLite-backed infrastructure)
gem "solid_queue"
gem "solid_cache"
gem "solid_cable"

# Authentication
gem "bcrypt", "~> 3.1"

# Rich text
gem "lexxy", "~> 0.9.7.beta"
gem "image_processing", "~> 1.2"

# Code highlighting
gem "rouge"

# Windows timezone data
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching
gem "bootsnap", require: false

# Deploy with Kamal
gem "kamal", require: false

# HTTP asset caching/compression
gem "thruster", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end
