Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  authenticated :user do
    root 'plans#dashboard', as: :authenticated_root
  end
  
  root 'home#index'

  resources :recipes do
    resources :reviews, only: [:create, :edit, :update, :destroy]
  end

  # Routes nécessitant une authentification
  authenticate :user do
    resources :plans do
      member do
        get :generate
      end
    end
  end
end
