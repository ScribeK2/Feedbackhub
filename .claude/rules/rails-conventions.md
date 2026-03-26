# Rails Conventions

Follow these Rails 8 conventions for FeedbackHub.

## Models

### Validations
```ruby
class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true, length: { maximum: 100 }
end
```

### Associations
```ruby
class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
end
```

### Scopes
```ruby
class Post < ApplicationRecord
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
end
```

## Controllers

### Strong Parameters
```ruby
class PostsController < ApplicationController
  private

  def post_params
    params.require(:post).permit(:title, :body, :published)
  end
end
```

### RESTful Actions
Keep to standard CRUD actions when possible:
- index, show, new, create, edit, update, destroy

### Turbo Responses
```ruby
def create
  @post = Post.new(post_params)
  if @post.save
    redirect_to @post
  else
    render :new, status: :unprocessable_entity
  end
end
```

## Routes

### RESTful Resources
```ruby
resources :posts do
  resources :comments, only: [:create, :destroy]
end
```

### Shallow Nesting
```ruby
resources :posts, shallow: true do
  resources :comments
end
```

## Migrations

### Reversible
```ruby
class AddStatusToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :status, :string, default: 'draft'
    add_index :posts, :status
  end
end
```

### Foreign Keys
```ruby
add_reference :comments, :post, foreign_key: true
```

## Phlex Views

### Component Structure
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

### Layouts
Views inherit from `Views::Base` which renders within the application layout.
