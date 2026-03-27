Rails.application.routes.draw do
  root "hub#index"
  get "hub", to: "hub#index"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  resources :feedback, only: [ :index, :new, :create, :show ] do
    collection do
      get :form
    end
  end

  resources :articles, only: [ :index, :show, :new, :create, :destroy ]
  resources :updates, only: [ :index, :create, :update, :destroy ]
  resources :tags, only: [ :index ]
  resources :tools, only: [ :index ]
  get "search", to: "search#index"

  namespace :admin do
    resources :templates
    resources :users
  end

  # Healthcheck endpoint for ONCE deployment
  get "up" => "rails/health#show", as: :rails_health_check
end
