Rails.application.routes.draw do
  get "store/show"
  get "store/edit"
  get "store/update"
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  root "home#index"

  resources :users, only: [:show, :edit, :update] do
    member do
      get :profile
    end
  end

  resource :store, only: [:show, :edit, :update], controller: "store" do
    collection do
      post :test_connection
    end
  end

  resource :onboardings, only: [ :new, :create ]

  resources :products, only: [ :index, :edit, :update ] do
    resources :variations, only: [ :edit, :update ]
  end

  resources :merge_simple_products, only: [ :new, :create ]
  resources :categories, only: [ :index, :edit, :update ]

  resources :product_imports, only: [ :new, :create ] do
    collection do
      get :validate
      get :configure
      get :preview
      post :import
      get :results
    end
  end
end
