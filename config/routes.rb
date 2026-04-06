Rails.application.routes.draw do
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

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

    resources :plans do
      member { post :generate }
      resource :shopping_list, only: [:show]
    end

    resources :pantry_items, only: [:index, :create, :update, :destroy]
    resources :pantry_scans, only: [:new, :create, :show]

    resource :household, only: [:show, :edit, :update, :create] do
      post :join, on: :collection
    end
  end
end
