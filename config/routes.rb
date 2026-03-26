Rails.application.routes.draw do
  root "hub#index"
  get "hub", to: "hub#index"

  resources :feedback, only: [ :new, :create, :show ] do
    collection do
      get :form
    end
  end

  namespace :admin do
    resources :templates
  end

  # Healthcheck endpoint for ONCE deployment
  get "up" => "rails/health#show", as: :rails_health_check
end
