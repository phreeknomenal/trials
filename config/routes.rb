Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

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

  namespace :admin do
    root to: "dashboard#index"
    resources :testimonials
    get "operations", to: "operations#index"
    resources :users, only: [:index]
  end

  # The onboarding wizard. One step per URL so a refresh resumes where the user
  # was and the back button behaves, neither of which the modal could do.
  get "onboarding", to: "onboarding#show", as: :onboarding
  get "onboarding/:step", to: "onboarding#show", as: :onboarding_step,
    constraints: {step: /[a-z_]+/}
  patch "onboarding/:step", to: "onboarding#update", constraints: {step: /[a-z_]+/}
  post "onboarding/:step/skip", to: "onboarding#skip", as: :skip_onboarding_step,
    constraints: {step: /[a-z_]+/}
  delete "onboarding/banner", to: "onboarding#dismiss_banner", as: :onboarding_banner

  resources :profiles, only: [:new, :create, :show, :edit, :update]
  resources :search, only: [:index, :show]

  namespace :my_trials do
    root action: :index
    get :search
    get :saved_trials
    get :trial_comparison
  end

  # My Trials show action (for viewing individual trial details with scoring)
  resources :my_trials, only: [:show]

  # Public. A summary is a pure function of public study text and is cached per
  # study rather than per user, so there is nothing account-specific to protect.
  # Generation is bounded by rate limits instead of by authentication.
  post "summaries/:nct_id", to: "readable_summaries#create", as: :readable_summary

  # Keep old saved_trials routes for backward compatibility
  resources :saved_trials, only: [:index, :show, :edit, :create, :update, :destroy]
end
