Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users

  root "products#index"

  resource :onboardings, only: [ :new, :create ]
  resources :products, only: [ :index, :edit, :update ] do
    resources :variations, only: [ :edit, :update ]
  end
  resources :merge_simple_products, only: [ :new, :create ]
  resources :categories, only: [ :index, :edit, :update ]
end
