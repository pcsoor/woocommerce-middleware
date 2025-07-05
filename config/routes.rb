Rails.application.routes.draw do
  get "store/show"
  get "store/edit"
  get "store/update"
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  root "home#index"

  get "/user/:id", to: "users#profile", as: "user"

  resource :store, only: [:show, :edit, :update] do
    collection do
      post :test_connection
    end
  end

  resource :onboardings, only: [ :new, :create ]

  resources :products, only: [ :index, :edit, :update ] do
    resources :variations, only: [ :edit, :update ]
    resources :bulk_price_update, only: [ :new, :create ]
  end

  resources :merge_simple_products, only: [ :new, :create ]
  resources :categories, only: [ :index, :edit, :update ]
end
