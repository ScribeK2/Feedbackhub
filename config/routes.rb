Rails.application.routes.draw do
  root "hub#index"
  get "hub", to: "hub#index"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  resources :feedback, only: [ :index, :new, :create, :show, :edit, :update, :destroy ] do
    collection do
      get :form
    end
    resources :comments, only: [ :index, :create ]
    resource :subscription, only: [ :update ]
    resource :status, only: [ :update ]
  end

  resources :comments, only: [ :show, :edit, :update, :destroy ]

  resources :notifications, only: [ :index, :show ] do
    collection do
      post :mark_all_read
    end
  end

  get   "settings",               to: redirect("/settings/account")
  get   "settings/account",       to: "settings#account",         as: :settings_account
  patch "settings/profile",       to: "settings#update_profile",  as: :settings_profile
  patch "settings/password",      to: "settings#update_password", as: :settings_password
  get   "settings/subscriptions", to: "settings#subscriptions",   as: :settings_subscriptions

  resources :articles, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]
  resources :updates, only: [ :index, :create, :update, :destroy ]
  resources :tags, only: [ :index ]
  resources :tools, only: [ :index ]
  get "search", to: "search#index"

  get "team", to: "team_memberships#index"
  resources :team_memberships, only: [ :create, :destroy ]

  get "scorecards", to: "scorecards#index"
  get "scorecards/show", to: "scorecards#show", as: :scorecard

  namespace :admin do
    resources :templates
    resources :users
    resources :csrs, except: [ :show ] do
      member do
        post :merge
      end
    end
    resources :tags, only: [ :index, :edit, :update, :destroy ] do
      member do
        post :merge
      end
    end
    resources :tools, except: [ :show ]
  end

  # Healthcheck endpoint for ONCE deployment
  get "up" => "rails/health#show", as: :rails_health_check
end
