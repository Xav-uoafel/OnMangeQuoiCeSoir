Rails.application.routes.draw do
  devise_for :users, controllers: { passwords: "users/passwords" }
  if Rails.env.development?
    constraints ->(request) { request.local? } do
      mount LetterOpenerWeb::Engine, at: "/dev/emails"
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "health#show", as: :readiness_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "offline" => "home#offline", as: :offline

  authenticated :user do
    root 'plans#dashboard', as: :authenticated_root
  end

  root 'home#index'

  resources :recipes do
    resources :reviews, only: [:create, :edit, :update, :destroy]
    member { post :mark_cooked }
  end

  authenticate :user do
    resource :profile, only: [:edit, :update]
    resource :onboarding, only: [:show, :update]

    resources :plans, only: %i[index show new create update destroy] do
      member { post :generate }
      resources :plan_recipes, only: [] do
        member do
          patch :toggle_lock
          post :replace
        end
      end
      resource :shopping_list, only: [:show] do
        post :refresh_prices
        resources :shopping_list_items, only: [:update]
      end
    end

    resources :pantry_items, only: [:index, :create, :update, :destroy] do
      post :merge_duplicates, on: :collection
    end
    resources :pantry_scans, only: [:new, :create, :show] do
      member do
        post :confirm
        post :discard
        post :retry_analysis
      end
    end

    resource :household, only: [:show, :edit, :update, :create] do
      post :join, on: :collection
    end
  end
end
