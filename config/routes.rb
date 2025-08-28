Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Locale switching
  post "switch_locale", to: "application#switch_locale"

  # Settings routes with Turbo Frame support  
  get 'settings', to: 'settings#show'



  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  root "home#index"



  resource :store, only: [:show, :edit, :update], controller: "store" do
    collection do
      post :test_connection
    end
  end

  resource :onboardings, only: [ :new, :create ]

  resources :products, only: [ :index, :edit, :update ] do
    collection do
      delete :bulk_delete
    end
    resources :variations, only: [ :edit, :update ]
  end

  resources :bulk_price_updates, only: [ :new, :create ] do
    collection do
      get :validate
      post :import
      get :results
    end
  end

  resources :merge_simple_products, only: [ :new, :create ]
  resources :categories, only: [ :index, :edit, :update ]
end
