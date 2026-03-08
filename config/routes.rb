Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # Show home page when authenticated, welcome page when not
  authenticated :user do
    root "my_trials#index", as: :authenticated_root
  end

  unauthenticated do
    root "public#index"
  end

  devise_for :users, controllers: {
    passwords: "users/passwords",
    sessions: "users/sessions"
  }

  devise_scope :user do
    get "users/password/confirmation", to: "users/passwords#confirmation"
    get "/users/sign_out" => "devise/sessions#destroy"
  end

  resources :profiles, only: [ :new, :create, :show, :edit, :update ]
  resources :search, only: [ :index, :show ]

  namespace :my_trials do
    root action: :index
    get :search
    get :saved_trials
    get :trial_comparison
  end

  # My Trials show action (for viewing individual trial details with scoring)
  resources :my_trials, only: [ :show ]

  # Keep old saved_trials routes for backward compatibility
  resources :saved_trials, only: [ :index, :show, :edit, :create, :update, :destroy ]
end
